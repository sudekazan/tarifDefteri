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

// Ücretsiz kullanıcılar için haftalık AI hakkı; iki özellik ayrı sayılır
// (yemek adıyla 5, malzemeden 5). Flutter tarafındaki
// RevenueCatService.freeWeeklyAiLimit ile aynı değer olmalı.
const FREE_WEEKLY_AI_LIMIT = 5;

// Premium kullanıcılar da tamamen sınırsız değil; normal kullanımı
// rahatça karşılayan ama otomatik/kötüye kullanımı önleyen günlük tavan.
const PRO_DAILY_AI_LIMIT = 20;

// Ücretsiz kullanıcının ödüllü reklam izleyerek haftada kazanabileceği
// azami ekstra hak sayısı (iki özellik toplamı).
const MAX_BONUS_USES_PER_WEEK = 3;
// İstek metninin (yemek adı, link ya da malzeme listesi) en fazla uzunluğu.
const MAX_PROMPT_LENGTH = 1000;
// Premium öneri kartlarından seçilen tarifin tamamı bu süre içinde üretilebilir.
const SUGGESTION_TTL_MS = 24 * 60 * 60 * 1000;

const normalizeMode = (mode) => (mode === 'ingredients' ? 'ingredients' : 'dish_name');

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
 * Haftanın başlangıcı: pazartesi 00:00 UTC, YYYY-MM-DD biçiminde.
 * Flutter tarafındaki RevenueCatService.haftaBaslangici ile aynı hesap.
 */
function weekStartUtc(date = new Date()) {
    const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
    const daysSinceMonday = (d.getUTCDay() + 6) % 7;
    d.setUTCDate(d.getUTCDate() - daysSinceMonday);
    return d.toISOString().slice(0, 10);
}

/**
 * Bir isteğin hangi sayaçtan düşeceğini belirler. Hak düşülürken ve iade
 * edilirken aynı belge kullanılsın diye istek başında bir kez hesaplanır
 * (istek gün ya da hafta sınırını aşarsa yanlış yere iade olmasın).
 * Ücretsiz: haftalık belge, özelliğe göre ayrı sayaç + o özelliğin reklam bonusu.
 * Premium: günlük belge, iki özellik ortak sayaç.
 */
function usageSlot(firebaseUid, isPro, mode) {
    const db = admin.firestore();
    if (isPro) {
        const today = new Date().toISOString().slice(0, 10);
        return {
            docRef: db.collection('aiUsage').doc(`${firebaseUid}_${today}`),
            countField: 'count',
            bonusField: null,
            baseLimit: PRO_DAILY_AI_LIMIT,
        };
    }
    return {
        docRef: db.collection('aiUsageWeekly').doc(`${firebaseUid}_${weekStartUtc()}`),
        countField: `count_${mode}`,
        bonusField: `bonus_${mode}`,
        baseLimit: FREE_WEEKLY_AI_LIMIT,
    };
}

/**
 * Kullanıcının AI hakkını Firestore'da (transaction ile) kontrol eder ve artırır.
 */
async function checkAndIncrementUsage(slot) {
    try {
        return await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(slot.docRef);
            const data = snap.exists ? snap.data() : {};
            const currentCount = data[slot.countField] || 0;
            const bonusUses = slot.bonusField ? (data[slot.bonusField] || 0) : 0;
            const effectiveLimit = slot.baseLimit + bonusUses;

            if (currentCount >= effectiveLimit) {
                return { allowed: false, remaining: 0 };
            }

            tx.set(slot.docRef, {
                [slot.countField]: currentCount + 1,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            return { allowed: true, remaining: effectiveLimit - (currentCount + 1) };
        });
    } catch (error) {
        console.error('Kullanım kontrolü hatası (Firestore):', error.message);
        // Altyapı sorununda sınırsız izin vermek maliyet riski oluşturur;
        // isteği reddet, UI "limit doldu" değil "geçici sorun" mesajı göstersin.
        return { allowed: false, remaining: null, infraError: true };
    }
}

/**
 * Tarif üretimi teknik bir hata yüzünden (OpenRouter zaman aşımı, bozuk JSON)
 * başarısız olduğunda düşülen hakkı geri verir. Kullanıcı tarif alamadığı
 * bir istek için hak kaybetmemeli.
 */
async function refundUsage(slot) {
    try {
        await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(slot.docRef);
            const currentCount = snap.exists ? (snap.data()[slot.countField] || 0) : 0;
            if (currentCount > 0) {
                tx.set(slot.docRef, {
                    [slot.countField]: currentCount - 1,
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

/** Bu hafta kalan hakkı daha az olan tür (eşitse yemek adı). */
async function modeWithFewerRemaining(firebaseUid) {
    try {
        const snap = await usageSlot(firebaseUid, false, 'dish_name').docRef.get();
        const data = snap.exists ? snap.data() : {};
        const kalan = (mode) => FREE_WEEKLY_AI_LIMIT + (data[`bonus_${mode}`] || 0) - (data[`count_${mode}`] || 0);
        return kalan('ingredients') < kalan('dish_name') ? 'ingredients' : 'dish_name';
    } catch (error) {
        console.error('Kalan hak okunamadı (Firestore):', error.message);
        return 'dish_name';
    }
}

/**
 * Kullanıcı ödüllü reklam izlediğinde o haftaya, hakkı biten özellik için
 * +1 ekstra hak tanır. Haftada toplam en fazla MAX_BONUS_USES_PER_WEEK kez.
 */
async function grantBonusUse(firebaseUid, mode) {
    const slot = usageSlot(firebaseUid, false, mode);

    try {
        return await admin.firestore().runTransaction(async (tx) => {
            const snap = await tx.get(slot.docRef);
            const data = snap.exists ? snap.data() : {};
            const currentCount = data[slot.countField] || 0;
            const bonusUses = data[slot.bonusField] || 0;
            const bonusTotal = data.bonusTotal || 0;

            if (bonusTotal >= MAX_BONUS_USES_PER_WEEK) {
                return { granted: false, remaining: 0 };
            }

            const newBonusUses = bonusUses + 1;
            tx.set(slot.docRef, {
                [slot.bonusField]: newBonusUses,
                bonusTotal: bonusTotal + 1,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            const effectiveLimit = FREE_WEEKLY_AI_LIMIT + newBonusUses;
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
            generateRecipe: 'POST /api/generate-recipe',
            suggestRecipes: 'POST /api/suggest-recipes'
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Ödüllü reklam izlendikten sonra o haftaya, hakkı biten özellik için +1 hak tanır.
app.post('/api/grant-bonus-ai-use', ipLimiter, authenticate, userLimiter, async (req, res) => {
    const firebaseUid = req.user.uid;
    const isPro = await isProUserViaRevenueCat(firebaseUid);

    if (isPro) {
        // Premium kullanıcı için bonus kavramı yok.
        return res.json({ success: true, remaining: null });
    }

    // Eski uygulama sürümü tür göndermez; bonusu hakkı daha az kalan türe ver.
    const mode = req.body?.mode
        ? normalizeMode(req.body.mode)
        : await modeWithFewerRemaining(firebaseUid);

    const result = await grantBonusUse(firebaseUid, mode);
    if (!result.granted) {
        return res.status(429).json({
            success: false,
            message: 'Weekly bonus ad limit reached.',
        });
    }

    return res.json({ success: true, remaining: result.remaining });
});

/** Yapay zekâ yanıtındaki JSON'u ayrıştırır (kod çitlerini temizleyerek). */
function parseAiJson(rawContent) {
    const jsonContent = rawContent.replace(/```json\n?/g, '').replace(/\n?```/g, '');
    return JSON.parse(jsonContent);
}

function measurementRuleFor(languageCode) {
    return languageCode === 'en'
        ? 'Use US Imperial measurements (cups, oz, tbsp, tsp, °F) for all quantities and temperatures.'
        : 'Use metric measurements (grams, ml, °C) for all quantities and temperatures.';
}

function ingredientsValidationRule(languageCode) {
    return `=== CHOOSING THE DISH (CRITICAL) ===
The user lists what they have at home. Treat it as a pantry, NOT a shopping list for one dish:
- You do NOT have to use all of the ingredients. Pick the subset that naturally goes together
  and leave the rest out. Using 2-3 of them is perfectly fine.
- The dish MUST be a real, well-known dish that people actually cook today — the kind found on
  popular home-cooking recipe sites in the cuisine of '${languageCode}' (e.g. for 'tr': menemen,
  ton balıklı makarna, mantar sote, kremalı makarna). Never invent an odd, random combination.
- You may assume common pantry basics are available (salt, pepper, oil, water, flour, sugar,
  onion, spices) even if not listed.
- If a meal preference is given (e.g. breakfast), choose a real dish that fits that meal.

=== VALIDATION ===
Return an error ONLY if no real, commonly cooked dish can be made from any reasonable subset of
the ingredients plus pantry basics (or the input contains no real food at all). If any sensible
real dish is possible, ALWAYS return it. When you do return an error, give a SPECIFIC reason
(e.g. which ingredient is missing for a real dish) — never a vague "could not create" message:
{ "success": false, "message": "<specific, helpful reason translated to '${languageCode}'>" }`;
}

/**
 * Tam tarifi üretir. [chosen] verilirse (Premium öneri kartından seçilen
 * tarif) başlık ve kısa açıklama ona göre sabitlenir.
 */
async function generateFullRecipe({ userPrompt, mode, languageCode, chosen }) {
    const titleRule = chosen
        ? `=== TITLE (CRITICAL) ===
The user already picked this dish from earlier suggestions. The "baslik" value MUST be exactly:
"${chosen.baslik}"`
        : mode === 'ingredients'
        ? `=== TITLE (CRITICAL) ===
The user input is a list of ingredients and preferences, NOT a dish name. Use the real, commonly
known name of the dish in '${languageCode}' (the name people would search for on a recipe site).
NEVER build the title by listing or joining ingredient names (bad: "Domatesli Biberli Mantarlı
Pirinç"; good: "Menemen", "Mantar Sote").`
        : `=== FOOD NAME INTERPRETATION ===
Always interpret the dish name in the culinary/cultural context of language code '${languageCode}'.
Examples:
- language='en', input='pasta' → Italian-style pasta dish (spaghetti, penne, etc.) NOT a Turkish cream cake.
- language='tr', input='pasta' → Turkish cream cake.
- language='en', input='mantı' → Turkish-style dumplings (explain what it is in English).
Apply the meaning that is most natural and common in the cuisine of the given language.`;

    const validationRule = mode === 'ingredients'
        ? ingredientsValidationRule(languageCode)
        : `=== VALIDATION ===
If the input is clearly NOT a food or drink name in any language, return:
{ "success": false, "message": "<appropriate error message translated to '${languageCode}'>" }`;

    let userContent;
    if (chosen) {
        userContent = `Ingredients/preferences: ${userPrompt}
Write the full recipe for the dish the user picked: "${chosen.baslik}" — ${chosen.aciklama}`;
    } else if (mode === 'ingredients') {
        userContent = `Generate a recipe using these ingredients/preferences: ${userPrompt}`;
    } else {
        userContent = `Generate a recipe for: ${userPrompt}`;
    }

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
- ${measurementRuleFor(languageCode)}

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
            { "role": "user", "content": userContent }
        ],
        temperature: 0.7,
    }, {
        timeout: 30000, // OpenRouter yanıt vermezse isteği 30sn sonra düşür
    });

    return parseAiJson(response.choices[0].message.content);
}

/** Malzemelerden 3 farklı kısa tarif önerisi üretir (yalnızca Premium). */
async function generateSuggestions({ userPrompt, languageCode }) {
    const response = await openai.chat.completions.create({
        model: "openai/gpt-4o-mini",
        messages: [
            {
                "role": "system",
                "content": `You are an expert chef assistant. Suggest exactly 3 clearly DIFFERENT dishes that can realistically be cooked from the ingredients and preferences the user provides.

=== LANGUAGE (HIGHEST PRIORITY) ===
User's language code: '${languageCode}'
- Write ALL text values in this language ONLY. Never mix languages.

=== TITLES (CRITICAL) ===
Each title is the real, commonly known name of the dish (the name people would search for on a
recipe site) — NEVER built by listing or joining ingredient names. Each of the 3 dishes may use a
different subset of the ingredients.
Each description is ONE short sentence (max 110 characters) saying what makes the dish appealing.

${ingredientsValidationRule(languageCode)}

=== RESPONSE FORMAT (CRITICAL) ===
Return ONLY valid JSON. No markdown, no code fences, no extra text. Keys stay exactly as shown.

Success:
{
    "oneriler": [
        { "baslik": "Dish name", "aciklama": "One short sentence" },
        { "baslik": "Dish name", "aciklama": "One short sentence" },
        { "baslik": "Dish name", "aciklama": "One short sentence" }
    ],
    "success": true
}

Error:
{ "success": false, "message": "Reason in '${languageCode}'" }`
            },
            { "role": "user", "content": `Ingredients/preferences: ${userPrompt}` }
        ],
        temperature: 0.9,
    }, {
        timeout: 30000,
    });

    return parseAiJson(response.choices[0].message.content);
}

/** İstek metnini doğrular; hata varsa 400 yanıtını gönderip false döner. */
function validatePrompt(userPrompt, res) {
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        res.status(400).json({ success: false, message: 'Please enter a valid food name.' });
        return false;
    }
    // Uzunluk sınırı: çok uzun metinle maliyet şişirilmesin (hak düşülmeden önce).
    if (userPrompt.length > MAX_PROMPT_LENGTH) {
        res.status(400).json({ success: false, message: 'The request text is too long.' });
        return false;
    }
    return true;
}

/** Hak düşürmeyi dener; izin yoksa uygun yanıtı gönderip null döner. */
async function chargeUsageOrRespond(slot, isPro, res) {
    const usage = await checkAndIncrementUsage(slot);
    if (usage.allowed) return usage;

    if (usage.infraError) {
        // Firestore'a ulaşılamadı: bunu "hakkın bitti" ile karıştırmamalı.
        res.status(503).json({
            success: false,
            message: 'Usage check temporarily unavailable. Please try again in a few minutes.',
            remaining: null,
        });
        return null;
    }
    res.status(429).json({
        success: false,
        message: isPro
            ? 'Daily Premium AI limit reached. Please try again tomorrow.'
            : 'Weekly free AI limit reached. Upgrade to Premium for a higher limit.',
        remaining: 0,
        isPro,
    });
    return null;
}

// Premium: malzemelerden 3 kısa öneri kartı. Bir hak düşer; seçilen kartın
// tam tarifi /api/generate-recipe'ye suggestionId ile istenince hak düşmez.
app.post('/api/suggest-recipes', ipLimiter, authenticate, userLimiter, async (req, res) => {
    const userPrompt = req.body.prompt;
    const languageCode = req.body.language || 'en';
    if (!validatePrompt(userPrompt, res)) return;

    const firebaseUid = req.user.uid;
    const isPro = await isProUserViaRevenueCat(firebaseUid);
    if (!isPro) {
        return res.status(403).json({ success: false, message: 'Suggestions are a Premium feature.' });
    }

    const slot = usageSlot(firebaseUid, true, 'ingredients');
    const usage = await chargeUsageOrRespond(slot, true, res);
    if (!usage) return;

    console.log(`Suggestions requested | Language: ${languageCode}`);

    try {
        const result = await generateSuggestions({ userPrompt, languageCode });

        if (result.success === false) {
            console.log(`AI refused suggestions | Prompt: "${userPrompt}" | Reason: "${result.message}"`);
            return res.json({ success: false, message: result.message || null, remaining: usage.remaining });
        }

        const oneriler = Array.isArray(result.oneriler)
            ? result.oneriler
                .filter((o) => o && typeof o.baslik === 'string' && o.baslik.trim())
                .slice(0, 3)
                .map((o) => ({
                    baslik: o.baslik.trim(),
                    aciklama: typeof o.aciklama === 'string' ? o.aciklama.trim() : '',
                }))
            : [];
        if (oneriler.length === 0) {
            throw new Error('Öneri listesi boş döndü');
        }

        const ref = await admin.firestore().collection('aiSuggestions').add({
            uid: firebaseUid,
            prompt: userPrompt,
            language: languageCode,
            oneriler,
            used: false,
            createdAt: Date.now(),
        });

        return res.json({ success: true, suggestionId: ref.id, oneriler, remaining: usage.remaining });
    } catch (error) {
        console.error('Suggestion API Error:', error);
        const refunded = await refundUsage(slot);
        return res.status(500).json({
            success: false,
            message: 'Failed to generate suggestions. Please try again.',
            remaining: refunded ? usage.remaining + 1 : usage.remaining,
        });
    }
});

// Recipe API Endpoint
app.post('/api/generate-recipe', ipLimiter, authenticate, userLimiter, async (req, res) => {
    const firebaseUid = req.user.uid;
    const suggestionId = req.body.suggestionId;

    // Premium öneri kartından seçilen tarif: hak öneri isteğinde düşüldü.
    if (typeof suggestionId === 'string' && suggestionId) {
        const index = Number.isInteger(req.body.suggestionIndex) ? req.body.suggestionIndex : -1;
        const ref = admin.firestore().collection('aiSuggestions').doc(suggestionId);
        let suggestion;
        try {
            const snap = await ref.get();
            suggestion = snap.exists ? snap.data() : null;
        } catch (error) {
            console.error('Öneri okunamadı (Firestore):', error.message);
            return res.status(503).json({ success: false, message: 'Please try again in a few minutes.' });
        }

        const chosen = suggestion?.oneriler?.[index];
        if (!suggestion || suggestion.uid !== firebaseUid || suggestion.used || !chosen ||
            Date.now() - (suggestion.createdAt || 0) > SUGGESTION_TTL_MS) {
            return res.status(410).json({ success: false, suggestionExpired: true, message: 'Suggestion is no longer valid.' });
        }

        try {
            const recipeData = await generateFullRecipe({
                userPrompt: suggestion.prompt,
                mode: 'ingredients',
                languageCode: suggestion.language || 'en',
                chosen,
            });
            if (recipeData.success === false) {
                return res.json({ success: false, message: recipeData.message || null });
            }
            // Yalnızca başarıda kullanıldı sayılır; hata olursa kullanıcı tekrar dener.
            await ref.update({ used: true }).catch((e) => console.error('Öneri işaretlenemedi:', e.message));
            return res.json({ success: true, data: recipeData });
        } catch (error) {
            console.error('API Error (suggestion):', error);
            return res.status(500).json({ success: false, message: 'Failed to generate recipe. Please try again.' });
        }
    }

    const userPrompt = req.body.prompt;
    const languageCode = req.body.language || 'en';
    // 'dish_name': kullanıcı tek bir yemek adı/link girdi (AI Şef).
    // 'ingredients': kullanıcı elindeki malzemeleri girdi (Bugün Ne Pişirsem).
    const mode = normalizeMode(req.body.mode);
    if (!validatePrompt(userPrompt, res)) return;

    // Ücretsiz: özelliğe göre haftalık hak (+ reklam bonusu).
    // Premium: iki özellik ortak günlük tavan.
    const isPro = await isProUserViaRevenueCat(firebaseUid);
    const slot = usageSlot(firebaseUid, isPro, mode);
    const usage = await chargeUsageOrRespond(slot, isPro, res);
    if (!usage) return;
    const remaining = usage.remaining;

    console.log(`Recipe requested: "${userPrompt}" | Mode: ${mode} | Language: ${languageCode} | Pro: ${isPro}`);

    try {
        const recipeData = await generateFullRecipe({ userPrompt, mode, languageCode });

        if (recipeData.success === false) {
            console.log(`AI refused recipe | Mode: ${mode} | Reason: "${recipeData.message}"`);
            // Mesajı yapay zekâ kullanıcının dilinde yazar; yoksa istemci kendi
            // çevrilmiş metnini gösterir (İngilizce yedek metin göndermiyoruz).
            return res.json({ success: false, message: recipeData.message || null, remaining });
        }

        return res.json({ success: true, data: recipeData, remaining });

    } catch (error) {
        console.error("API Error:", error);
        // Tarif üretilemedi: düşülen hakkı iade et ve güncel kalan hakkı dön ki
        // istemcideki sayaç doğru kalsın.
        const refunded = await refundUsage(slot);
        return res.status(500).json({
            success: false,
            // İç hata metni istemciye gitmez; ayrıntı yalnızca sunucu günlüğünde.
            message: 'Failed to generate recipe. Please try again.',
            remaining: refunded ? remaining + 1 : remaining,
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
