import AppKit

public class BaseStatsView: NSView {
    public var onClick: (() -> Void)?
    public var onRightClick: (() -> Void)?

    override public func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override public func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}

// MARK: - Color Utilities
private func getContrastOptimizedColor(normalized: Double, isDark: Bool) -> NSColor {
    let clamped = min(max(normalized, 0.0), 1.0)
    let hueDegrees = 120.0 - clamped * 130.0
    let hue = (hueDegrees < 0.0 ? hueDegrees + 360.0 : hueDegrees) / 360.0
    
    let saturation: CGFloat
    let brightness: CGFloat
    
    if isDark {
        saturation = CGFloat(0.40 + clamped * 0.05)
        brightness = CGFloat(0.95 + clamped * 0.05)
    } else {
        saturation = CGFloat(0.85 + clamped * 0.05)
        brightness = CGFloat(0.28 + clamped * 0.05)
    }
    
    return NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
}

private func colorForUsage(_ percent: Double, isDark: Bool) -> NSColor {
    let clamped = min(max(percent, 0.0), 100.0) / 100.0
    return getContrastOptimizedColor(normalized: clamped, isDark: isDark)
}

private func colorForNetworkSpeed(_ bytesPerSec: Double, isDark: Bool, defaultColor: NSColor) -> NSColor {
    guard bytesPerSec >= 1024.0 else { return defaultColor }
    let logKb = log10(bytesPerSec / 1024.0)
    let normalized = min(max(logKb / 4.5, 0.0), 1.0)
    return getContrastOptimizedColor(normalized: normalized, isDark: isDark)
}


// MARK: - Static constants (allocated once for app lifetime)
private let rightAlignStyle: NSParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.alignment = .right
    return style
}()

private let font = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .bold)
private let unitFont = NSFont.monospacedSystemFont(ofSize: 9.0, weight: .bold)
private let cpuMemUnitFont = NSFont.systemFont(ofSize: 9.0, weight: .bold)

private let speedTiers: [(threshold: Double, divisor: Double, unit: String)] = [
    (1000.0,             1.0,              "B"),
    (1000.0 * 1024.0,    1024.0,           "K"),
    (1000.0 * 1048576.0, 1048576.0,        "M"),
    (Double.infinity,    1073741824.0,      "G"),
]

// MARK: - Unified Status Bar View with Cached Rendering
public class UnifiedStatsView: BaseStatsView {
    // Raw input values
    private var _cpuPercent: Double = -1
    private var _memGB: Double = -1
    private var _memPercent: Double = -1
    private var _uploadBPS: Double = -1
    private var _downloadBPS: Double = -1

    // Cached rendered attributed strings (survive across frames)
    private var cachedUpLine: NSAttributedString?
    private var cachedDownLine: NSAttributedString?
    private var cachedCpuLine: NSAttributedString?
    private var cachedMemLine: NSAttributedString?

    // Cached formatted display strings (used as cache invalidation keys)
    private var lastUpKey: String = ""
    private var lastDownKey: String = ""
    private var lastCpuKey: String = ""
    private var lastMemKey: String = ""

    // Cached appearance state
    private var cachedIsDark: Bool? = nil

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    public func updateValues(cpuPercent: Double, memGB: Double, memPercent: Double,
                             uploadBytesPerSec: Double, downloadBytesPerSec: Double) {
        var changed = false
        if _cpuPercent != cpuPercent { _cpuPercent = cpuPercent; changed = true }
        if _memGB != memGB { _memGB = memGB; changed = true }
        if _memPercent != memPercent { _memPercent = memPercent; changed = true }
        if _uploadBPS != uploadBytesPerSec { _uploadBPS = uploadBytesPerSec; changed = true }
        if _downloadBPS != downloadBytesPerSec { _downloadBPS = downloadBytesPerSec; changed = true }
        if changed { needsDisplay = true }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> (val: String, unit: String) {
        for tier in speedTiers {
            if bytesPerSec < tier.threshold {
                let scaled = bytesPerSec / tier.divisor
                if scaled < 10.0 && tier.divisor > 1.0 {
                    return (String(format: "%.1f", scaled), tier.unit)
                } else {
                    return (String(format: "%.0f", scaled), tier.unit)
                }
            }
        }
        return (String(format: "%.0f", bytesPerSec), "B")
    }

    private func buildLine(val: String, unit: String, color: NSColor, dimAlpha: CGFloat,
                           valFont: NSFont, uFont: NSFont) -> NSAttributedString {
        let s = NSMutableAttributedString()
        s.append(NSAttributedString(string: val, attributes: [
            .font: valFont, .foregroundColor: color, .paragraphStyle: rightAlignStyle
        ]))
        s.append(NSAttributedString(string: " " + unit, attributes: [
            .font: uFont, .foregroundColor: color.withAlphaComponent(dimAlpha), .paragraphStyle: rightAlignStyle
        ]))
        return s
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let appearanceChanged = (isDark != cachedIsDark)
        if appearanceChanged {
            cachedIsDark = isDark
            cachedUpLine = nil; cachedDownLine = nil; cachedCpuLine = nil; cachedMemLine = nil
            lastUpKey = ""; lastDownKey = ""; lastCpuKey = ""; lastMemKey = ""
        }

        let textColor = isDark ? NSColor.white : NSColor.black
        let dimAlpha: CGFloat = isDark ? 0.75 : 0.65

        let line1Y: CGFloat = 11.0
        let line2Y: CGFloat = 1.0
        let lineH: CGFloat = 11.0
        let netW: CGFloat = 38.0
        let cpuMemW = bounds.width - 2.0

        // Upload — only rebuild attributed string if formatted display text changed
        let (upVal, upUnit) = formatSpeed(_uploadBPS)
        let upKey = upVal + upUnit
        if cachedUpLine == nil || upKey != lastUpKey {
            lastUpKey = upKey
            let upColor = colorForNetworkSpeed(_uploadBPS, isDark: isDark, defaultColor: textColor)
            cachedUpLine = buildLine(val: upVal, unit: upUnit, color: upColor, dimAlpha: dimAlpha,
                                     valFont: font, uFont: unitFont)
        }
        cachedUpLine!.draw(in: CGRect(x: 0, y: line1Y, width: netW, height: lineH))

        // Download
        let (downVal, downUnit) = formatSpeed(_downloadBPS)
        let downKey = downVal + downUnit
        if cachedDownLine == nil || downKey != lastDownKey {
            lastDownKey = downKey
            let downColor = colorForNetworkSpeed(_downloadBPS, isDark: isDark, defaultColor: textColor)
            cachedDownLine = buildLine(val: downVal, unit: downUnit, color: downColor, dimAlpha: dimAlpha,
                                       valFont: font, uFont: unitFont)
        }
        cachedDownLine!.draw(in: CGRect(x: 0, y: line2Y, width: netW, height: lineH))

        // CPU
        let cpuKey = String(format: "%.0f", _cpuPercent)
        if cachedCpuLine == nil || cpuKey != lastCpuKey {
            lastCpuKey = cpuKey
            let cpuColor = colorForUsage(_cpuPercent, isDark: isDark)
            cachedCpuLine = buildLine(val: cpuKey, unit: "%", color: cpuColor, dimAlpha: dimAlpha,
                                       valFont: font, uFont: cpuMemUnitFont)
        }
        cachedCpuLine!.draw(in: CGRect(x: 0, y: line1Y, width: cpuMemW, height: lineH))

        // RAM
        let memKey = String(format: "%.1f", _memGB)
        if cachedMemLine == nil || memKey != lastMemKey {
            lastMemKey = memKey
            let memColor = colorForUsage(_memPercent, isDark: isDark)
            cachedMemLine = buildLine(val: memKey, unit: "G", color: memColor, dimAlpha: dimAlpha,
                                       valFont: font, uFont: cpuMemUnitFont)
        }
        cachedMemLine!.draw(in: CGRect(x: 0, y: line2Y, width: cpuMemW, height: lineH))
    }
}
