import SwiftUI
import Translation

struct ContentView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        TabView {
            CreateView(model: model)
                .tabItem { Label("Oluştur", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            LibraryView(model: model)
                .tabItem { Label("Kelimeler", systemImage: "text.book.closed") }
            GuideView()
                .tabItem { Label("Kurulum", systemImage: "clock.arrow.circlepath") }
        }
        .translationTask(model.translationConfiguration) { session in
            await model.translate(using: session)
        }
        .alert("LexiWall", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Tamam", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .sheet(isPresented: $model.showGuide) { GuideView() }
    }
}

struct CreateView: View {
    @ObservedObject var model: AppModel
    @State private var resetConfirmation = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Her bakışta\nbir kelime.")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("İngilizceyi gününün bir parçası yap.")
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .center, spacing: 20) {
                        if let image = model.preview {
                            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 146).clipShape(RoundedRectangle(cornerRadius: 23))
                                .overlay(RoundedRectangle(cornerRadius: 23).stroke(.gray.opacity(0.2), lineWidth: 2))
                                .accessibilityLabel("by the way: bu arada. Saat ve tarih için üst bölüm boş.")
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Label("1206 × 2622", systemImage: "iphone")
                            Text("iPhone 16 Pro").foregroundStyle(.secondary)
                            Label("Saat alanı boş", systemImage: "clock")
                            Text("Önizlemede saat çizilmez; kilit ekranında iOS ekler.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.font(.subheadline)
                    }
                    sectionTitle("01", "Görünümünü seç")
                    HStack(spacing: 10) {
                        ForEach(WallpaperTheme.allCases) { theme in
                            Button {
                                model.theme = theme; model.updatePreview()
                            } label: {
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: theme.background))
                                        .frame(height: 48)
                                        .overlay(Text("Aa").font(.title3.bold()).foregroundStyle(Color(uiColor: theme.accent)))
                                    Text(theme.title).font(.subheadline)
                                }.padding(8)
                                    .background(model.theme == theme ? Color.accentColor.opacity(0.12) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(model.theme == theme ? .isSelected : [])
                        }
                    }.disabled(model.busy)
                    sectionTitle("02", "Paketini hazırla")
                    Picker("Görsel sayısı", selection: $model.count) {
                        Text("72 görsel").tag(72)
                        Text("168 görsel").tag(168)
                        Text("336 görsel").tag(336)
                    }.pickerStyle(.segmented).disabled(model.busy)
                    Text("Her kart farklı bir kelime veya ifade içerir. iOS karıştırma sırasını kendisi belirler.")
                        .font(.caption).foregroundStyle(.secondary)
                    DisclosureGroup("Seviye ve kategori") {
                        VStack(alignment: .leading, spacing: 14) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(Level.allCases) { level in
                                        filterButton(level.rawValue, selected: model.filter.levels.contains(level)) {
                                            if model.filter.levels.contains(level) { model.filter.levels.remove(level) }
                                            else { model.filter.levels.insert(level) }
                                        }
                                    }
                                }
                            }
                            ForEach(Category.allCases) { category in
                                Toggle(category.title, isOn: Binding(get: { model.filter.categories.contains(category) }, set: {
                                    if $0 { model.filter.categories.insert(category) } else { model.filter.categories.remove(category) }
                                }))
                            }
                            Text("Seviyeler rehber niteliğinde. Çevrimiçi içerikte seviye sıklıktan, kategori arama bağlamından tahmin edilir; resmî CEFR sınıflaması değildir.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 14)
                    }.disabled(model.busy)
                    HStack {
                        Label("\(model.available.count) yeni kart", systemImage: "sparkles")
                        Spacer()
                        Text("\(model.exportedCount) kaydedildi").foregroundStyle(.secondary)
                    }.font(.subheadline)
                    if model.available.count < model.count {
                        Text("Bu paket için yeterli yeni kart yok. Filtreleri genişlet veya havuzu internetten büyüt.")
                            .font(.callout).foregroundStyle(.orange)
                    }
                    Button { model.refresh() } label: {
                        Label("İnternetten yeni içerik ekle", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.bordered).disabled(model.busy || model.store == nil)
                    Text("Datamuse + Free Dictionary API + Apple Çeviri. Her arama en fazla 24 eksiksiz kart ekler. Dil paketi ilk seferde indirilebilir.")
                        .font(.caption).foregroundStyle(.secondary)
                    if model.busy {
                        ProgressView(value: model.progress)
                        Button("İşlemi durdur", role: .cancel) { model.stop() }.buttonStyle(.bordered)
                    }
                    Text(model.status).font(.callout).foregroundStyle(.secondary)
                        .accessibilityLabel("İşlem durumu: \(model.status)")
                    if model.hasUnfinishedExport {
                        Text("Yarım kalan paket, ilk seçtiğin kartlar ve temayla devam edecek.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Button { model.export() } label: {
                        Label(model.exportTitle, systemImage: "square.and.arrow.down")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }.buttonStyle(.borderedProminent)
                        .disabled(model.busy || model.store == nil || (model.available.count < model.count && !model.hasUnfinishedExport && model.store?.state.pending.isEmpty != false))
                    Text("Kayıt bitene kadar uygulamayı açık tut. Ardından Fotoğraf Karıştırma → Her Saat seçeneğini ayarla.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Tekrar geçmişini ve bildiklerimi sıfırla", role: .destructive) { resetConfirmation = true }
                        .font(.caption).disabled(model.busy)
                }.padding(24)
            }.background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle("LexiWall").navigationBarTitleDisplayMode(.inline)
                .confirmationDialog("Aynı kelimeler yeniden üretilebilir. Fotoğraflar albümü silinmez.", isPresented: $resetConfirmation, titleVisibility: .visible) {
                    Button("Geçmişi sıfırla", role: .destructive) { model.resetHistory() }
                }
        }
    }
    private func sectionTitle(_ number: String, _ title: String) -> some View {
        HStack(spacing: 10) { Text(number).foregroundStyle(.secondary).monospaced(); Text(title).fontWeight(.semibold) }
    }
    private func filterButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.bold()).padding(.horizontal, 14).padding(.vertical, 10)
                .background(selected ? Color.accentColor : Color.gray.opacity(0.15))
                .foregroundStyle(selected ? Color.white : Color.primary).clipShape(Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct LibraryView: View {
    @ObservedObject var model: AppModel
    @State private var search = ""
    @State private var selected: Lexeme?
    private var results: [Lexeme] {
        model.items.filter { model.filter.includes($0) && (search.isEmpty || $0.term.localizedCaseInsensitiveContains(search) || $0.meaning.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        NavigationStack {
            List {
                Section("\(results.count) kart · Oluştur sekmesindeki filtreler geçerli") {
                    ForEach(results) { item in
                        Button { selected = item } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.term).font(.headline).foregroundStyle(.primary)
                                    Text(item.meaning).font(.subheadline).foregroundStyle(.secondary)
                                    Text("\(item.level.rawValue) · \(item.category.title)\(item.isEstimated ? " · Tahmini" : "")").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if model.excluded.contains(item.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                            }.padding(.vertical, 4)
                        }.swipeActions {
                            Button("Biliyorum", systemImage: "checkmark") { model.markKnown(item) }.tint(.green).disabled(model.busy)
                        }
                    }
                }
            }.searchable(text: $search, prompt: "İngilizce veya Türkçe ara")
                .navigationTitle("Kelime havuzu")
                .sheet(item: $selected) { item in
                    NavigationStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(item.term).font(.largeTitle.bold())
                                Text(item.meaning).font(.title2).foregroundStyle(.tint)
                                Text(item.explanation)
                                if !item.secondary.isEmpty { Text("Diğer anlamlar: " + item.secondary.joined(separator: " • ")) }
                                Divider()
                                Text(item.example).font(.title3)
                                Text(item.exampleTR).foregroundStyle(.secondary)
                                if item.isEstimated {
                                    Text("Makine çevirisi; çok anlamlı kelimelerde bağlam farkı olabilir. Seviye ve kategori tahminidir.").font(.caption)
                                }
                                ForEach(item.sources, id: \.self) { source in
                                    if let url = URL(string: source.url) { Link(source.name, destination: url) }
                                    if let url = URL(string: source.licenseURL) { Link(source.license, destination: url) }
                                }
                                if let image = try? WallpaperRenderer.image(item, theme: model.theme) {
                                    Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 24))
                                }
                                Button("Bunu biliyorum, yeniden üretme") { model.markKnown(item); selected = nil }
                                    .buttonStyle(.borderedProminent).disabled(model.busy)
                            }.padding(24)
                        }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("Kapat") { selected = nil } } }
                    }
                }
        }
    }
}

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Saatlik duvar kâğıdı") {
                    Label("1. LexiWall’de görselleri kaydet.", systemImage: "photo.on.rectangle")
                    Label("2. Ayarlar → Duvar Kâğıdı → Yeni Duvar Kâğıdı Ekle.", systemImage: "gearshape")
                    Label("3. Fotoğraf Karıştırma → Albüm → LexiWall Hourly.", systemImage: "rectangle.stack")
                    Label("4. Karıştırma Sıklığı → Her Saat; ardından Albümü Kullan ve Ekle.", systemImage: "clock")
                }
                Section("Yerleşim") {
                    Text("Standart saat boyutu ve yakınlaştırılmamış görsel kullan. Üstte yaklaşık 800 piksel boş alan var. Duvar kâğıdını kırparsan, saati büyütürsen veya bildirimler görünürse metin örtülebilir. Önizlemede kontrol et.")
                    Text("Uygulama iOS duvar kâğıdını doğrudan değiştiremez. Saatlik seçimi sen yaparsın. iOS sıra veya tekrarsız gösterim garantisi vermez; 168 kart tam bir haftalık takvim değildir.")
                }
                Section("Çevrimdışı kullanım ve gizlilik") {
                    Text("Yerel kartlar ve indirilmiş kartlar çevrimdışı çalışır. Yeni kart araması kelime sorgularını Datamuse ve Free Dictionary API’ye gönderir. Fotoğrafların bu servislere gönderilmez.")
                    Text("Apple Çeviri dil paketlerini indirebilir. Simülatörde çeviri çalışmaz; gerçek iPhone kullan. Çeviri veya kaynak başarısız olduğunda eksik kartlar havuza alınmaz.")
                    Text("Albüm oluşturma ve yarım kalmış kayıtları denetlemek için Fotoğraflar’da Tam Erişim istenir. Uygulama mevcut fotoğrafları silmez.")
                }
                Section("Kaynaklar") {
                    Link("Datamuse — kelime ve sıklık", destination: URL(string: "https://www.datamuse.com/api/")!)
                    Link("Free Dictionary API — tanım ve örnek", destination: URL(string: "https://dictionaryapi.dev/")!)
                    Link("Apple — Fotoğraf Karıştırma", destination: URL(string: "https://support.apple.com/102638")!)
                    Text("Çevrimiçi sözlük içeriği ve çeviri uyarlamaları kayıtta belirtilen lisansa tabidir. Kaynak ve lisans bağlantıları her kartın ayrıntısında bulunur. Yerel örnekler bu proje için yazılmıştır.")
                    Text("Datamuse 2027 için anahtar zorunluluğu duyurdu. Servis erişimi değişirse yerel havuz ve indirilmiş kartlar çalışmaya devam eder.").font(.caption)
                }
            }.navigationTitle("Saatlik değişim")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Tamam") { dismiss() } } }
        }
    }
}
