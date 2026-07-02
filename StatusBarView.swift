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

// MARK: - Usage-based Color Helper for CPU & RAM (0% to 100%)
private func colorForUsage(_ percent: Double) -> NSColor {
    let clamped = min(max(percent, 0.0), 100.0) / 100.0  // 0.0 to 1.0
    let hue: CGFloat = CGFloat((1.0 - clamped) * 120.0 / 360.0)
    let saturation: CGFloat = CGFloat(0.6 + clamped * 0.4)
    let brightness: CGFloat = CGFloat(0.85 + clamped * 0.15)
    return NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
}

// MARK: - Bandwidth-based Color Helper for Network Speed
// Dynamic log-scale color mapping from low bandwidth (green) to heavy saturation (red).
private func colorForNetworkSpeed(_ bytesPerSec: Double, isDark: Bool, defaultColor: NSColor) -> NSColor {
    guard bytesPerSec >= 1024.0 else {
        // Under 1 KB/s: standard text color (idle / low activity)
        return defaultColor
    }
    
    // Logarithmic scale: 1 KB/s (log=0) to ~32 MB/s (log=4.5)
    let logKb = log10(bytesPerSec / 1024.0)
    let normalized = min(max(logKb / 4.5, 0.0), 1.0)
    
    let hue: CGFloat = CGFloat((1.0 - normalized) * 120.0 / 360.0) // 120° (Green) -> 0° (Red)
    let saturation: CGFloat = CGFloat(0.6 + normalized * 0.4)
    let brightness: CGFloat = isDark ? CGFloat(0.85 + normalized * 0.15) : CGFloat(0.75 + normalized * 0.2)
    
    return NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
}

private let rightAlignStyle: NSParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.alignment = .right
    return style
}()

// MARK: - Merged Compact Unified Status Item View
public class UnifiedStatsView: BaseStatsView {
    public var cpuPercent: Double = 0.0 {
        didSet { if oldValue != cpuPercent { needsDisplay = true } }
    }
    public var memGB: Double = 0.0 {
        didSet { if oldValue != memGB { needsDisplay = true } }
    }
    public var memPercent: Double = 0.0 {
        didSet { if oldValue != memPercent { needsDisplay = true } }
    }
    public var uploadBytesPerSec: Double = 0.0 {
        didSet { if oldValue != uploadBytesPerSec { needsDisplay = true } }
    }
    public var downloadBytesPerSec: Double = 0.0 {
        didSet { if oldValue != downloadBytesPerSec { needsDisplay = true } }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> (valStr: String, unitStr: String) {
        let units: [(threshold: Double, divisor: Double, unit: String)] = [
            (1000.0,             1.0,              "B"),
            (1000.0 * 1024.0,    1024.0,           "K"),
            (1000.0 * 1048576.0, 1048576.0,        "M"),
            (Double.infinity,    1073741824.0,      "G"),
        ]
        
        for tier in units {
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

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let textColor = isDark ? NSColor.white : NSColor.black
                
        // Auto-colors for network speeds based on active bandwidth
        let upTextColor = colorForNetworkSpeed(uploadBytesPerSec, isDark: isDark, defaultColor: textColor)
        let downTextColor = colorForNetworkSpeed(downloadBytesPerSec, isDark: isDark, defaultColor: textColor)
        
        let cpuColor = colorForUsage(cpuPercent)
        let memColor = colorForUsage(memPercent)

        let font = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .bold)
        let unitFont = NSFont.monospacedSystemFont(ofSize: 9.0, weight: .bold)
        let cpuMemUnitFont = NSFont.systemFont(ofSize: 9.0, weight: .bold)
        
        let line1Y: CGFloat = 11.0
        let line2Y: CGFloat = 1.0
        let lineH: CGFloat = 11.0
        
        // Compact layout breakdown:
        // Left Column (Network): x = 0..38 (Right-aligned to x = 38)
        // Right Column (CPU & Mem): x = 38..bounds.width - 2 (Right-aligned to bounds.width - 2)
        let netDrawWidth: CGFloat = 38.0
        let cpuMemDrawWidth = bounds.width - 2.0
        
        // --- COL 1, LINE 1: Upload (Speed Unit ▲) ---
        let (upValStr, upUnitStr) = formatSpeed(uploadBytesPerSec)
        let upAttrStr = NSMutableAttributedString()
        upAttrStr.append(NSAttributedString(string: upValStr, attributes: [
            .font: font, .foregroundColor: upTextColor, .paragraphStyle: rightAlignStyle
        ]))
        upAttrStr.append(NSAttributedString(string: " " + upUnitStr , attributes: [
            .font: unitFont, .foregroundColor: upTextColor.withAlphaComponent(isDark ? 0.75 : 0.65), .paragraphStyle: rightAlignStyle
        ]))
        upAttrStr.draw(in: CGRect(x: 0, y: line1Y, width: netDrawWidth, height: lineH))
        
        // --- COL 1, LINE 2: Download (Speed Unit ▼) ---
        let (downValStr, downUnitStr) = formatSpeed(downloadBytesPerSec)
        let downAttrStr = NSMutableAttributedString()
        downAttrStr.append(NSAttributedString(string: downValStr, attributes: [
            .font: font, .foregroundColor: downTextColor, .paragraphStyle: rightAlignStyle
        ]))
        downAttrStr.append(NSAttributedString(string: " " + downUnitStr, attributes: [
            .font: unitFont, .foregroundColor: downTextColor.withAlphaComponent(isDark ? 0.75 : 0.65), .paragraphStyle: rightAlignStyle
        ]))
        downAttrStr.draw(in: CGRect(x: 0, y: line2Y, width: netDrawWidth, height: lineH))
        
        // --- COL 2, LINE 1: CPU (%) ---
        let cpuValStr = String(format: "%.0f", cpuPercent)
        let cpuAttrStr = NSMutableAttributedString()
        cpuAttrStr.append(NSAttributedString(string: cpuValStr, attributes: [
            .font: font, .foregroundColor: cpuColor, .paragraphStyle: rightAlignStyle
        ]))
        cpuAttrStr.append(NSAttributedString(string: "%", attributes: [
            .font: cpuMemUnitFont, .foregroundColor: cpuColor.withAlphaComponent(isDark ? 0.75 : 0.65), .paragraphStyle: rightAlignStyle
        ]))
        cpuAttrStr.draw(in: CGRect(x: 0, y: line1Y, width: cpuMemDrawWidth, height: lineH))
        
        // --- COL 2, LINE 2: RAM (G) ---
        let memValStr = String(format: "%.1f", memGB)
        let memAttrStr = NSMutableAttributedString()
        memAttrStr.append(NSAttributedString(string: memValStr, attributes: [
            .font: font, .foregroundColor: memColor, .paragraphStyle: rightAlignStyle
        ]))
        memAttrStr.append(NSAttributedString(string: "G", attributes: [
            .font: cpuMemUnitFont, .foregroundColor: memColor.withAlphaComponent(isDark ? 0.75 : 0.65), .paragraphStyle: rightAlignStyle
        ]))
        memAttrStr.draw(in: CGRect(x: 0, y: line2Y, width: cpuMemDrawWidth, height: lineH))
    }
}
