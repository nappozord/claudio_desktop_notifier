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

// rounds off every vertex of an arbitrary closed polygon — split out from roundedStar below so a
// caller can perturb individual points first (the mascot's star body moves its two "arm"
// points), not just round the plain, static star shape. The rounding trick: at each vertex, stop
// `corner` units short along both neighboring edges, then curve between those two points using
// the original (sharp) vertex as both control points — a cheap, good-enough approximation of a
// true rounded corner with no arc-angle math needed.
func roundedPolygon(_ points: [NSPoint], corner: CGFloat) -> NSBezierPath {
    func tangent(_ from: NSPoint, _ toward: NSPoint) -> NSPoint {
        let dx = toward.x - from.x, dy = toward.y - from.y
        let len = max(1, hypot(dx, dy))
        let d = min(corner, len * 0.5)   // never overshoot halfway, so short edges don't invert
        return NSPoint(x: from.x + dx / len * d, y: from.y + dy / len * d)
    }
    let path = NSBezierPath()
    let n = points.count
    for i in 0..<n {
        let prev = points[(i - 1 + n) % n], cur = points[i], next = points[(i + 1) % n]
        let t1 = tangent(cur, prev), t2 = tangent(cur, next)
        if i == 0 { path.move(to: t1) } else { path.line(to: t1) }
        path.curve(to: t2, controlPoint1: cur, controlPoint2: cur)
    }
    path.close()
    return path
}

// the 10 points (5 outer, 5 inner, alternating) of a plain star — same formula `star` above uses,
// exposed separately so a caller can perturb individual points before building a path from them.
func starPoints(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ rot: CGFloat) -> [NSPoint] {
    (0..<10).map { i in
        let a = rot + CGFloat(i) * .pi / 5 + .pi / 2
        let rr = i % 2 == 0 ? r : r * 0.45
        return NSPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr)
    }
}

// a star like `star` above, but with every point (outer and inner) rounded off by `corner` —
// used for the star mascot's body, where sharp spikes read as too aggressive. The small
// decorative stars elsewhere (sparkle trail, wand) stay sharp via the plain `star`, unaffected.
func roundedStar(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ rot: CGFloat, corner: CGFloat) -> NSBezierPath {
    roundedPolygon(starPoints(cx, cy, r, rot), corner: corner)
}

// four-pointed twinkle
func sparkle(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ c: NSColor) {
    poly([NSPoint(x: x, y: y + s), NSPoint(x: x + s * 0.28, y: y), NSPoint(x: x, y: y - s), NSPoint(x: x - s * 0.28, y: y)], c)
    poly([NSPoint(x: x + s, y: y), NSPoint(x: x, y: y + s * 0.28), NSPoint(x: x - s, y: y), NSPoint(x: x, y: y - s * 0.28)], c)
}
