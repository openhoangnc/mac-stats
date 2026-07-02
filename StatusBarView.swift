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

// MARK: - CPU & Memory Status Item View (Block 1)
public class CPUMemView: BaseStatsView {
    public var cpuPercent: Double = 0.0 {
        didSet { if oldValue != cpuPercent { needsDisplay = true } }
    }
    public var memGB: Double = 0.0 {
        didSet { if oldValue != memGB { needsDisplay = true } }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let textColor = isDark ? NSColor.white : NSColor.black
        let secondaryTextColor = textColor.withAlphaComponent(0.7)

        let font = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .bold)
        let unitFont = NSFont.systemFont(ofSize: 8.0, weight: .semibold)
        
        // Formatted strings
        let cpuValStr = String(format: "%2.0f", cpuPercent)
        let memValStr = String(format: "%4.1f", memGB)
        
        // Define column positions for perfect vertical alignment
        // Column 1: Value (Right aligned to x = 24)
        // Column 2: Unit (Left aligned at x = 26)
        let valRightX: CGFloat = 25.0
        let unitLeftX: CGFloat = 27.0
        
        let line1Y: CGFloat = 11.0
        let line2Y: CGFloat = 1.0
        
        // --- Line 1: CPU ---
        let cpuValAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let cpuValSize = cpuValStr.size(withAttributes: cpuValAttrs)
        let cpuValRect = CGRect(x: valRightX - cpuValSize.width, y: line1Y, width: cpuValSize.width, height: 10)
        cpuValStr.draw(in: cpuValRect, withAttributes: cpuValAttrs)
        
        let cpuUnitStr = "%"
        let cpuUnitAttrs: [NSAttributedString.Key: Any] = [.font: unitFont, .foregroundColor: secondaryTextColor]
        let cpuUnitRect = CGRect(x: unitLeftX, y: line1Y + 0.5, width: 15, height: 10)
        cpuUnitStr.draw(in: cpuUnitRect, withAttributes: cpuUnitAttrs)
        
        // --- Line 2: RAM ---
        let memValAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let memValSize = memValStr.size(withAttributes: memValAttrs)
        let memValRect = CGRect(x: valRightX - memValSize.width, y: line2Y, width: memValSize.width, height: 10)
        memValStr.draw(in: memValRect, withAttributes: memValAttrs)
        
        let memUnitStr = "G"
        let memUnitAttrs: [NSAttributedString.Key: Any] = [.font: unitFont, .foregroundColor: secondaryTextColor]
        let memUnitRect = CGRect(x: unitLeftX, y: line2Y + 0.5, width: 15, height: 10)
        memUnitStr.draw(in: memUnitRect, withAttributes: memUnitAttrs)
    }
}

// MARK: - Network Speed Status Item View (Block 2)
public class NetworkSpeedView: BaseStatsView {
    public var uploadBytesPerSec: Double = 0.0 {
        didSet { if oldValue != uploadBytesPerSec { needsDisplay = true } }
    }
    public var downloadBytesPerSec: Double = 0.0 {
        didSet { if oldValue != downloadBytesPerSec { needsDisplay = true } }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> (valStr: String, unitStr: String) {
        if bytesPerSec < 1024 {
            return (String(format: "%3.0f", bytesPerSec), "B/s")
        } else if bytesPerSec < 1024 * 1024 {
            let kb = bytesPerSec / 1024.0
            if kb < 10 {
                return (String(format: "%3.1f", kb), "K/s")
            } else {
                return (String(format: "%3.0f", kb), "K/s")
            }
        } else if bytesPerSec < 1024 * 1024 * 1024 {
            let mb = bytesPerSec / (1024.0 * 1024.0)
            if mb < 10 {
                return (String(format: "%3.1f", mb), "M/s")
            } else {
                return (String(format: "%3.0f", mb), "M/s")
            }
        } else {
            let gb = bytesPerSec / (1024.0 * 1024.0 * 1024.0)
            return (String(format: "%3.1f", gb), "G/s")
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let textColor = isDark ? NSColor.white : NSColor.black
        let upColor = isDark ? NSColor(calibratedRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0) : NSColor.systemBlue
        let downColor = isDark ? NSColor(calibratedRed: 0.4, green: 1.0, blue: 0.5, alpha: 1.0) : NSColor.systemGreen

        let font = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .bold)
        let arrowFont = NSFont.systemFont(ofSize: 8.0, weight: .bold)
        let unitFont = NSFont.monospacedSystemFont(ofSize: 8.0, weight: .semibold)
        
        let (upValStr, upUnitStr) = formatSpeed(uploadBytesPerSec)
        let (downValStr, downUnitStr) = formatSpeed(downloadBytesPerSec)
        
        // Multi-column vertical alignment layout:
        // Col 1: Arrow Icon (x = 2)
        // Col 2: Value (Right-aligned to x = 32)
        // Col 3: Unit (Left-aligned at x = 34)
        let arrowX: CGFloat = 2.0
        let valRightX: CGFloat = 31.0
        let unitLeftX: CGFloat = 33.0
        
        let line1Y: CGFloat = 11.0
        let line2Y: CGFloat = 1.0
        
        // --- Line 1: Upload ---
        let upArrowStr = "▲"
        let upArrowAttrs: [NSAttributedString.Key: Any] = [.font: arrowFont, .foregroundColor: upColor]
        upArrowStr.draw(in: CGRect(x: arrowX, y: line1Y + 0.5, width: 10, height: 10), withAttributes: upArrowAttrs)
        
        let upValAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let upValSize = upValStr.size(withAttributes: upValAttrs)
        let upValRect = CGRect(x: valRightX - upValSize.width, y: line1Y, width: upValSize.width, height: 10)
        upValStr.draw(in: upValRect, withAttributes: upValAttrs)
        
        let upUnitAttrs: [NSAttributedString.Key: Any] = [.font: unitFont, .foregroundColor: textColor.withAlphaComponent(0.7)]
        upUnitStr.draw(in: CGRect(x: unitLeftX, y: line1Y + 0.5, width: 20, height: 10), withAttributes: upUnitAttrs)
        
        // --- Line 2: Download ---
        let downArrowStr = "▼"
        let downArrowAttrs: [NSAttributedString.Key: Any] = [.font: arrowFont, .foregroundColor: downColor]
        downArrowStr.draw(in: CGRect(x: arrowX, y: line2Y + 0.5, width: 10, height: 10), withAttributes: downArrowAttrs)
        
        let downValAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let downValSize = downValStr.size(withAttributes: downValAttrs)
        let downValRect = CGRect(x: valRightX - downValSize.width, y: line2Y, width: downValSize.width, height: 10)
        downValStr.draw(in: downValRect, withAttributes: downValAttrs)
        
        let downUnitAttrs: [NSAttributedString.Key: Any] = [.font: unitFont, .foregroundColor: textColor.withAlphaComponent(0.7)]
        downUnitStr.draw(in: CGRect(x: unitLeftX, y: line2Y + 0.5, width: 20, height: 10), withAttributes: downUnitAttrs)
    }
}
