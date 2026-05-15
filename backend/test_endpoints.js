const http = require('http');

const runTest = (name, headers, bodyData) => {
  return new Promise((resolve) => {
    console.log(`\n\n--- ${name} ---`);
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/generate-recipe',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };

    const req = http.request(options, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`Durum Kodu (Status): ${res.statusCode}`);
        try {
            console.log(`Cevap (Body):`, JSON.stringify(JSON.parse(data), null, 2));
        } catch(e) {
            console.log(`Cevap (Body): ${data}`);
        }
        resolve();
      });
    });

    req.on('error', e => {
      console.error(`İstek hatası: ${e.message}`);
      resolve();
    });

    if (bodyData) {
      req.write(JSON.stringify(bodyData));
    }
    req.end();
  });
};

const executeAll = async () => {
  console.log("TESTLER BAŞLIYOR...");
  
  await runTest("TEST 1: Kimlik Doğrulaması Olmadan", {}, { prompt: "Krep" });
  
  await runTest("TEST 2: Yanlış/Geçersiz Token İle", { 'Authorization': 'Bearer gecersiz-token-123' }, { prompt: "Krep" });
  
  await runTest("TEST 3: Doğru Token Ama Boş Girdi", { 'Authorization': 'Bearer test-test-test' }, { prompt: "" });
  
  await runTest("TEST 4: Doğru Token ve Geçerli Yemek İsmi", { 'Authorization': 'Bearer test-test-test' }, { prompt: "Mercimek Çorbası" });

  console.log("\n\nTÜM TESTLER BAŞARIYLA TAMAMLANDI.");
};

executeAll();
