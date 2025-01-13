import Cocoa
import CommonCrypto

enum Symbols: String {
    case circledPlusSign = "􀁌"
    case circledMinusSign = "􀁎"
    case circledSlashSign = "􀕧"
    case circledNumber0 = "􀀸"
    case circledNumber10 = "􀓵"
    case circledStar = "􀕬"
    case filledCircledStar = "􀕭"
    case filledCircled = "􀀁"
    case filledCircledNumber0 = "􀀹"
    case filledCircledNumber10 = "􀔔"
    case circledInfo = "􀅴"
}

func sha256Hash(_ string: String) -> [UInt8] {
    // Convert the string to a Data object
    let data = Data(string.utf8)
    
    // Prepare an empty buffer for the hash
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    // Perform the hash operation
    _ = data.withUnsafeBytes { bytes in
        CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
    }
    
    // Convert the hash bytes to a hexadecimal string
    return hash
}

func colorFrom(text: String) -> NSColor {
    let hash = sha256Hash(text)
    
    // Convert first bytes to an integer
    let hashInt = Int(hash.prefix(3).reduce(0) { $0 << 8 + Int($1) })
    // Use HSL to ensure visibility of the text on the background
    // Capped at 310 to remove pink
    let hue = CGFloat(hashInt % 11) / 11 * 310
    var saturation = 0.7
    var lightness = 1.0
    if hue > 110.0 && hue < 170.0 {
        saturation = 0.6
        lightness = 0.9
    }
    return NSColor(calibratedHue: hue / 360, saturation: saturation, brightness: lightness, alpha: 1.0)
}


// Font icon using SF Symbols from the SF Pro font from Apple
// see https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/
class ThumbnailFontIconView: ThumbnailTitleView {
    static var paragraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        // clip the top of the box since we know these symbols are always disks
        paragraphStyle.lineHeightMultiple = 0.85
        return paragraphStyle
    }()
    var initialAttributedString: NSMutableAttributedString!

    convenience init(symbol: Symbols, tooltip: String? = nil, size: CGFloat = Appearance.fontHeight,
                     color: NSColor = Appearance.fontColor,
                     shadow: NSShadow? = ThumbnailView.makeShadow(Appearance.indicatedIconShadowColor)) {
        // This helps SF symbols display vertically centered and not clipped at the top
        self.init(shadow: nil, font: NSFont(name: "SF Pro Text", size: (size * 1).rounded())!)
        initialAttributedString = NSMutableAttributedString(string: symbol.rawValue, attributes: [.paragraphStyle: ThumbnailFontIconView.paragraphStyle])
        attributedStringValue = initialAttributedString
        textColor = color
        toolTip = tooltip
        addOrUpdateConstraint(widthAnchor, cell!.cellSize.width)
    }

    // number should be in the interval [0-50]
    func setNumber(_ number: Int, _ filled: Bool) {
        let (baseCharacter, offset) = baseCharacterAndOffset(number, filled)
        replaceCharIfNeeded(String(UnicodeScalar(Int(baseCharacter.unicodeScalars.first!.value) + offset)!))
    }

    func setStar() {
        replaceCharIfNeeded(Symbols.circledStar.rawValue)
    }

    func setFilledStar() {
        replaceCharIfNeeded(Symbols.filledCircledStar.rawValue)
    }
    
    func setText(_ monitorId: UInt32, _ text: String) {
        replaceCharIfNeeded(text)
        textColor = colorFrom(text: text)
    }

    private func replaceCharIfNeeded(_ newChar: String) {
        if newChar != attributedStringValue.string {
            initialAttributedString.replaceCharacters(in: NSRange(location: 0, length: newChar.count), with: newChar)
            attributedStringValue = initialAttributedString
        }
    }

    private func baseCharacterAndOffset(_ number: Int, _ filled: Bool) -> (String, Int) {
        if number <= 9 {
            // numbers alternate between empty and full circles; we skip the full circles
            return ((filled ? Symbols.filledCircledNumber0 : Symbols.circledNumber0).rawValue, number * 2)
        } else {
            return ((filled ? Symbols.filledCircledNumber10 : Symbols.circledNumber10).rawValue, number - 10)
        }
    }
}

class ThumbnailFilledFontIconView: NSView {
    convenience init(_ thumbnailFontIconView: ThumbnailFontIconView, backgroundColor: NSColor, size: CGFloat) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let backgroundView = ThumbnailFontIconView(symbol: .filledCircled, size: size - 4, color: backgroundColor, shadow: nil)
        addSubview(backgroundView)
        addSubview(thumbnailFontIconView, positioned: .above, relativeTo: nil)
        backgroundView.centerXAnchor.constraint(equalTo: thumbnailFontIconView.centerXAnchor).isActive = true
        let offset = ((thumbnailFontIconView.cell!.cellSize.width - backgroundView.cell!.cellSize.width) / 2).rounded()
        backgroundView.topAnchor.constraint(equalTo: thumbnailFontIconView.topAnchor, constant: offset).isActive = true
        widthAnchor.constraint(equalTo: thumbnailFontIconView.widthAnchor).isActive = true
        heightAnchor.constraint(equalTo: thumbnailFontIconView.heightAnchor).isActive = true
    }
}
