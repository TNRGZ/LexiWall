# LexiWall — iPhone 16 Pro

İngilizce kelime ve kalıpları Türkçe açıklamalarla kilit ekranına taşıyan SwiftUI uygulaması. Hedef **iPhone 16 Pro, iOS 18 ve üzeri**. Arayüz Türkçe; görseller **1206 × 2622 piksel**.

**Teslim durumu:** Bu paket Xcode proje dosyasını, uygulama kaynaklarını, 360 yerel kartı ve XCTest testlerini içerir. Windows ortamında hazırlanmıştır. Swift sözdizimi ve proje yapısı denetlendi; **Xcode derlemesi, iPhone çalıştırması ve XCTest burada çalıştırılamadı**. Apple imzalı IPA üretilmedi. ZIP doğrudan iPhone’a kurulamaz; Mac/Xcode veya Windows + bulut derleme adımları gerekir. Gerçek cihaz doğrulaması yapılmadan App Store’a hazır kabul edilmemelidir.

## Mac bilgisayarın yoksa

**[Windows kurulum rehberini aç](WINDOWS-KURULUM.md).** Projeye GitHub Actions üzerinden buluttaki Mac’te test/derleme yapan ve AltStore ile Windows’tan kurulabilecek imzasız IPA hazırlayan akış eklendi. Kendi Mac’ine sahip olman gerekmez. Bulut derlemesi henüz çalıştırılmadı; kaynak ZIP’inin içinde hazır IPA yok. Ücretsiz Apple hesabıyla AltStore kurulumu haftalık yenileme gerektirir.

## Hızlı kurulum — Mac ve fiziksel iPhone

1. ZIP’i **Mac’te** aç. `LexiWall/` klasöründeki `LexiWall.xcodeproj` dosyasına çift tıkla. Yeni proje oluşturman, dosya eklemen veya XcodeGen kurman gerekmez.
2. **Xcode 16 veya daha yeni** bir sürüm kullan. Xcode sürümün, iPhone’unda kurulu iOS sürümünü de desteklemeli. Güncel bir iOS sürümündeki telefon için daha yeni Xcode gerekebilir.
3. Xcode → Settings → Accounts bölümüne kendi Apple hesabını ekle.
4. Sol tarafta LexiWall projesini, sonra **TARGETS → LexiWall → Signing & Capabilities** bölümünü aç. **Automatically manage signing** açık olsun. **Team** olarak kendi hesabını veya Personal Team’i seç.
5. **Bundle Identifier** değerini kendine özgü bir değerle değiştir; örneğin `com.adiniz.lexiwall`. Bu örnekteki adı kendin belirle. Testleri fiziksel cihazda çalıştıracaksan LexiWallTests hedefinde de takımını seç ve test kimliğini benzersiz yap.
6. iPhone’u USB ile bağla, kilidini aç ve “Bu bilgisayara güven” isteğini onayla.
7. iPhone → Ayarlar → Gizlilik ve Güvenlik → **Geliştirici Modu** seçeneğini etkinleştir. Telefon yeniden başlatma ve onay isteyebilir. Seçenek görünmüyorsa önce Xcode’un telefonu tanımasını bekle. [Apple’ın Geliştirici Modu rehberi](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
8. Xcode’un üst çubuğunda **LexiWall** şemasını ve hedef olarak kendi iPhone’unu seç; **Run / ▶** düğmesine bas.
9. iOS ayrıca geliştiriciye güvenmeni isterse Ayarlar → Genel → VPN ve Aygıt Yönetimi içinden kendi geliştirici hesabını onayla.
10. Uygulamada ilk denemeyi tüm seviyeler/kategoriler açıkken 72 kartla yap. Fotoğraflar izninde **Tam Erişim** seç.

Kendi cihazında denemek için ücretsiz Personal Team kullanılabilir. Apple’ın belgesine göre bu hesapla kurulum sağlayan profiller **7 gün sonra sona erer**; yeniden Xcode’dan çalıştırmak gerekebilir. Kaydedilmiş duvar kâğıtları Fotoğraflar’da kalır. [Apple hesap türleri](https://developer.apple.com/help/account/basics/about-your-developer-account). TestFlight/App Store dağıtımı için uygun geliştirici üyeliği ve dağıtım süreci gerekir; bu pakette dağıtım sertifikası veya özel anahtar bulunmaz.

## İlk kullanım

1. **Oluştur** sekmesinde Gece, Kâğıt veya Orman temasını seç.
2. **72 / 168 / 336 görsel** seçeneklerinden birini seç.
3. İstersen A1–C1 seviyelerini veya Günlük yaşam, İş hayatı, Seyahat, Teknoloji, Kalıplar kategorilerini filtrele. Görünen “yeni kart” sayısı kaydedilmiş ve “biliyorum” işaretli kartları içermez.
4. Havuzu büyütmek için **İnternetten yeni içerik ekle** düğmesine dokun. Gerekirse Apple’ın İngilizce ve Türkçe dil paketlerinin indirilmesini onayla. Bu adım çevrimdışı başlangıç kartları için gerekli değildir.
5. **Görselleri Fotoğraflar’a kaydet** düğmesine dokun. Uygulamayı ön planda tut. Görseller `LexiWall Hourly` albümüne eklenir.
6. İşlem kesilirse uygulama yeniden açıldığında **Kalan … görseli kaydet** ile aynı pakete devam et. Önceden seçilen tema ve kartlar korunur; yeni filtreler bu yarım paketi değiştirmez.

İlk kurulumda 360 benzersiz yerel kart vardır: **193 günlük yaşam, 46 iş hayatı, 33 seyahat, 27 teknoloji, 61 kalıp**. 336 kart ürettikten sonra yerel havuzda yalnızca 24 yeni kart kalır. Sonraki büyük paket için internetten içerik eklemen veya bilinçli biçimde tekrar geçmişini sıfırlaman gerekir. Dar filtrelerde 72 kart bile bulunmayabilir; uygulama eksik sayıyı tekrarla doldurmaz.

**Kelimeler** sekmesinde arama yapabilir, kartın iki dilde tam içeriğini ve çevrimiçi kaynağını görebilir, sola kaydırıp **Biliyorum** diyebilirsin. Yarım kalan paket bitene kadar “biliyorum” değişikliği engellenir. Geçmişi sıfırlama işlemi onay ister ve mevcut Fotoğraflar görsellerini silmez; sonraki paketlerde tekrarları mümkün kılar.

## Saatlik duvar kâğıdı değişimi

1. iPhone’da **Ayarlar → Duvar Kâğıdı → Yeni Duvar Kâğıdı Ekle** yolunu aç.
2. **Fotoğraf Karıştırma / Photo Shuffle** seç.
3. Albüm seçeneğinden **LexiWall Hourly** albümünü seç.
4. **Karıştırma Sıklığı / Shuffle Frequency → Her Saat / Hourly** ayarını yap.
5. **Albümü Kullan / Use Album**, ardından **Ekle** ile tamamla. Gerekirse kilit ekranı ve ana ekranı ayrı düzenle.

Menü adları iOS dili/sürümüne göre değişebilir. Çok sayıda kart için albüm seçimini kullan; elle tek tek fotoğraf seçimi iOS tarafından sınırlandırılabilir. [Apple’ın albüm ve saatlik karıştırma adımları](https://support.apple.com/en-us/102638).

**Uygulama sistem duvar kâğıdını kendisi değiştirmez.** Saatlik değişimi iOS yapar. LexiWall üretimde aynı kelimeyi tekrarlamaz; Photo Shuffle’ın gösterme sırasını ve tekrarını kontrol edemez. 72/168/336 görsel, tam 3/7/14 günlük tekrarsız bir takvim garantisi değildir.

## Saat/tarih için yerleşim

- Çıktı 1206 × 2622, ölçek 1 ve yüksek kaliteli JPEG’dir.
- Üstte ilk 800 pikselde metin bulunmaz. Küçük ayırıcı çizgi 808. pikselde, içerik **y=860–2250** aralığındadır. Altta kilit ekranı denetimleri için boşluk kalır.
- Başlık, ana anlam, kısa açıklama, varsa en fazla iki başka anlam, İngilizce cümle ve Türkçe çeviri çizilir. Metin ölçülür; gerekirse yazı boyutu düşürülür. Hâlâ sığmayan içerik kırpılıp eksik gösterilmez, hata olarak ele alınır.
- Uygulamanın önizlemesi aynı UIKit çizim kodunu kullanır. Örnek saat görselin içine basılmaz; gerçek saati iOS gösterir.
- Duvar kâğıdını yakınlaştırma/kırpma ve standarttan çok büyük saat kullanma. Bildirimler veya özelleştirilmiş saat metnin üzerine gelebilir; son yerleşimi kilit ekranı önizlemesinde kontrol et. Diğer iPhone boyutları için ayrı yerleşim garantisi verilmez.

## İnternet, çeviri ve yedek içerik

**Datamuse:** İngilizce kelime/çok sözcüklü ifade adayları ve `f:` kullanım sıklığı alınır. Tanımları bu kaynaktan çekmiyoruz. Kategoriye göre anlam araması, değişen harf örüntüleri ve kalıp örüntüleri kullanılır. İnternet havuzu 360 kelimeyle sınırlı değildir; başarılı aramalar kalıcı önbelleği büyütür. Bir arama en fazla 45 adayı inceler ve en fazla 24 eksiksiz kart ekler. [API belgesi](https://www.datamuse.com/api/).

**Free Dictionary API:** Sözcüğün tanımları, varsa İngilizce örnek cümle ve kaynak/lisans bilgisi alınır. Örnek cümlesi, lisansı veya kaynağı bulunmayan aday atlanır. Örneğin ait olduğu tanım açıklamanın temelini oluşturur; iki ek tanım varsa yan anlam olarak çevrilir. 404, “bu kelime sözlükte yok” kabul edilir. [API belgesi](https://dictionaryapi.dev/).

**Apple Translation:** iOS 18’deki `translationTask`, `LanguageAvailability`, `prepareTranslation` ve `translations(from:)` kullanılır. Kelime, seçilen açıklama, yan anlamlar ve örnek cümle İngilizceden Türkçeye çevrilir. Dil indirimi kullanıcının sistem onayına tabidir. Simülatörde çeviri desteklenmez; gerçek cihaz gerekir. [Apple örnek proje ve belgeleri](https://developer.apple.com/documentation/translation/translating-text-within-your-app).

Ana anlam, tek başına kelimenin makine çevirisidir; çok anlamlı sözcüklerde örneğin bağlamıyla tamamen örtüşmeyebilir. Açıklama ve cümle çevirisi bu yüzden birlikte sunulur. Çevrimiçi kartlar makine çevirisi olarak işaretlenir; bir dil uzmanının onayladığı sözlük iddiası yoktur. Yerel 360 kart bu proje için yazılmıştır; onların seviyeleri de yaklaşık öğrenme rehberidir. İnternetten gelen seviyeler sıklık eşiklerinden, kategoriler arama bağlamından tahmin edilir; resmî CEFR sınıflaması değildir.

API anahtarı veya ücretli hizmet zorunlu değildir **mevcut erişim koşullarında**. Ancak Datamuse sayfası 2027’de anahtar zorunluluğu duyuruyor: üst duyuruda 1 Şubat, kullanım sınırları bölümünde 1 Ocak tarihi yazıyor (21 Ekim 2026 kontrolü). Kesin başlangıç tarihini servisle yeniden kontrol et. Koşullar değişirse `Network.swift` içindeki kaynak uyarlanabilir. Uygulama içine gizli anahtar gömmek yerine gerekirse kendi sunucu katmanını kullan. Bu sürümde anahtar alanı veya sunucu yoktur.

Bağlantı kesilmesi, zaman aşımı, 429, 401/403, bozuk JSON, çeviri iptali ve eksik içerik ele alınır. Geçici ağ/5xx hatalarında en fazla bir tekrar yapılır; seri başarısızlıklarda arama durur. Çeviri başarısızsa bilinmeyen kelime için uydurma Türkçe kart üretilmez. Yerel ve daha önce başarıyla indirilmiş kartlar kullanılmaya devam eder. Her çevrimiçi sorgu yeni kart bulmayı garanti etmez.

## Kayıt güvenilirliği ve veri konumu

Kaynak içerik ve geçmiş uygulamanın Application Support klasöründeki `LexiWall/library-v1.json` dosyasına atomik yazılır. Kelimeler büyük/küçük harf, boşluk ve kesme işareti bakımından normalize edilir. Bilinenler, kaydedilenler ve henüz doğrulanmamış kayıtlar ayrı tutulur.

Paketin seçimi ve teması kayda başlamadan önce saklanır. Görseller tek tek çizilip geçici dosyaya yazılır; Fotoğraflar’a altışarlı gruplar hâlinde eklenir. Aynı anda 336 bitmap bellekte tutulmaz. Fotoğraf işlemi sırasında durdurma istenirse mevcut grup tamamlanır. Önce kayıt günlüğü yazılır; Fotoğraflar’daki grup doğrulandıktan sonra geçmiş ilerletilir. Uygulama arada kapanırsa kaynak dosya adlarındaki SHA-256 kimlikleriyle yalnızca kendi albümündeki kayıtlar uzlaştırılır. Bu mekanizma yerel kapanma/kesinti durumlarını azaltır; kullanıcının albümü elle silmesi veya başka cihazlarda eşzamanlı düzenleme yapması ayrıca kontrol edilmelidir.

Fotoğraflar’da **Tam Erişim** albümü bulmak ve kayıtları uzlaştırmak için gereklidir; “Sınırlı erişim” veya yalnızca ekleme izni bu akışta kabul edilmez. Kaydetme öncesinde izin istenir. Mevcut kişisel fotoğraflar silinmez veya ağ servislerine gönderilmez. Albüm aynı adlı birden fazla kez elle oluşturulmuşsa ilk bulunan albüm kullanılır; tek bir `LexiWall Hourly` albümü tut.

Uygulama silinirse yerel önbellek ve tekrar geçmişi silinir; Fotoğraflar’daki görseller kalabilir. Yeniden kurulum sonrası önceki üretim geçmişi otomatik geri yüklenmez. Bozulmuş geçmiş dosyası sessizce sıfırlanmaz; uygulama hata gösterip dosyayı korur.

## Xcode ile doğrulama

Paylaşılan **LexiWall** şeması uygulama ve test hedefini içerir. Üçüncü taraf Swift paketi, CocoaPods veya ağdan derleme bağımlılığı yoktur.

Mac’te Terminal’den proje klasöründe:

```sh
# iOS SDK ile imzasız cihaz derlemesi
xcodebuild -project LexiWall.xcodeproj -scheme LexiWall \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

# Kullanılabilir simülatörleri listele
xcodebuild -showdestinations -project LexiWall.xcodeproj -scheme LexiWall

# Listeden uygun iPhone 16 Pro simülatörünün kimliğini kullan
xcodebuild -project LexiWall.xcodeproj -scheme LexiWall \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -derivedDataPath build -resultBundlePath build/LexiWallTests.xcresult test
```

`SIMULATOR_UUID` yer tutucusunu liste çıktısındaki kimlikle değiştir. Önceki sonuç paketi varsa yeni bir `-resultBundlePath` seç. Alternatif olarak Xcode’da Product → Test (⌘U) kullan. Testler 360 kaydın bütünlüğünü, tekrar/filtre mantığını, kalıcı geçmişi, yarım paket seçimini, bozuk dosya davranışını, ağ hata/eksik örnek senaryolarını, tüm yerel kartların üç temada sınırlarını ve gerçek görsel piksel boyutunu kontrol eder. Ağ birim testleri gerçek servisleri kullanmaz.

Fiziksel iPhone’da ayrıca şunları doğrula:

- İlk açılışta uçak modunda 72 kart üretimi; Fotoğraflar’da doğru albüm, adet ve boyut.
- Tam erişim reddi ve sınırlı erişimde anlaşılır mesaj; sonradan izin verilince başarı.
- 168/336 kartlık temiz başlangıç; kaydetme sırasında durdurma, uygulamayı kapatma, yeniden açıp kalan seçimi tamamlama.
- Ağ açıkken dil paketinin ilk indirilmesi ve sonraki çevrimiçi kartların Türkçe içeriği. Dil indirimini reddetme/çeviriyi iptal etme.
- Üç temada uzun kartlar ve gerçek kilit ekranındaki saat/tarih konumu.
- Önceden kaydedilenlerin ve “biliyorum” işaretlenenlerin sonraki paketlere girmemesi.
- Albüm tabanlı Photo Shuffle → Hourly; sistemin seçtiği fotoğrafların okunabilirliği.

Bu teslim sırasında yapılan ve yapılamayan kontroller `VALIDATION.md` dosyasında ayrı listelenmiştir.

## Dosyalar

| Dosya | İşlev |
|---|---|
| `LexiWall.xcodeproj` | Doğrudan açılan proje ve paylaşılan şema |
| `LexiWall/Core.swift` | İçerik modeli, filtreler, tekrar mantığı, atomik kayıt |
| `LexiWall/Network.swift` | Datamuse ve Free Dictionary API, kaynak/lisans ayrıştırma |
| `LexiWall/AppModel.swift` | Çeviri, içerik ekleme, devam edilebilir üretim |
| `LexiWall/WallpaperRenderer.swift` | Piksel boyutu ve metin yerleşimi |
| `LexiWall/PhotoExporter.swift` | İzin, albüm, küçük grup kaydı ve uzlaştırma |
| `LexiWall/ContentView.swift` | Oluştur, Kelimeler ve Kurulum ekranları |
| `LexiWall/seed.json` | 360 özgün yerel kelime/kalıp kartı |
| `LexiWallTests/` | XCTest kontrolleri |
| `THIRD_PARTY_NOTICES.md` | Kaynaklar ve içerik lisanslarının işlenmesi |

