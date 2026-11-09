require('dotenv').config({ quiet: true });
const express = require('express');
const cors = require('cors');
const path = require('path');
const OpenAI = require('openai');
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

// Kimlik doğrulamadan önce: geçersiz token ile yapılan yığın isteklere karşı
// gevşek bir IP sınırı. Mobil operatörlerde çok sayıda kullanıcı aynı IP'yi
// paylaştığı (CGNAT) için asıl kullanıcı başı sınır aşağıda UID ile yapılır.
const ipLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 200,
    message: { success: false, rateLimited: true, message: 'Rate limit exceeded. Please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

// Kimlik doğrulamadan sonra: kullanıcı başına saatte en fazla 15 istek.
// Eskiden bu sınır IP'ye göreydi; aynı operatör IP'sini paylaşan alakasız
// kullanıcılar birbirinin hakkını tüketiyordu.
const userLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 15,
    keyGenerator: (req) => req.user.uid,
    message: { success: false, rateLimited: true, message: 'Rate limit exceeded. Please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

// Render gibi GCP dışı ortamlarda Application Default Credentials bulunamaz;
// Firestore'a erişim için FIREBASE_SERVICE_ACCOUNT_JSON ortam değişkeni
// (Firebase Console > Proje Ayarları > Servis Hesapları > Yeni özel anahtar
// üret, JSON içeriğini tek satır olarak buraya koy) tanımlanmalı.
let firebaseCredential;
if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
        firebaseCredential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON));
    } catch (error) {
        console.error('HATA: FIREBASE_SERVICE_ACCOUNT_JSON tanımlı ama geçerli JSON değil (tek satır mı, eksik kopyalanmış mı?):', error.message);
    }
} else {
    console.error('HATA: FIREBASE_SERVICE_ACCOUNT_JSON tanımlı değil; Render gibi GCP dışı ortamlarda Firestore erişimi başarısız olur ve AI istekleri 503 döner.');
}

// Bu anahtarlar eksikse sunucu "sağlıklı" görünür ama özellikler sessizce
// bozulur; açılışta açıkça logla ki Render loglarında hemen fark edilsin.
for (const key of ['OPENROUTER_API_KEY', 'REVENUECAT_SECRET_KEY']) {
    if (!process.env[key]) {
        console.error(`HATA: ${key} tanımlı değil.`);
    }
}

admin.initializeApp({
    credential: firebaseCredential || admin.credential.applicationDefault(),
    projectId: "tarifdefteriuygulamasi"
});

const app = express();
app.set('trust proxy', 1);
app.use(cors({ origin: true }));
app.use(express.json());

// Serve static website files
app.use(express.static(path.join(__dirname, 'public')));

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const REVENUECAT_SECRET_KEY = process.env.REVENUECAT_SECRET_KEY;

// Ücretsiz kullanıcılar için günlük AI Şef hakkı (Flutter tarafındaki
// RevenueCatService.canUseAi() ile aynı değer olmalı).
const FREE_DAILY_AI_LIMIT = 3;

// Pro kullanıcılar da artık tamamen sınırsız değil; normal kullanımı
// rahatça karşılayan ama otomatik/kötüye kullanımı önleyen bir tavan.
const PRO_DAILY_AI_LIMIT = 20;

// Ücretsiz kullanıcının ödüllü reklam izleyerek günde kazanabileceği
// azami ekstra hak sayısı (reklam "vergi" değil, isteğe bağlı ödül olsun diye).
const MAX_BONUS_USES_PER_DAY = 3;

// Flutter tarafındaki RevenueCatService._entitlementID ile aynı kimlikler.
const PRO_ENTITLEMENT_IDS = ['recipe_keeper_custom_cookbook_pro', 'pro', 'premium'];

/**
 * RevenueCat'e göre bu Firebase kullanıcısının Pro aboneliği var mı?
 * Flutter tarafında Purchases.logIn(firebaseUid) çağrıldığı için
 * RevenueCat'teki app_user_id, Firebase UID ile aynıdır.
 */
async function isProUserViaRevenueCat(firebaseUid) {
    if (!REVENUECAT_SECRET_KEY) {
        console.error('HATA: REVENUECAT_SECRET_KEY tanımlı değil; Pro aboneler ücretsiz limite düşüyor.');
        return false;
    }

    try {
        const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(firebaseUid)}`, {
            headers: { 'Authorization': `Bearer ${REVENUECAT_SECRET_KEY}` },
            signal: AbortSignal.timeout(5000),
        });

        if (!response.ok) {
            console.warn(`RevenueCat API ${response.status} döndürdü (uid: ${firebaseUid}); kullanıcı ücretsiz sayılıyor.`);
            return false;
        }

        const data = await response.json();
        const entitlements = data?.subscriber?.entitlements || {};
        const now = Date.now();

        return PRO_ENTITLEMENT_IDS.some((id) => {
            const ent = entitlements[id];
            if (!ent) return false;
            if (!ent.expires_date) return true; // süresiz/ömür boyu yetki
            return new Date(ent.expires_date).getTime() > now;
        });
    } catch (error) {
        console.error('RevenueCat Pro kontrolü hatası:', error.message);
        return false; // Belirsizlik durumunda ücretsiz limiti uygula (maliyet güvenliği)
    }
}

/**
 * Kullanıcının günlük AI Şef hakkını Firestore'da (transaction ile) kontrol eder ve artırır.
 * [baseLimit]: free kullanıcı için FREE_DAILY_AI_LIMIT, pro kullanıcı için PRO_DAILY_AI_LIMIT.
 * [allowBonus]: sadece free kullanıcılar reklamla kazanılmış bonusUses hakkı kullanabilir.
 */
async function checkAndIncrementDailyUsage(firebaseUid, baseLimit, allowBonus) {
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
    const docRef = admin.firestore().collection('aiUsage').doc(`${firebaseUid}_${today}`);

    try {
        return await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(docRef);
            const currentCount = snap.exists ? (snap.data().count || 0) : 0;
            const bonusUses = allowBonus && snap.exists ? (snap.data().bonusUses || 0) : 0;
            const effectiveLimit = baseLimit + bonusUses;

            if (currentCount >= effectiveLimit) {
                return { allowed: false, remaining: 0 };
            }

            tx.set(docRef, {
                count: currentCount + 1,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            return { allowed: true, remaining: effectiveLimit - (currentCount + 1), today };
        });
    } catch (error) {
        console.error('Günlük kullanım kontrolü hatası (Firestore):', error.message);
        // ÖNEMLİ: Altyapı sorununda sınırsız izin vermek maliyet riski oluşturur
        // (önceki haliyle bu catch bloğu "allowed: true, remaining: null" döndürüp
        // hem free hem pro kullanıcıyı fiilen sınırsız yapıyordu). Güvenli taraf:
        // isteği reddet, UI "limit doldu" değil "geçici sorun" mesajı göstersin.
        return { allowed: false, remaining: null, infraError: true };
    }
}

/**
 * Tarif üretimi teknik bir hata yüzünden (OpenRouter zaman aşımı, bozuk JSON)
 * başarısız olduğunda, checkAndIncrementDailyUsage'ın düştüğü hakkı geri verir.
 * Kullanıcı tarif alamadığı bir istek için hak kaybetmemeli.
 * [today]: hakkın düşüldüğü gün (istek gece yarısını aşarsa yanlış güne iade olmasın).
 */
async function refundDailyUsage(firebaseUid, today) {
    const docRef = admin.firestore().collection('aiUsage').doc(`${firebaseUid}_${today}`);
    try {
        await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(docRef);
            const currentCount = snap.exists ? (snap.data().count || 0) : 0;
            if (currentCount > 0) {
                tx.set(docRef, {
                    count: currentCount - 1,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            }
        });
        return true;
    } catch (error) {
        console.error('AI hakkı iade edilemedi (Firestore):', error.message);
        return false;
    }
}

/**
 * Kullanıcı ödüllü reklam izlediğinde o güne +1 ekstra AI Şef hakkı tanır.
 * Günde en fazla MAX_BONUS_USES_PER_DAY kez kullanılabilir.
 */
async function grantBonusUse(firebaseUid) {
    const today = new Date().toISOString().slice(0, 10);
    const docRef = admin.firestore().collection('aiUsage').doc(`${firebaseUid}_${today}`);

    try {
        return await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(docRef);
            const currentCount = snap.exists ? (snap.data().count || 0) : 0;
            const bonusUses = snap.exists ? (snap.data().bonusUses || 0) : 0;

            if (bonusUses >= MAX_BONUS_USES_PER_DAY) {
                return { granted: false, remaining: 0 };
            }

            const newBonusUses = bonusUses + 1;
            tx.set(docRef, {
                bonusUses: newBonusUses,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            const effectiveLimit = FREE_DAILY_AI_LIMIT + newBonusUses;
            return { granted: true, remaining: Math.max(0, effectiveLimit - currentCount) };
        });
    } catch (error) {
        console.error('Bonus hak tanımlama hatası (Firestore):', error.message);
        return { granted: false, remaining: 0 };
    }
}

const openai = new OpenAI({
    apiKey: OPENROUTER_API_KEY,
    baseURL: "https://openrouter.ai/api/v1",
    defaultHeaders: {
        "HTTP-Referer": "https://tarifdefteri.app",
        "X-Title": "Recipe Keeper App",
    }
});

// Middleware: Authenticate requests
const authenticate = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'Authentication required.' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // (Test token backdoor removed for security)

    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error("Token verification error:", error);
        return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
    }
};

// Request logging
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// API status endpoint
app.get('/api/status', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Tarif Defteri API is running!',
        endpoints: {
            generateRecipe: 'POST /api/generate-recipe'
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Ödüllü reklam izlendikten sonra o güne +1 ekstra AI Şef hakkı tanır.
app.post('/api/grant-bonus-ai-use', ipLimiter, authenticate, userLimiter, async (req, res) => {
    const firebaseUid = req.user.uid;
    const isPro = await isProUserViaRevenueCat(firebaseUid);

    if (isPro) {
        // Pro kullanıcı zaten sınırsız; bonus kavramı onun için anlamsız.
        return res.json({ success: true, remaining: null });
    }

    const result = await grantBonusUse(firebaseUid);
    if (!result.granted) {
        return res.status(429).json({
            success: false,
            message: 'Daily bonus ad limit reached.',
        });
    }

    return res.json({ success: true, remaining: result.remaining });
});

// Recipe API Endpoint
app.post('/api/generate-recipe', ipLimiter, authenticate, userLimiter, async (req, res) => {
    const userPrompt = req.body.prompt;
    const languageCode = req.body.language || 'en';
    // 'dish_name': kullanıcı tek bir yemek adı/link girdi (AI Şef).
    // 'ingredients': kullanıcı elindeki malzemeleri girdi (Bugün Ne Pişirsem).
    const mode = req.body.mode === 'ingredients' ? 'ingredients' : 'dish_name';

    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Please enter a valid food name.' });
    }

    // Hem free hem pro kullanıcı artık günlük bir tavana tabi (free: düşük +
    // reklamla bonus, pro: cömert ama sınırsız değil — maliyet güvenliği).
    const firebaseUid = req.user.uid;
    const isPro = await isProUserViaRevenueCat(firebaseUid);
    const baseLimit = isPro ? PRO_DAILY_AI_LIMIT : FREE_DAILY_AI_LIMIT;

    const usage = await checkAndIncrementDailyUsage(firebaseUid, baseLimit, !isPro);
    if (!usage.allowed) {
        if (usage.infraError) {
            // Firestore'a ulaşılamadı: limiti sessizce atlamak yerine kullanıcıya
            // "geçici sorun" diyoruz; bunu "hakkın bitti" ile karıştırmamalı.
            return res.status(503).json({
                success: false,
                message: 'Usage check temporarily unavailable. Please try again in a few minutes.',
                remaining: null,
            });
        }
        return res.status(429).json({
            success: false,
            message: isPro
                ? 'Daily Pro AI Chef limit reached. Please try again tomorrow.'
                : 'Daily free AI Chef limit reached. Upgrade to Pro for a higher limit.',
            remaining: 0,
            isPro,
        });
    }
    const remaining = usage.remaining;

    console.log(`Recipe requested: "${userPrompt}" | Mode: ${mode} | Language: ${languageCode} | Pro: ${isPro}`);

    const measurementRule = languageCode === 'en'
        ? 'Use US Imperial measurements (cups, oz, tbsp, tsp, °F) for all quantities and temperatures.'
        : 'Use metric measurements (grams, ml, °C) for all quantities and temperatures.';

    const titleRule = mode === 'ingredients'
        ? `=== TITLE (CRITICAL) ===
The user input is a list of ingredients and preferences, NOT a dish name. Invent a natural,
appetizing dish name in '${languageCode}' for something that can realistically be cooked from
them — NEVER just list or concatenate the ingredient names as the title.`
        : `=== FOOD NAME INTERPRETATION ===
Always interpret the dish name in the culinary/cultural context of language code '${languageCode}'.
Examples:
- language='en', input='pasta' → Italian-style pasta dish (spaghetti, penne, etc.) NOT a Turkish cream cake.
- language='tr', input='pasta' → Turkish cream cake.
- language='en', input='mantı' → Turkish-style dumplings (explain what it is in English).
Apply the meaning that is most natural and common in the cuisine of the given language.`;

    const validationRule = mode === 'ingredients'
        ? `=== VALIDATION ===
The ingredients may be an imperfect or unusual combination — that's expected and fine: do your
best to invent a plausible, edible recipe from (most of) them, improvising a reasonable addition
only when truly necessary. Only return an error if the input contains NO real food ingredients at
all (e.g. random objects, gibberish). When you do return an error, give a SPECIFIC, helpful reason
(e.g. which ingredients you couldn't work with, or that the requested meal type doesn't fit them) —
never a vague "something went wrong" message:
{ "success": false, "message": "<specific, helpful reason translated to '${languageCode}'>" }`
        : `=== VALIDATION ===
If the input is clearly NOT a food or drink name in any language, return:
{ "success": false, "message": "<appropriate error message translated to '${languageCode}'>" }`;

    try {
        const response = await openai.chat.completions.create({
            model: "openai/gpt-4o-mini",
            messages: [
                {
                    "role": "system",
                    "content": `You are an expert chef assistant. Your job is to generate a detailed, reliable recipe ${mode === 'ingredients' ? 'from the ingredients and preferences the user provides' : 'for the dish the user requests'}.

=== LANGUAGE (HIGHEST PRIORITY) ===
User's language code: '${languageCode}'
- Write ALL text values in the JSON response in this language ONLY.
- Never mix languages.
- ${measurementRule}

${titleRule}

${validationRule}

=== RESPONSE FORMAT (CRITICAL) ===
Return ONLY valid JSON. No markdown, no code fences, no extra text.
JSON keys must stay EXACTLY as shown below. Only translate the VALUES.

Success:
{
    "baslik": "Recipe title in '${languageCode}'",
    "icindekiler": [ { "bolum_adi": "Section name in '${languageCode}'", "malzemeler": ["Ingredient with precise quantity"] } ],
    "adimlar": ["Detailed step 1", "Detailed step 2"],
    "puf_noktasi": "Chef tip in '${languageCode}', or empty string if none",
    "success": true
}

Error:
{ "success": false, "message": "Reason in '${languageCode}'" }`
                },
                {
                    "role": "user",
                    "content": mode === 'ingredients'
                        ? `Generate a recipe using these ingredients/preferences: ${userPrompt}`
                        : `Generate a recipe for: ${userPrompt}`
                }
            ],
            temperature: 0.7,
        }, {
            timeout: 30000, // OpenRouter yanıt vermezse isteği 30sn sonra düşür
        });

        const rawContent = response.choices[0].message.content;
        let jsonContent = rawContent.replace(/```json\n?/g, "").replace(/\n?```/g, "");

        const recipeData = JSON.parse(jsonContent);

        if (recipeData.success === false) {
            // Mesajı yapay zekâ kullanıcının dilinde yazar; yoksa istemci kendi
            // çevrilmiş metnini gösterir (İngilizce yedek metin göndermiyoruz).
            return res.json({ success: false, message: recipeData.message || null, remaining });
        }

        return res.json({ success: true, data: recipeData, remaining });

    } catch (error) {
        console.error("API Error:", error);
        // Tarif üretilemedi: düşülen hakkı iade et ve güncel kalan hakkı dön ki
        // istemcideki sayaç doğru kalsın.
        const refunded = await refundDailyUsage(firebaseUid, usage.today);
        return res.status(500).json({
            success: false,
            message: 'Failed to generate recipe: ' + error.message,
            remaining: refunded ? remaining + 1 : remaining,
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
