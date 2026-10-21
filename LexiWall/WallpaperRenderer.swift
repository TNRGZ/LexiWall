import UIKit
import CryptoKit

enum WallpaperTheme: String, CaseIterable, Identifiable {
    case midnight, paper, forest
    var id: String { rawValue }
    var title: String {
        switch self { case .midnight: return "Gece"; case .paper: return "Kâğıt"; case .forest: return "Orman" }
    }
    var background: UIColor {
        switch self { case .midnight: return UIColor(hex: 0x101928); case .paper: return UIColor(hex: 0xF5F0E6); case .forest: return UIColor(hex: 0x102C27) }
    }
    var foreground: UIColor { self == .paper ? UIColor(hex: 0x17241F) : UIColor(hex: 0xF3F3ED) }
    var accent: UIColor {
        switch self { case .midnight: return UIColor(hex: 0xA4D7FC); case .paper: return UIColor(hex: 0x3A7665); case .forest: return UIColor(hex: 0xD8E8AB) }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

@MainActor
enum WallpaperRenderer {
    static let size = CGSize(width: 1206, height: 2622)
    static let safeContent = CGRect(x: 104, y: 860, width: 998, height: 1390)
    struct Block {
        var text: String
        var font: UIFont
        var color: UIColor
        var gap: CGFloat
    }
    struct Layout {
        var blocks: [Block]
        var rects: [CGRect]
    }

    static func layout(_ item: Lexeme, theme: WallpaperTheme) throws -> Layout {
        for scale in stride(from: 1.0, through: 0.68, by: -0.02) {
            let s = CGFloat(scale)
            var blocks = [
                Block(text: "\(item.level.rawValue)  /  \(item.category.title.uppercased(with: Locale(identifier: "tr_TR")))", font: .systemFont(ofSize: 27, weight: .semibold), color: theme.accent, gap: 36),
                Block(text: item.term, font: .systemFont(ofSize: 104 * s, weight: .bold), color: theme.foreground, gap: 18),
                Block(text: item.meaning, font: .systemFont(ofSize: 58 * s, weight: .medium), color: theme.accent, gap: 34),
                Block(text: item.explanation, font: .systemFont(ofSize: 38 * s), color: theme.foreground.withAlphaComponent(0.8), gap: 34)
            ]
            if !item.secondary.isEmpty {
                blocks.append(Block(text: "DİĞER ANLAMLAR\n" + item.secondary.joined(separator: " • "), font: .systemFont(ofSize: 32 * s), color: theme.foreground.withAlphaComponent(0.75), gap: 38))
            }
            blocks.append(Block(text: "“\(item.example)”", font: .systemFont(ofSize: 43 * s, weight: .medium), color: theme.foreground, gap: 18))
            blocks.append(Block(text: item.exampleTR, font: .systemFont(ofSize: 35 * s), color: theme.foreground.withAlphaComponent(0.7), gap: 35))
            let credit = item.sources.first.map { source in
                return "\(source.name): \(source.url)\n\(source.license) · \(source.licenseURL)\nTürkçe uyarlama: Apple Translation · Seviye/kategori tahmini"
            } ?? "LEXIWALL  /  HER SAAT BİR KEŞİF"
            blocks.append(Block(text: credit, font: .systemFont(ofSize: 22), color: theme.foreground.withAlphaComponent(0.5), gap: 0))
            var y = safeContent.minY
            var rects: [CGRect] = []
            for block in blocks {
                let rect = (block.text as NSString).boundingRect(with: CGSize(width: safeContent.width, height: 4000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes(block), context: nil)
                let height = ceil(rect.height) + 3
                rects.append(CGRect(x: safeContent.minX, y: y, width: safeContent.width, height: height))
                y += height + block.gap * s
            }
            if y <= safeContent.maxY { return Layout(blocks: blocks, rects: rects) }
        }
        throw LexiError.message("‘\(item.term)’ kartı güvenli alana sığmıyor. Bu kartı bildiklerime ekleyip yeniden deneyin.")
    }
    private static func attributes(_ block: Block) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        paragraph.lineBreakMode = .byWordWrapping
        return [.font: block.font, .foregroundColor: block.color, .paragraphStyle: paragraph]
    }
    static func image(_ item: Lexeme, theme: WallpaperTheme) throws -> UIImage {
        let layout = try layout(item, theme: theme)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            theme.background.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let colors = [theme.accent.withAlphaComponent(0.12).cgColor, theme.background.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 1206, y: 2622), end: CGPoint(x: 300, y: 600), options: [])
            }
            theme.accent.setFill()
            UIBezierPath(roundedRect: CGRect(x: 104, y: 808, width: 70, height: 7), cornerRadius: 3.5).fill()
            for (block, rect) in zip(layout.blocks, layout.rects) {
                (block.text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes(block), context: nil)
            }
        }
    }
    static func fileName(for key: String) -> String {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return "lexiwall-\(hash).jpg"
    }
}
