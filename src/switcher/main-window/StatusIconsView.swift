import Cocoa
import CommonCrypto

class StatusIconsView: FlippedView {
    struct Icon {
        var symbol: String
        var tooltip: String?
        var color: NSColor? = nil
        var visible = false
    }

    static let spaceIdx = 0
    static let hiddenIdx = 1
    static let fullscreenIdx = 2
    static let minimizedIdx = 3

    private static let defaultSymbols: [(Symbols, String?)] = [
        (.circledNumber0, nil),
        (.circledSlashSign, NSLocalizedString("App is hidden", comment: "")),
        (.circledPlusSign, NSLocalizedString("Window is fullscreen", comment: "")),
        (.circledMinusSign, NSLocalizedString("Window is minimized", comment: "")),
    ]

    var icons: [Icon]
    private var visibleCount = 0
    private var tooltipsDirty = true
    /// Single-character cell size, cached at init for the layout cache
    let iconCellSize: NSSize

    @objc func _windowChangedKeyState() {}
    @objc func _layoutSubtreeWithOldSize(_ oldSize: NSSize) {}

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: NSRect) {
        let font = NSFont(name: "SF Pro Text", size: Appearance.fontHeight.rounded())!
        let measureAttrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: TileFontIconView.paragraphStyle]
        icons = Self.defaultSymbols.map { Icon(symbol: $0.0.rawValue, tooltip: $0.1) }
        iconCellSize = NSAttributedString(string: Symbols.circledNumber0.rawValue, attributes: measureAttrs).size()
        super.init(frame: frame)
    }

    static func cachedAttrString(for symbol: String, color: NSColor = Appearance.fontColor) -> NSAttributedString {
        let size = Appearance.fontHeight
        let key = TileFontIconView.SymbolCacheKey(symbol: symbol, size: size, colorKey: TileFontIconView.symbolColorKey(color))
        if let cached = TileFontIconView.symbolCache[key] { return cached }
        let font = NSFont(name: "SF Pro Text", size: size.rounded())!
        let str = NSAttributedString(string: symbol, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: TileFontIconView.paragraphStyle,
        ])
        TileFontIconView.symbolCache[key] = str
        return str
    }

    required init?(coder: NSCoder) { fatalError() }

    var totalWidth: CGFloat { CGFloat(visibleCount) * TilesView.layoutCache.iconWidth }

    func update(isHidden: Bool, isFullscreen: Bool, isMinimized: Bool, showSpace: Bool) {
        icons[Self.hiddenIdx].visible = isHidden
        icons[Self.fullscreenIdx].visible = isFullscreen
        icons[Self.minimizedIdx].visible = isMinimized
        icons[Self.spaceIdx].visible = showSpace
        visibleCount = icons.count(where: { $0.visible })
    }

    func setSpaceStar() {
        icons[Self.spaceIdx].symbol = Symbols.circledStar.rawValue
        icons[Self.spaceIdx].tooltip = NSLocalizedString("Window is on every Space", comment: "")
        icons[Self.spaceIdx].color = nil
    }

    func setSpaceNumber(_ number: Int) {
        icons[Self.spaceIdx].symbol = Self.symbolForSpace(number)
        icons[Self.spaceIdx].tooltip = String(format: NSLocalizedString("Window is on Space %d", comment: ""), number)
        icons[Self.spaceIdx].color = nil
    }

    func setSpaceText(_ text: String) {
        icons[Self.spaceIdx].symbol = text
        icons[Self.spaceIdx].tooltip = text
        icons[Self.spaceIdx].color = Self.colorFrom(text)
    }

    static func symbolForSpace(_ number: Int) -> String {
        let (base, offset) = number <= 9
            ? (Symbols.circledNumber0.rawValue, number * 2)
            : (Symbols.circledNumber10.rawValue, number - 10)
        return String(UnicodeScalar(Int(base.unicodeScalars.first!.value) + offset)!)
    }

    private static func colorFrom(_ text: String) -> NSColor {
        let hash = sha256Hash(text)
        let hashInt = (Int(hash[0]) << 16) | (Int(hash[1]) << 8) | Int(hash[2])
        let hue = CGFloat(hashInt % 11) / 11 * 310
        let saturation: CGFloat = hue > 110.0 && hue < 170.0 ? 0.6 : 0.7
        let brightness: CGFloat = hue > 110.0 && hue < 170.0 ? 0.9 : 1.0
        return NSColor(calibratedHue: hue / 360, saturation: saturation, brightness: brightness, alpha: 1.0)
    }

    private static func sha256Hash(_ text: String) -> [UInt8] {
        let data = Data(text.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash
    }

    var spaceVisible: Bool { icons[Self.spaceIdx].visible }

    func layoutIcons(hWidth: CGFloat, hHeight: CGFloat, edgeInsets: CGFloat) {
        let indicatorSpace = totalWidth
        assignIfDifferent(&frame.size.width, indicatorSpace)
        assignIfDifferent(&frame.size.height, hHeight)
        let isLTR = App.shared.userInterfaceLayoutDirection == .leftToRight
        assignIfDifferent(&frame.origin.x, isLTR ? edgeInsets + hWidth - indicatorSpace : edgeInsets)
        assignIfDifferent(&frame.origin.y, edgeInsets)
        tooltipsDirty = true
        needsDisplay = true
    }

    func ensureTooltipsInstalled() {
        guard tooltipsDirty else { return }
        tooltipsDirty = false
        removeAllToolTips()
        let iconWidth = TilesView.layoutCache.iconWidth
        let iconHeight = TilesView.layoutCache.iconHeight
        let isLTR = App.shared.userInterfaceLayoutDirection == .leftToRight
        let yOffset = ((frame.height - iconHeight) / 2).rounded()
        var offset = CGFloat(0)
        for icon in icons {
            guard icon.visible else { continue }
            offset += iconWidth
            let x = isLTR ? frame.width - offset : offset - iconWidth
            if let tooltip = icon.tooltip {
                _ = addToolTip(NSRect(x: x, y: yOffset, width: iconWidth, height: iconHeight), owner: tooltip as NSString, userData: nil)
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard visibleCount > 0 else { return }
        let iconWidth = TilesView.layoutCache.iconWidth
        let iconHeight = TilesView.layoutCache.iconHeight
        let isLTR = App.shared.userInterfaceLayoutDirection == .leftToRight
        let yOffset = ((frame.height - iconHeight) / 2).rounded()
        var offset = CGFloat(0)
        for icon in icons {
            guard icon.visible else { continue }
            offset += iconWidth
            let x = isLTR ? frame.width - offset : offset - iconWidth
            Self.cachedAttrString(for: icon.symbol, color: icon.color ?? Appearance.fontColor).draw(at: NSPoint(x: x, y: yOffset))
        }
    }
}
