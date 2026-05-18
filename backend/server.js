require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');
const admin = require('firebase-admin');

admin.initializeApp({
    projectId: "tarifdefteriuygulamasi"
});

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

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

    // Allow test token for development
    if (idToken === "test-test-test") {
        req.user = { uid: "test-user" };
        return next();
    }

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

// Recipe API Endpoint
app.post('/api/generate-recipe', authenticate, async (req, res) => {
    const userPrompt = req.body.prompt;
    const languageCode = req.body.language || 'en';

    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Please enter a valid food name.' });
    }

    console.log(`Recipe requested: "${userPrompt}" | Language: ${languageCode}`);

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
        });

        const rawContent = response.choices[0].message.content;
        let jsonContent = rawContent.replace(/```json\n?/g, "").replace(/\n?```/g, "");

        const recipeData = JSON.parse(jsonContent);

        if (recipeData.success === false) {
            return res.json({ success: false, message: recipeData.message || "This does not appear to be a valid food name." });
        }

        return res.json({ success: true, data: recipeData });

    } catch (error) {
        console.error("API Error:", error);
        return res.status(500).json({ success: false, message: 'Failed to generate recipe: ' + error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
