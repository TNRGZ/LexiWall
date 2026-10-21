# Kaynaklar ve atıflar

## Yerel içerik

`seed.json` içindeki Türkçe anlamlar, açıklamalar, İngilizce örnekler ve Türkçe örnek çevirileri bu proje için hazırlanmıştır. Harici bir sözlükten toplu içerik kopyalanmamıştır. Bu yerel içerik ve LexiWall kaynak kodları MIT lisansı kapsamında sunulur. Çevrimiçi kaynaklardan sonradan gelen içerik bu lisansa dahil değildir.

## Datamuse

Kelime adayları ve kullanım sıklıkları [Datamuse API](https://www.datamuse.com/api/) ile alınır. Sıklık, Google Books Ngrams üzerinden milyon kelime başına kullanım tahminidir; seviye sertifikası değildir. Uygulama Datamuse tanımlarını istemez (`md=f`). Datamuse atfı uygulamanın Kurulum ekranında ve README’de korunur. API erişim koşulları değişebilir.

## Free Dictionary API ve Wiktionary

[Free Dictionary API](https://dictionaryapi.dev/) üzerinden gelen içerik kayıt bazında `license` ve `sourceUrls` bilgileriyle saklanır. Bu alanlar yoksa çevrimiçi kayıt kabul edilmez. İngilizce tanımlar ve örnekler çoğunlukla Wiktionary kaynaklıdır; her kaydın kendi lisansı esas alınır. Servisin uygulama kodunun lisansı ile API’nin sunduğu metnin lisansı aynı şey değildir; bu projeye servis kodu dahil edilmemiştir.

Türkçe açıklamalar, yan anlamlar ve cümle çevirileri bu metinlerin Apple Translation ile uyarlamalarıdır. Kaynak kayıt örneğin CC BY-SA kapsamında ise bu uyarlanmış metin de ilgili paylaşım koşullarıyla kullanılır. Her kartın ayrıntısında özgün kaynak ve lisans bağlantısı, üretilen çevrimiçi görselin altında kaynak URL’si, lisans adı/URL’si ve Türkçe uyarlama bilgisi yer alır. Bu atıfları kaldırmayın. Özgün katkı geçmişi için kaydın Wiktionary sayfasındaki geçmişe başvurulabilir.

Bu uygulama kaynak kodunun MIT lisansı, çevrimiçi sözlük metinlerinin ayrı lisanslarını değiştirmez. Ses dosyaları indirilmez veya yeniden dağıtılmaz.

## Apple

SwiftUI, UIKit, PhotoKit ve Translation sistem framework’leridir; üçüncü taraf ikili dağıtılmaz. Çeviri modeli, izinler ve dil desteği cihazın işletim sistemi tarafından yönetilir.
