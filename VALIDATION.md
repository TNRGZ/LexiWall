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

## Bulutta çalıştırılan testler ve cihaz derlemesi

16 XCTest metodu bulunur. Kapsam: anahtar normalizasyonu, 360 kaydın bütünlüğü, üç paket boyutu, ardışık paketlerde tekrar engelleme, yetersiz havuz, boş filtre, kalıcı geçmiş ve kayıt günlüğü, yarım kalan paketin kalan seçimi, bozuk dosyayı koruma, tüm yerel kartların üç temada yerleşimi, 1206 × 2622 raster boyutu, kaynak sıklık sıralaması, eksik tanım/atıf, sözlükte bulunmayan kelime, örnek cümle/tanım eşleşmesi ve 429/bozuk JSON davranışı.

**21 Ekim 2026 — başarılı:** [GitHub Actions çalışması #1](https://github.com/TNRGZ/LexiWall/actions/runs/39612452125), kaynak commit `d2d634fc12343abbd1ebc47b652b2bd99e7c8235`. Xcode 16.4 (16F6), iPhone 16 Pro / iOS 18.5 simülatörü. `xcodebuild test`: **16 test, 0 hata**; ardından Release / iphoneos derlemesi: **BUILD SUCCEEDED**. UIKit ile 360 kartın üç temadaki metin sınırları ve örnek raster boyutu testlerde doğrulandı.

İndirilen Actions ZIP’inin SHA-256 özeti GitHub artifact özetiyle eşleşti. IPA arşivi ve Info.plist açıldı; Mach-O dosyasında **arm64 / fiziksel iOS**, minimum iOS **18.0**, kimlik **com.tnrgz.lexiwall**, **360 yerel kayıt** doğrulandı. IPA’da XCTest paketi veya provisioning profile bulunmuyor.

IPA SHA-256: `e03e8a9b4597c14569ac4a4ea7dd3a7d93324b62bbfee09ffecc1ce6f27908b6`.

**Henüz çalıştırılmadı:** fiziksel iPhone’a AltStore ile kurulum, Photos izin/albüm/kayıt döngüsü, Apple dil paketi ve çeviri, gerçek kilit ekranında görsel inceleme, saatlik Photo Shuffle. README’deki fiziksel cihaz adımları kalan doğrulamayı tarif eder. Apple dağıtım imzalı IPA oluşturulmadı; kullanıcının kendi hesabıyla imzalaması gerekir.

## Mac olmadan kurulum için eklenen akış

`.github/workflows/build-ipa.yml` ve `ci/build_ipa.py` yalnızca elle başlatılır; macOS çalıştırıcısında önce testleri, sonra fiziksel iOS derlemesini yapar. [TNRGZ/LexiWall](https://github.com/TNRGZ/LexiWall) deposu kullanıcının isteğiyle herkese açık oluşturuldu ve kaynaklar yüklendi. İlk akış 7 dakika 21 saniyede başarıyla tamamlandı; imzasız IPA ve tanılama dosyaları üretildi. Windows üzerinde Python sözdizimi, simülatör seçme mantığı ve iş akışı yapısı da doğrulandı. Derlemeden sonraki belge güncellemesi uygulama veya test kodunu değiştirmedi.
