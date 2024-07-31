import Cocoa
import CryptoKit

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
}

func hashString(_ text: String) -> CGFloat {
    let data = Data(text.utf8)
    let digest = Insecure.MD5.hash(data: data)
    
    // Convert last 2 bytes to an integer
    let firstTwoBytes = digest.suffix(2)
    let md5Int = Int(firstTwoBytes.reduce(0) { $0 << 8 + Int($1) })
    
    // Normalize the integer to a 0-360 range
    let angle = CGFloat(md5Int % 360)
    return angle
}

func colorFrom(text: String) -> NSColor {
    // Use HSL to ensure visibility of the text on the background
    let hue = hashString(text) / 360.0
    let saturation = 0.7
    let lightness = 1.0
    return NSColor(calibratedHue: hue, saturation: saturation, brightness: lightness, alpha: 1.0)
}

// Font icon using SF Symbols from the SF Pro font from Apple
// see https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/
class ThumbnailFontIconView: ThumbnailTitleView {
    convenience init(_ symbol: Symbols, _ tooltip: String?, _ size: CGFloat = Preferences.fontHeight, _ color: NSColor = .white, _ shadow: NSShadow? = ThumbnailView.makeShadow(NSColor.darkGray)) {
        self.init(size, nil)
        string = symbol.rawValue
        // This helps SF symbols display vertically centered and not clipped at the top
        font = NSFont(name: "SF Pro Text", size: (size * 0.99).rounded())!
        textColor = NSColor(red: 255.0/255.0, green: 132.0/255.0, blue: 56.0/255.0, alpha: 1.0)
        // This helps SF symbols not be clipped on the right
        widthAnchor.constraint(equalToConstant: size * 1.15).isActive = true
        toolTip = tooltip
    }

    // number should be in the interval [0-50]
    func setNumber(_ number: Int, _ filled: Bool) {
        let (baseCharacter, offset) = baseCharacterAndOffset(number, filled)
        assignIfDifferent(&string, String(UnicodeScalar(Int(baseCharacter.unicodeScalars.first!.value) + offset)!))
    }

    func setText(_ text: String) {
        assignIfDifferent(&string, text)
        textColor = colorFrom(text: text)
    }

    private func baseCharacterAndOffset(_ number: Int, _ filled: Bool) -> (String, Int) {
        if number <= 9 {
            // numbers alternate between empty and full circles; we skip the full circles
            return ((filled ? Symbols.filledCircledNumber0 : Symbols.circledNumber0).rawValue, number * 2)
        } else {
            return ((filled ? Symbols.filledCircledNumber10 : Symbols.circledNumber10).rawValue, number - 10)
        }
    }

    func setStar() {
        assignIfDifferent(&string, Symbols.circledStar.rawValue)
    }

    func setFilledStar() {
        assignIfDifferent(&string, Symbols.filledCircledStar.rawValue)
    }
}

class ThumbnailFilledFontIconView: NSView {
    convenience init(_ thumbnailFontIconView: ThumbnailFontIconView, _ backgroundColor: NSColor, _ size: CGFloat) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let backgroundView = ThumbnailFontIconView(.filledCircled, nil, size - 2, backgroundColor, nil)
        addSubview(backgroundView)
        addSubview(thumbnailFontIconView, positioned: .above, relativeTo: nil)
        backgroundView.frame.origin = CGPoint(x: backgroundView.frame.origin.x + 1, y: backgroundView.frame.origin.y + 1)
        fit(thumbnailFontIconView.fittingSize.width, thumbnailFontIconView.fittingSize.height)
    }
}
