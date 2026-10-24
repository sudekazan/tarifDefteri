require('dotenv').config({ quiet: true });
const express = require('express');
const cors = require('cors');
const path = require('path');
const OpenAI = require('openai');
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

// Her kullanıcı/IP için 1 saatte maksimum 15 tarif isteği
const recipeLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 15,
    message: { success: false, message: 'Rate limit exceeded. Please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

admin.initializeApp({
    projectId: "tarifdefteriuygulamasi"
});

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Serve static website files
app.use(express.static(path.join(__dirname, 'public')));

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const REVENUECAT_SECRET_KEY = process.env.REVENUECAT_SECRET_KEY;

// Ücretsiz kullanıcılar için günlük AI Şef hakkı (Flutter tarafındaki
// RevenueCatService.canUseAi() ile aynı değer olmalı).
const FREE_DAILY_AI_LIMIT = 3;

// Flutter tarafındaki RevenueCatService._entitlementID ile aynı kimlikler.
const PRO_ENTITLEMENT_IDS = ['recipe_keeper_custom_cookbook_pro', 'pro', 'premium'];

/**
 * RevenueCat'e göre bu Firebase kullanıcısının Pro aboneliği var mı?
 * Flutter tarafında Purchases.logIn(firebaseUid) çağrıldığı için
 * RevenueCat'teki app_user_id, Firebase UID ile aynıdır.
 */
async function isProUserViaRevenueCat(firebaseUid) {
    if (!REVENUECAT_SECRET_KEY) {
        console.warn('REVENUECAT_SECRET_KEY tanımlı değil; Pro kontrolü atlanıp kullanıcı ücretsiz sayılıyor.');
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
 * Ücretsiz kullanıcının günlük AI Şef hakkını Firestore'da (transaction ile) kontrol eder ve artırır.
 */
async function checkAndIncrementDailyUsage(firebaseUid) {
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
    const docRef = admin.firestore().collection('aiUsage').doc(`${firebaseUid}_${today}`);

    return admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(docRef);
        const currentCount = snap.exists ? (snap.data().count || 0) : 0;

        if (currentCount >= FREE_DAILY_AI_LIMIT) {
            return { allowed: false, remaining: 0 };
        }

        tx.set(docRef, {
            count: currentCount + 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        return { allowed: true, remaining: FREE_DAILY_AI_LIMIT - (currentCount + 1) };
    });
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

// Recipe API Endpoint
app.post('/api/generate-recipe', recipeLimiter, authenticate, async (req, res) => {
    const userPrompt = req.body.prompt;
    const languageCode = req.body.language || 'en';

    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Please enter a valid food name.' });
    }

    // Ücretsiz kullanıcı günlük limiti: Pro abonelerin RevenueCat kaydı
    // Firebase UID'ye bağlıysa (Purchases.logIn) burada tespit edilip
    // limit tamamen atlanır; değilse Firestore'daki günlük sayaç kontrol edilir.
    const firebaseUid = req.user.uid;
    const isPro = await isProUserViaRevenueCat(firebaseUid);

    // null => Pro/sınırsız. Değilse Flutter tarafı yerel "kalan hak" sayacını
    // bu değerle senkronize eder (bkz. RevenueCatService.syncRemainingFromServer).
    let remaining = null;
    if (!isPro) {
        const usage = await checkAndIncrementDailyUsage(firebaseUid);
        if (!usage.allowed) {
            return res.status(429).json({
                success: false,
                message: 'Daily free AI Chef limit reached. Upgrade to Pro for unlimited recipes.',
                remaining: 0,
            });
        }
        remaining = usage.remaining;
    }

    console.log(`Recipe requested: "${userPrompt}" | Language: ${languageCode} | Pro: ${isPro}`);

    const measurementRule = languageCode === 'en'
        ? 'Use US Imperial measurements (cups, oz, tbsp, tsp, °F) for all quantities and temperatures.'
        : 'Use metric measurements (grams, ml, °C) for all quantities and temperatures.';

    try {
        const response = await openai.chat.completions.create({
            model: "openai/gpt-4o-mini",
            messages: [
                {
                    "role": "system",
                    "content": `You are an expert chef assistant. Your job is to generate a detailed, reliable recipe for the dish the user requests.

=== LANGUAGE (HIGHEST PRIORITY) ===
User's language code: '${languageCode}'
- Write ALL text values in the JSON response in this language ONLY.
- Never mix languages.
- ${measurementRule}

=== FOOD NAME INTERPRETATION ===
Always interpret the dish name in the culinary/cultural context of language code '${languageCode}'.
Examples:
- language='en', input='pasta' → Italian-style pasta dish (spaghetti, penne, etc.) NOT a Turkish cream cake.
- language='tr', input='pasta' → Turkish cream cake.
- language='en', input='mantı' → Turkish-style dumplings (explain what it is in English).
Apply the meaning that is most natural and common in the cuisine of the given language.

=== VALIDATION ===
If the input is clearly NOT a food or drink name in any language, return:
{ "success": false, "message": "<appropriate error message translated to '${languageCode}'>" }

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
                    "content": `Generate a recipe for: ${userPrompt}`
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
            return res.json({ success: false, message: recipeData.message || "This does not appear to be a valid food name.", remaining });
        }

        return res.json({ success: true, data: recipeData, remaining });

    } catch (error) {
        console.error("API Error:", error);
        return res.status(500).json({ success: false, message: 'Failed to generate recipe: ' + error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
