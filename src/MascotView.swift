import Cocoa

final class MascotView: NSView {
    let start = Date()
    var endAt = lifetime

    // speech text: a canned line (or TEXT=) at once, maybe a task-specific one from phrase.sh later
    var phrase: String? = initialPhrase
    var phraseAt = 0.0
    var swapped = false
    // held object: picked at spawn, may be replaced by a task-related one from phrase.sh
    var item: String? = crowned ? nil : initialItem
    var itemAt = -10.0

    // bubble and its X, in design units (shared by drawing and the click check)
    let bubbleRect = NSRect(x: 158, y: 16, width: design.width - 158 - 12, height: 78)
    var closeRect: NSRect { NSRect(x: bubbleRect.maxX - 21, y: bubbleRect.maxY - 13, width: 26, height: 26) }

    // a click on the X only closes the banner; anywhere else it also jumps to the session
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let onClose = hypot(p.x / uiScale - closeRect.midX, p.y / uiScale - closeRect.midY) <= closeRect.width / 2 + 4
        if !onClose { jumpToSession() }
        dismiss()
    }

    // runs focus.sh (path in CLAUDIO_FOCUS, set by notify.sh), which reads the session details
    // from the environment. Not set when the app is started by hand: then a click only closes it.
    func jumpToSession() {
        guard let script = ProcessInfo.processInfo.environment["CLAUDIO_FOCUS"], !script.isEmpty else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = [script]
        try? p.run()
    }

    func dismiss() {
        let t = Date().timeIntervalSince(start)
        endAt = min(endAt, t + slideTime)
    }

    func pollPhrase(_ t: Double) {
        guard let f = phraseFile,
              let raw = try? String(contentsOfFile: f, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(atPath: f)
        // line 1 = caption, optional "item: <name>" line = task-related prop
        var lines = raw.components(separatedBy: "\n")
        if let i = lines.firstIndex(where: { $0.hasPrefix("item:") }) {
            let name = lines.remove(at: i).dropFirst(5).trimmingCharacters(in: .whitespaces)
            if !crowned, forced == nil, name != item, (isAsk ? askItems : doneItems).contains(name) {
                item = name
                itemAt = t
            }
        }
        let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text != phrase else { return }
        swapped = phrase != nil
        phrase = text
        phraseAt = t
    }

    func tick() {
        let t = Date().timeIntervalSince(start)
        // slide + fade: in from the right, out to the right
        let prog = min(smooth(t / slideTime), smooth((endAt - t) / slideTime))
        window?.alphaValue = CGFloat(prog)   // fade together with the slide
        let hidden = (1 - prog) * (bounds.width + 40)
        let screen = NSScreen.main!.visibleFrame
        window?.setFrameOrigin(NSPoint(x: screen.maxX - bounds.width - 12 + hidden,
                                       y: screen.maxY - bounds.height - 8))
        pollPhrase(t)
        if t >= endAt {
            if let f = phraseFile { try? FileManager.default.removeItem(atPath: f) }
            NSApp.terminate(nil)
        }
        needsDisplay = true
    }

    func drawBubble(_ t: Double, _ ctx: CGContext) {
        guard let phrase = phrase else { return }
        let k = min(1, (t - phraseAt) / 0.3)
        let pop = swapped ? 1 + 0.06 * sin(k * .pi)
                          : (k < 1 ? 1 + 0.12 * sin(k * .pi) - (1 - k) * (1 - k) : 1)
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
        str.draw(with: NSRect(x: bubble.minX + 14, y: bubble.midY - textH / 2, width: textW, height: textH),
                 options: [.usesLineFragmentOrigin, .usesFontLeading])
        ctx.restoreGState()
    }

    override func draw(_ dirtyRect: NSRect) {
        let t = Date().timeIntervalSince(start)
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.scaleBy(x: uiScale, y: uiScale)

        drawBubble(t, ctx)

        // mascot, drawn in its original 420-wide coordinates and scaled down into the left side
        ctx.saveGState()
        ctx.translateBy(x: 70, y: -8)
        ctx.scaleBy(x: 0.38, y: 0.38)
        ctx.translateBy(x: -210, y: 0)
        drawMascot(t, ctx)
        ctx.restoreGState()
    }

    func drawMascot(_ t: Double, _ ctx: CGContext) {
        let cx: CGFloat = 210

        // jump + shake
        let shout = CGFloat(0.5 + 0.5 * sin(t * 13))
        ctx.translateBy(x: CGFloat(sin(t * 40)) * (isAsk ? 5 : 2),
                        y: CGFloat(abs(sin(t * 7))) * (isAsk ? 22 : 30))

        // shout lines radiating from the face, pulsing with the shout
        ctx.saveGState()
        ctx.translateBy(x: cx, y: 190)
        for i in 0..<12 {
            let a = CGFloat(i) / 12 * 2 * .pi + CGFloat(t) * 0.3
            let r0: CGFloat = 130 + shout * 8, r1: CGFloat = r0 + 22 + shout * 18
            let line = NSBezierPath()
            line.lineWidth = 9; line.lineCapStyle = .round
            line.move(to: NSPoint(x: cos(a) * r0, y: sin(a) * r0 * 0.8))
            line.line(to: NSPoint(x: cos(a) * r1, y: sin(a) * r1 * 0.8))
            shade.withAlphaComponent(0.35 + 0.65 * shout).setStroke()
            line.stroke()
        }
        ctx.restoreGState()

        // legs
        for i in 0..<4 { block(cx - 82 + CGFloat(i) * 44, 40, 24, 50, orange) }
        // arms (wave up)
        let wave = CGFloat(sin(t * (isAsk ? 14 : 9))) * 14
        block(cx - 140, 165 + wave, 40, 36, orange)
        block(cx + 100, 165 - wave, 40, 36, orange)
        // body
        block(cx - 100, 85, 200, 150, orange, r: 8)
        block(cx - 100, 85, 200, 14, shade, r: 4)

        // eyes (nudge toward cursor)
        let mouse = NSEvent.mouseLocation
        let o = window!.frame.origin
        let dx = mouse.x - (o.x + 70 * uiScale), dy = mouse.y - (o.y + 75 * uiScale)
        let d = max(1, hypot(dx, dy)), reach = min(1, d / 250)
        let ox = dx / d * 8 * reach, oy = dy / d * 6 * reach
        for side in [-1.0, 1.0] {
            let ey: CGFloat = isAsk ? 190 : 196
            block(cx + CGFloat(side) * 44 - 11 + ox, ey + oy, 22, isAsk ? 46 : 38, ink, r: 3)
        }

        // open mouth: shouts without making a sound
        let mh = 10 + 40 * shout
        block(cx - 32, 150 - (mh - 10) * 0.5, 64, mh, mouthColor, r: 6)
        if mh > 28 { block(cx - 20, 150 - (mh - 10) * 0.5 + 4, 40, 8, .white, r: 2) }

        // a crowned mascot keeps its hands free
        if crowned { drawCrown(cx); return }
        guard let item = item else { return }
        // held object (pops in when swapped), then the right hand again on top so it looks gripped
        let hx = cx + 120, hy = 183 - wave
        let k = min(1, (t - itemAt) / 0.35)
        let pop = CGFloat(k < 1 ? 1 + 0.25 * sin(k * .pi) - (1 - k) * (1 - k) : 1)
        ctx.saveGState()
        ctx.translateBy(x: hx, y: hy)
        ctx.scaleBy(x: pop, y: pop)
        ctx.translateBy(x: -hx, y: -hy)
        drawItem(item, t, hx, hy, shout, ctx)
        ctx.restoreGState()
        block(cx + 100, 165 - wave, 40, 36, orange)
    }
}
