# MyFinanceTracker

🚀 My Finance Tracker: Akıllı Portföy ve Varlık Yönetimi
Bu proje, Mobil Programlama Dersi Final Ödevi kapsamında geliştirilmiş; modern bir yatırımcının tüm varlıklarını (Borsa, Altın, Döviz, Kripto) tek bir merkezden, gerçek zamanlı verilerle takip etmesini sağlayan profesyonel bir finans uygulamasıdır.Yapay Zeka (AI) desteği sağlayan ileri seviye bir finans uygulamasıdır.


📖 1. Proje Amacı ve Çözülen Problemler 

Bu uygulama kimin işine yarar? 

Farklı yatırım araçlarında (hisse senedi, altın, kripto para) dağınık portföyü olan ve toplam varlık durumunu anlık takip etmek isteyen bireysel yatırımcılar için geliştirilmiştir.AI destekli analizler almak isteyen bilinçli yatırımcılar için tasarlanmıştır.


Hangi problemi çözer? 

Yatırımcıların en büyük sorunu olan "Varlıklarımın şu anki toplam değeri nedir?" sorusuna yanıt verir. Manuel hesaplama karmaşasını ortadan kaldırarak, API üzerinden çektiği canlı verilerle otomatik portföy değerlemesi yapar.Gemini AI entegrasyonu ile kişiselleştirilmiş, akıllı yorumlar sunarak rehberlik eder.


Nerede ve nasıl kullanılır? 

Mobil cihazlar üzerinden kullanılır. Kullanıcı, sahip olduğu varlık miktarını sisteme bir kez tanımlar; uygulama arka planda güncel piyasa fiyatlarını çekerek kar/zarar durumunu ve toplam net varlığı kullanıcıya anlık sunar.

🛠 2. Teknik Altyapı ve Veritabanı 

Framework: Google Flutter / Dart.

Yapay Zeka (AI): Google Gemini AI API entegre edilmiştir. Uygulama, kullanıcının portföy verilerini analiz ederek yatırımcıya özel stratejik geri bildirimler oluşturur.

Veritabanı (Firebase Firestore): Kullanıcı varlıkları, portföy bilgileri ve ayarlar Firebase Firestore üzerinde asenkron olarak saklanmaktadır. Bu sayede veriler bulutta güvenle tutulur ve cihazlar arası senkronizasyon sağlanır.

API Entegrasyonu: (CollectAPI / CoinGecko) üzerinden canlı borsa ve piyasa verileri anlık olarak çekilerek uygulamaya entegre edilmiştir.


Çalışma Ortamı: Proje, Android Emülatör üzerinde sorunsuz performans gösterecek şekilde optimize edilmiştir.

🎨 3. Tasarım (UI/UX) ve Ekran Yapısı
Arayüz tasarımı Material Design prensiplerine uygun, modern ve kullanıcı dostu bir yapıda kurgulanmıştır:

Akıllı Analiz Ekranı: Gemini AI'dan gelen verilerin listelendiği detay ekranı.

Ana Ekran (Dashboard): Kullanıcının toplam varlığını, varlık dağılımını ve anlık piyasa özetlerini gördüğü merkez üssüdür.


Varlık Ekleme/Düzenleme Ekranı: Firestore ile entegre çalışan, kullanıcının kolayca yeni yatırım kalemleri ekleyebildiği dinamik form alanıdır.


Listeleme ve Detay Ekranı: Sahip olunan varlıkların listelendiği, kar/zarar analizlerinin ve performans verilerinin sunulduğu detaylı raporlama ekranıdır.

🎬 4. YouTube Tanıtım Videosu 
Uygulamanın amacı, ekran tanıtımları ve veritabanı işlemlerinin (ekleme/silme) emülatör üzerinde gösterildiği sunum videosu: 


🔗 [BURAYA YOUTUBE LİNKİNİ YAPIŞTIR]

EK BİLGİ= Daha fazla kripto varlık hisse senedi ve diğerleri eklencek  kullanıcı isteğiyle veri çekme işlemi yapmaya çalışıyorum sadece kullanıcı ne istiyosa o gözükce umarım yaparım  geliştirilme aşamasındadır.
