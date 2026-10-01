import Cocoa

// The speech bubble: text, tail, and the close circle. Kept separate from the mascot's own
// drawing (Mascot.swift) since the two scale independently — the bubble swells with
// the mouth, the mascot jumps, blinks and occasionally backflips or twirls.
extension MascotView {
    func drawBubble(_ t: Double, _ ctx: CGContext) {
        guard let phrase = phrase else { return }
        let k = min(1, (t - phraseAt) / 0.3)
        let appearPop = swapped ? 1 + 0.06 * sin(k * .pi)
                                : (k < 1 ? 1 + 0.12 * sin(k * .pi) - (1 - k) * (1 - k) : 1)
        // a small continuous swell in time with the mouth (same formula as drawMascot's `shout`,
        // animT included — otherwise this would drift out of sync with the now-paced mouth), as
        // if the bubble breathes with what the mascot is shouting
        let shout = CGFloat(0.5 + 0.5 * sin(t * animSpeed * 13))
        let pop = appearPop * (1 + 0.025 * shout)
        // jiggle when the mascot knocks on the bubble (see knockAt/knockLift in Mascot.swift —
        // same timestamp, recomputed here rather than passed in, same as `shout` above). A
        // back-and-forth wobble, not the arm's one-way lift, scaled by the same two tap pulses.
        let sinceKnock = t - knockAt
        var jiggle: CGFloat = 0
        if isAsk && (0...knockDuration).contains(sinceKnock) {
            let kp = sinceKnock / knockDuration
            let tap1 = max(0, 1 - abs((kp - 0.2) / 0.12)), tap2 = max(0, 1 - abs((kp - 0.6) / 0.12))
            jiggle = CGFloat(sin(sinceKnock * 45)) * CGFloat(max(tap1, tap2)) * 0.07
        }
        // fixed size: from the mascot's feet up to a bit above the top of its head
        let bubble = bubbleRect
        let textW = bubble.width - 28
        let para = NSMutableParagraphStyle(); para.alignment = .left
        // largest font size that fits the bubble
        var str = NSAttributedString()
        var textH: CGFloat = 0
        for size: CGFloat in [18, 16, 14, 13, 12, 11] {
            str = NSAttributedString(string: phrase, attributes: [
                .font: NSFont.systemFont(ofSize: size, weight: .regular),
                .foregroundColor: NSColor.black,
                .paragraphStyle: para
            ])
            textH = ceil(str.boundingRect(with: NSSize(width: textW, height: 400),
                                          options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
            if textH <= bubble.height - 14 { break }
        }

        ctx.saveGState()
        ctx.translateBy(x: bubble.minX, y: bubble.midY)
        ctx.rotate(by: jiggle)
        ctx.scaleBy(x: pop, y: pop)
        ctx.translateBy(x: -bubble.minX, y: -bubble.midY)
        bubbleColor.setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 18, yRadius: 18).fill()
        // little tail near the top-left corner, pointing at the mascot
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: bubble.minX + 2, y: bubble.maxY - 18))
        tail.line(to: NSPoint(x: bubble.minX + 2, y: bubble.maxY - 38))
        tail.line(to: NSPoint(x: bubble.minX - 13, y: bubble.maxY - 28))
        tail.close()
        tail.fill()
        // close button on the top-right corner (see mouseDown)
        let close = closeRect
        NSColor(white: 0.8, alpha: 1).setFill()
        NSBezierPath(ovalIn: close).fill()
        let cross = NSBezierPath()
        cross.lineWidth = 2; cross.lineCapStyle = .round
        cross.move(to: NSPoint(x: close.midX - 5, y: close.midY - 5))
        cross.line(to: NSPoint(x: close.midX + 5, y: close.midY + 5))
        cross.move(to: NSPoint(x: close.midX - 5, y: close.midY + 5))
        cross.line(to: NSPoint(x: close.midX + 5, y: close.midY - 5))
        NSColor(white: 0.3, alpha: 1).setStroke()
        cross.stroke()
        ctx.restoreGState()
        // text is drawn after restoring the scale, so the bubble swells but the words hold still
        str.draw(with: NSRect(x: bubble.minX + 14, y: bubble.midY - textH / 2, width: textW, height: textH),
                 options: [.usesLineFragmentOrigin, .usesFontLeading])
    }
}
