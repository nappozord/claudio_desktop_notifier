import Cocoa

// Small shape helpers shared by the mascot and its props.

func block(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor, r: CGFloat = 0) {
    c.setFill()
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r).fill()
}
func smooth(_ x: Double) -> Double { let k = min(1, max(0, x)); return k * k * (3 - 2 * k) }

func disc(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor) {
    c.setFill()
    NSBezierPath(ovalIn: NSRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)).fill()
}

func poly(_ pts: [NSPoint], _ c: NSColor) {
    let p = NSBezierPath()
    p.move(to: pts[0])
    for pt in pts.dropFirst() { p.line(to: pt) }
    p.close()
    c.setFill(); p.fill()
}

func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ rot: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    for i in 0..<10 {
        let a = rot + CGFloat(i) * .pi / 5 + .pi / 2
        let rr = i % 2 == 0 ? r : r * 0.45
        let pt = NSPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr)
        if i == 0 { p.move(to: pt) } else { p.line(to: pt) }
    }
    p.close()
    return p
}

// four-pointed twinkle
func sparkle(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ c: NSColor) {
    poly([NSPoint(x: x, y: y + s), NSPoint(x: x + s * 0.28, y: y), NSPoint(x: x, y: y - s), NSPoint(x: x - s * 0.28, y: y)], c)
    poly([NSPoint(x: x + s, y: y), NSPoint(x: x, y: y + s * 0.28), NSPoint(x: x - s, y: y), NSPoint(x: x, y: y - s * 0.28)], c)
}
