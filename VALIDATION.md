# Doğrulama kaydı — 21 Ekim 2026

## Bu ortamda tamamlanan kontroller

| Kontrol | Sonuç |
|---|---|
| Swift kaynakları ve testler | 9 dosya Tree-sitter Swift ayrıştırıcısıyla okundu; sıfır sözdizimi hatası |
| Xcode proje dosyası | OpenStep ve pbxproj ayrıştırıcılarıyla okundu; 51 proje nesnesinin referansları çözüldü |
| Projeye kaynak ekleme | 7 uygulama ve 2 test Swift dosyası ilgili kaynak gruplarında ve derleme girdilerinde bulundu |
| Kaynak dosyalar | JSON, görsel kataloğu ve gizlilik bildirimi proje kaynaklarına bağlı; eksik dosya yok |
| Yapılandırma | Info.plist ve PrivacyInfo.xcprivacy okundu; paylaşılan şema ve workspace XML’i ayrıştırıldı |
| Yerel kelimeler | 360 benzersiz kayıt; zorunlu iki dilli alanlar, uzunluklar, seviye/kategori değerleri doğrulandı |
| Temel kapasite | Tüm filtreler açıkken başlangıçta 72/168/336 farklı kartı sağlayacak sayıda kayıt var |
| Uygulama simgesi | 1024 × 1024 RGB, alfa kanalı yok |

Yerel seviye dağılımı: A1=205, A2=63, B1=69, B2=13, C1=10. Kategori dağılımı: günlük=193, teknoloji=27, seyahat=33, iş=46, kalıplar=61. Bu seviyeler yaklaşık rehberdir.

## Canlı servis denemeleri

| İstek | Gözlenen sonuç |
|---|---|
| Datamuse, `ml=everyday life&md=f&max=600` | HTTP 200; 379 kayıt, 379 sıklık etiketi |
| Datamuse, `sp=* *&md=f&max=600` | HTTP 200; 600 kayıt, 600 sıklık etiketi |
| Free Dictionary API, `approach` | HTTP 200; lisans/kaynak bilgisi bulunan 1 kayıt, 3 örnek cümle |
| Free Dictionary API, `by the way` | HTTP 530; başarılı kabul edilmedi. Bu kalıp yerel havuzda mevcut. |

Bu istekler geliştirme bilgisayarından yapıldı. iPhone’un ağ koşullarını, Apple çevirisini veya gelecekteki servis erişimini doğrulamaz. Servis hataları gerçek bir olasılıktır; yerel içerik ve eksik kartı atlama davranışı bu yüzden bulunur.

## Pakete eklenen, burada çalıştırılamayan testler

16 XCTest metodu bulunur. Kapsam: anahtar normalizasyonu, 360 kaydın bütünlüğü, üç paket boyutu, ardışık paketlerde tekrar engelleme, yetersiz havuz, boş filtre, kalıcı geçmiş ve kayıt günlüğü, yarım kalan paketin kalan seçimi, bozuk dosyayı koruma, tüm yerel kartların üç temada yerleşimi, 1206 × 2622 raster boyutu, kaynak sıklık sıralaması, eksik tanım/atıf, sözlükte bulunmayan kelime, örnek cümle/tanım eşleşmesi ve 429/bozuk JSON davranışı.

**Çalıştırılmadı:** `xcodebuild`, Apple SDK tür denetimi ve bağlama, XCTest, iOS simülatörü, fiziksel iPhone, UIKit görsellerinin görsel incelemesi, Photos izin/kayıt döngüsü, Apple dil paketi ve çeviri, saatlik Photo Shuffle. Bu ortam Windows’tur ve Xcode/iOS SDK içermez.

**Sözdizimi ayrıştırması başarılı bir Xcode derlemesi demek değildir.** README’deki Mac komutları ve fiziksel cihaz kontrol listesi kalan doğrulamayı tarif eder. İmzalı IPA oluşturulmadı; sertifika veya provisioning profile eklenmedi.

## Mac olmadan kurulum için eklenen akış

`.github/workflows/build-ipa.yml` ve `ci/build_ipa.py` eklendi. Akış yalnızca elle başlatılır; macOS çalıştırıcısında önce testleri, sonra fiziksel iOS derlemesini yapar. Başarılı sonuç imzasız IPA ve tanılama dosyalarıdır. GitHub hesabında depo açılmadı, kaynak yüklenmedi ve bu akış henüz çalıştırılmadı. Windows üzerinde Python sözdizimi, simülatör seçme mantığı, iş akışı yapısı ve kaynak ZIP’ine dahil edilmesi denetlenir; bunlar gerçek bulut derlemesi yerine geçmez.
