import Cocoa

class AirDropIcon {
    static func generate(size: CGFloat = 36, color: NSColor = .systemBlue) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let center = CGPoint(x: size / 2.0, y: size / 2.0)
        let baseAngle: CGFloat = -.pi / 4.0
        let span: CGFloat = .pi * 0.72
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(size * 0.085)
        ctx.setLineCap(.round)
        
        // Arc 3 (outer arc)
        ctx.addArc(center: center, radius: size * 0.42, startAngle: baseAngle - span/2, endAngle: baseAngle + span/2, clockwise: false)
        ctx.strokePath()
        
        // Arc 2 (middle arc)
        ctx.addArc(center: center, radius: size * 0.28, startAngle: baseAngle - span/2, endAngle: baseAngle + span/2, clockwise: false)
        ctx.strokePath()
        
        // Arc 1 (inner dot)
        ctx.setFillColor(color.cgColor)
        let dotRadius = size * 0.12
        ctx.fillEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
