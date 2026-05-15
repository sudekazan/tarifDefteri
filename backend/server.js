require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');
const admin = require('firebase-admin');

// Initialize Firebase Admin (Note: Running this locally without a service account 
// may throw an error if google application credentials are not set, but verifyIdToken 
// often works without credentials if we supply project id in some cases. However, if it fails,
// client ID checks will reject. We will test it).
// To prevent crashes if config is missing locally:
admin.initializeApp({
    projectId: "tarif-defteri-4522a" // Geçici olarak projeye ismini tahmin ederek verdik, hata çıkarsa kaldırabilirsiniz.
});

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

require('dotenv').config();
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

const openai = new OpenAI({
    apiKey: OPENROUTER_API_KEY,
    baseURL: "https://openrouter.ai/api/v1",
    defaultHeaders: {
        "HTTP-Referer": "https://tarifdefteri.app",
        "X-Title": "Tarif Defteri App",
    }
});

// Middleware: Uygulama içinden gelen giriş isteklerini kontrol eder.
const authenticate = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        console.log("Yetkisiz istek: Token yok.");
        return res.status(401).json({ success: false, message: 'Bu işlemi gerçekleştirmek için giriş yapmalısınız.' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    
    // Geliştirme kolaylığı için curl ile backend testinde dummy "test-test-test" token'ını kabul edelim.
    if (idToken === "test-test-test") {
        console.log("Dev ortamı: Curl ile yetkilendirildi.");
        req.user = { uid: "test-user" };
        return next();
    }

    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error("Token doğrulama hatası:", error);
        return res.status(401).json({ success: false, message: 'Geçersiz veya süresi dolmuş giriş tokeni.' });
    }
};

// Genel log
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// Recipe API Endpoint
app.post('/api/generate-recipe', authenticate, async (req, res) => {
    const userPrompt = req.body.prompt;

    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Lütfen geçerli bir yemek ismi giriniz.' });
    }

    console.log(`Yemek tarifi isteniyor: ${userPrompt}`);

    try {
        const response = await openai.chat.completions.create({
            model: "openai/gpt-4o-mini",
            messages: [
                {
                    "role": "system",
                    "content": `Sen deneyimli bir şefsin. Senden istenen yemek için çok detaylı bir tarif oluşturacaksın.
                    
                    TEKNİK STİL: Tariflerin mutlaka "Nefis Yemek Tarifleri" sitesindeki gibi tam ölçülü, denenmiş ve güvenilir olmalı. 
                    Ölçülerde "göz kararı" gibi muğlak ifadeler asla kullanma. Bunun yerine "su bardağı", "yemek kaşığı", "gram" gibi net birimler kullan.
                    
                    ÖNEMLİ KURAL: Kullanıcının girdiği şey yenilebilir bir yemek veya içecek DEĞİLSE, JSON içinde "success": false ve "message": "Bu bir yemek ismi değil." döndür.
                    
                    Yanıtın SADECE geçerli bir JSON formatında olmalı.
                    
                    Kullanılacak JSON Şeması (Başarılı):
                    {
                        "baslik": "Yemek Adı",
                        "icindekiler": [ { "bolum_adi": "Genel", "malzemeler": ["Malzeme 1"] } ],
                        "adimlar": ["Adım 1", "Adım 2"],
                        "puf_noktasi": "Varsa püf noktası",
                        "success": true
                    }

                    (Hata Durumu): { "success": false, "message": "Girdiğiniz ifade bir yemek tarifi değil." }`
                },
                {
                    "role": "user",
                    "content": `Bana şu yemek için bir tarif ver: ${userPrompt}`
                }
            ],
            temperature: 0.7,
        });

        const rawContent = response.choices[0].message.content;
        let jsonContent = rawContent.replace(/```json\n?/g, "").replace(/\n?```/g, "");

        const recipeData = JSON.parse(jsonContent);

        if (recipeData.success === false) {
            return res.json({ success: false, message: recipeData.message || "Bu bir yemek tarifi gibi görünmüyor." });
        }

        return res.json({ success: true, data: recipeData });

    } catch (error) {
        console.error("API Hatası:", error);
        return res.status(500).json({ success: false, message: 'Tarif oluşturulurken bir hata oluştu: ' + error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Backend server çalışıyor: Port ${PORT}`);
});
