const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

/*
  Bu özellik yeni backend klasörü altındaki bağımsız Express sunucusuna taşındı.
*/
// exports.generateRecipe = onCall(async (request) => { ... });
