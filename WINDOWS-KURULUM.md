# Mac olmadan LexiWall kurulumu

Kendi Mac bilgisayarına ihtiyacın yok. Derleme GitHub’ın buluttaki Mac bilgisayarında yapılır; iPhone’a yükleme Windows bilgisayarındaki AltServer ve telefondaki AltStore Classic ile yapılır.

**Derleme durumu:** Kaynaklar [TNRGZ/LexiWall](https://github.com/TNRGZ/LexiWall) deposunda paylaşılır. Güncel test ve derleme sonucunu [Actions sayfasından](https://github.com/TNRGZ/LexiWall/actions) kontrol et. Yalnızca başarıyla tamamlanan çalışmalardan IPA indir. iPhone’a kurabilmek için imzasız IPA’yı kendi Apple hesabınla AltStore üzerinden imzalaman gerekir. Uygulamanın gerçek cihazda çeviri ve Fotoğraflar davranışı ayrıca doğrulanmalıdır.

## 1. Projeyi GitHub’a koy

GitHub hesabında ayrı bir `LexiWall` deposu kullan. ZIP’i Windows’ta çıkart. Depoya ZIP dosyasını değil, içindeki proje dosyalarını yükle. Deponun en üstünde şunlar olmalı:

```text
.github/workflows/build-ipa.yml
ci/build_ipa.py
LexiWall.xcodeproj/
LexiWall/
LexiWallTests/
WINDOWS-KURULUM.md
README.md
```

Özellikle `.github` klasörünü dahil et; Windows Dosya Gezgini’nde noktayla başlayan klasörü de seç. GitHub’ın web arayüzü gizli klasörü yüklemene izin vermezse `.github/workflows/build-ipa.yml` dosyasını GitHub’da **Add file → Create new file** ile aynı yolda oluşturup paketteki içeriği yapıştırabilirsin. Projeyi fazladan bir üst `LexiWall` klasörü içinde bırakma.

Görünürlüğü sen seç: **Private** kaynak kodunu gizli tutar ve hesabındaki Actions kotasını kullanır; kota sonrası ücret olabilir. **Public** kodu herkese açar; standart GitHub Actions çalıştırıcıları bu depolarda ücretsizdir. Bu paket GitHub’da otomatik depo açmaz, kod yayımlamaz veya harcama başlatmaz. [GitHub’ın çalıştırıcı ve kota açıklaması](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## 2. Bulutta derle

1. Deponun **Actions** sekmesini aç.
2. **LexiWall - Windows icin IPA** iş akışını seç.
3. **Run workflow** düğmesine bas. Bundle identifier varsayılanı `com.tnrgz.lexiwall`; kendi uygulama kimliğini istersen değiştirebilirsin.
4. Tamamlanınca çalışma sayfasının **Artifacts** bölümünden **LexiWall-unsigned-IPA** paketini indir ve ZIP’i aç.
5. İçinden çıkan **LexiWall-unsigned.ipa** kurulumda kullanılacak dosyadır. `build-info.json` derleme sonucunu belirtir.

Akış önce iOS simülatöründe testleri çalıştırır; bunlar geçerse fiziksel iPhone için uygulamayı derleyip IPA olarak paketler. Test/derleme hatası olduğunda IPA teslim etmez. **LexiWall-diagnostics** paketindeki günlükler hatanın bulunmasını sağlar. Bulutta çalışan simülatör Apple çevirisinin yerine geçmez.

Bu işlem için Apple parolası, sertifika, ücretli Apple Developer üyeliği veya GitHub secret girilmez. İş akışı yalnızca elle başlatılır, 45 dakika sınırı vardır ve çıktılarını yedi gün saklar. Başlatmadan önce GitHub hesabının Actions kotasını kontrol et.

## 3. Windows’tan iPhone’a yükle

1. [AltStore’un resmî Windows rehberini](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) aç. Oradaki Apple yazılım gereksinimlerini tamamlayıp **AltServer for Windows** kur. Resmî rehber doğrudan Apple’dan alınan iTunes/iCloud sürümlerini öneriyor; Microsoft Store iCloud için ayrıca alternatif adımlar veriyor.
2. iPhone’u USB ile bağla, kilidini aç ve bilgisayara güven.
3. AltServer menüsünden **Install AltStore → iPhone’un** seçimini yap. Apple hesabına yalnızca bu kurulum arayüzünde giriş yap; parolanı bu sohbete veya GitHub’a yazma.
4. Telefonda gerektiğinde Ayarlar → Genel → VPN ve Aygıt Yönetimi üzerinden kendi geliştirici hesabına güven; Ayarlar → Gizlilik ve Güvenlik → **Geliştirici Modu** açık olsun.
5. Üretilen `LexiWall-unsigned.ipa` dosyasını iPhone’un **Dosyalar** uygulamasına aktar. iCloud Drive kullanabilirsin.
6. Bilgisayarda AltServer açıkken, iPhone’da **AltStore Classic → My Apps → +** yoluyla IPA’yı seç. AltServer bağlantısı gerektiği için telefon ve bilgisayarın aynı yerel ağda olduğundan emin ol.

Bu süreç **AltStore Classic** içindir; AltStore PAL mağaza akışı değildir. Kurulum adımları zamanla değişebilir; resmî rehberi esas al.

## 4. Yedi günlük yenileme ve duvar kâğıtları

Ücretsiz Apple hesabıyla yüklenen uygulamalar yedi gün sonra yenilenmelidir. AltServer erişilebilirken AltStore’da **Refresh All** kullanılabilir; otomatik arka plan yenilemesi de mümkündür. Ücretsiz hesapta aynı anda üç yandan yüklenmiş uygulama sınırı vardır. [AltStore kullanım ve yenileme belgesi](https://faq.altstore.io/altstore-classic/your-altstore).

LexiWall’de bir kez görselleri Fotoğraflar’a kaydettikten sonra saatlik değişim iOS tarafından yapılır. LexiWall’in sürekli açık kalması gerekmez; uygulamanın imzası sona erse bile Fotoğraflar’a kaydedilmiş görseller silinmez. Yeni paket üretmek için uygulama yeniden açılabilir durumda olmalıdır.

Uygulama açıldıktan sonra **72/168/336 görsel üret → Fotoğraflar’da Tam Erişim ver → Ayarlar → Duvar Kâğıdı → Fotoğraf Karıştırma → LexiWall Hourly → Her Saat** adımlarını izle.

## TestFlight alternatifi

Haftalık yenileme istemiyorsan daha sonra TestFlight dağıtımı hazırlanabilir. Bunun için uygulamayı dağıtan hesabın ücretli Apple Developer Program üyeliği gerekir; normal Apple hesabı yeterli değildir. Bu paketin bulut akışı TestFlight yüklemesi yapmaz. [Apple’ın dağıtım koşulları](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases/).
