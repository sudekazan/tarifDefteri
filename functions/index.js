const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

// 1. Secret Tanımlama (Güvenlik)
// Bu anahtarı CLI üzerinden şu komutla kaydedeceğiz:
// firebase functions:secrets:set OPENROUTER_API_KEY
const apiKey = defineSecret("OPENROUTER_API_KEY");

/**
 * Kullanıcıdan gelen yemek ismine göre tarif oluşturan Cloud Function.
 * 
 * @param {Object} request - Client'tan gelen istek verisi.
 * @param {string} request.data.prompt - Kullanıcının girdiği yemek ismi.
 */
exports.generateRecipe = onCall({ secrets: [apiKey] }, async (request) => {
    // 1. Kimlik Doğrulama Kontrolü (İsteğe Bağlı ama Önerilir)
    if (!request.auth) {
        throw new HttpsError(
            'unauthenticated',
            'Bu işlemi gerçekleştirmek için giriş yapmalısınız.'
        );
    }

    // 2. Girdi Doğrulama
    const userPrompt = request.data.prompt;
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
        throw new HttpsError(
            'invalid-argument',
            'Lütfen geçerli bir yemek ismi giriniz.'
        );
    }

    // 3. OpenAI (OpenRouter) İstemcisi Hazırlama
    // onCall fonksiyonu içinde apiKey.value() ile secret değerine güvenli erişim
    const openai = new OpenAI({
        apiKey: apiKey.value(),
        baseURL: "https://openrouter.ai/api/v1", // OpenRouter Endpoint
        defaultHeaders: {
            "HTTP-Referer": "https://tarifdefteri.app", // OpenRouter için gerekli
            "X-Title": "Tarif Defteri App",
        }
    });

    try {
        // 4. AI API Çağrısı
        const response = await openai.chat.completions.create({
            model: "openai/gpt-4o-mini", // Ücretli ama çok ucuz ve stabil model
            messages: [
                {
                    "role": "system",
                    "content": `Sen deneyimli bir şefsin. Senden istenen yemek için çok detaylı bir tarif oluşturacaksın.
                    
                    TEKNİK STİL: Tariflerin mutlaka "Nefis Yemek Tarifleri" sitesindeki gibi tam ölçülü, denenmiş ve güvenilir olmalı. 
                    Ölçülerde "göz kararı" gibi muğlak ifadeler asla kullanma. Bunun yerine "su bardağı", "yemek kaşığı", "gram" gibi net birimler kullan.
                    
                    ÖNEMLİ KURAL: Kullanıcının girdiği şey yenilebilir bir yemek veya içecek DEĞİLSE (örneğin "araba", "telefon", "kod yaz", "aşk şiiri" vb.), JSON içinde "success": false ve "message": "Bu bir yemek ismi değil." döndür.
                    
                    Tarif oluşturulacaksa:
                    ÖNEMLİ: Yemeğin hamuru, sosu, şerbeti, içi veya üzeri gibi farklı bölümleri varsa bunları mutlaka ayırarak vermelisin.
                    
                    Yanıtın SADECE geçerli bir JSON formatında olmalı. Başka hiçbir açıklama yazma.
                    
                    Kullanılacak JSON Şeması (Başarılı Durum):
                    {
                        "baslik": "Yemek Adı",
                        "icindekiler": [
                            {
                                "bolum_adi": "Genel" (Veya "Hamuru İçin", "Sosu İçin", "Şerbeti İçin" gibi detaylı başlıklar),
                                "malzemeler": ["Malzeme 1", "Malzeme 2"]
                            }
                        ],
                        "adimlar": ["Adım 1", "Adım 2", "Adım 3"],
                        "puf_noktasi": "Varsa püf noktası",
                        "success": true
                    }

                    Kullanılacak JSON Şeması (Hata Durumu - Yemek Değilse):
                    {
                        "success": false,
                        "message": "Girdiğiniz ifade bir yemek tarifi değil. Lütfen gerçek bir yemek ismi girin."
                    }
                    
                    Tarif dili: Türkçe olmalı. Süre veya kalori bilgisi VERME.`

                },
                {
                    "role": "user",
                    "content": `Bana şu yemek için bir tarif ver: ${userPrompt}`
                }
            ],
            temperature: 0.7, // Yaratıcılık seviyesi (0-1 arası)
        });

        // 5. Yanıtı İşleme
        if (!response || !response.choices || response.choices.length === 0) {
            console.error("AI Yanıtı Boş veya Geçersiz:", response);
            throw new HttpsError('internal', 'Yapay zeka yanıt vermedi. Lütfen tekrar deneyin.');
        }

        const rawContent = response.choices[0].message.content;

        // JSON formatını temizle (Markdown ```json ... ``` blokları varsa kaldır)
        let jsonContent = rawContent;
        if (rawContent.includes("```json")) {
            jsonContent = rawContent.replace(/```json\n/g, "").replace(/\n```/g, "");
        } else if (rawContent.includes("```")) {
            jsonContent = rawContent.replace(/```/g, "");
        }

        // JSON'a çevirip client'a dön
        const recipeData = JSON.parse(jsonContent);

        if (!recipeData) {
            throw new HttpsError('internal', 'AI yanıtı boş bir obje olarak döndü.');
        }

        // AI mantıksal olarak reddettiyse (Yemek değilse)
        if (recipeData.success === false) {
            return {
                success: false,
                message: recipeData.message || "Bu bir yemek tarifi gibi görünmüyor."
            };
        }

        return {
            success: true,
            data: recipeData
        };

    } catch (error) {
        console.error("OpenAI API Hatası:", error);

        // Hata durumunda kullanıcıya anlamlı bir mesaj dön
        if (error instanceof SyntaxError) {
            throw new HttpsError('internal', 'AI yanıtı işlenemedi (JSON format hatası).');
        }

        throw new HttpsError('internal', 'Tarif oluşturulurken bir hata oluştu: ' + error.message);
    }
});
