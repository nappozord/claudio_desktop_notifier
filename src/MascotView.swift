import Cocoa

// The view's own state and plumbing: window position/stacking, clicks, the phrase file, the
// 60fps tick. What's actually drawn lives in Bubble.swift and Mascot.swift
// (stored properties have to stay here either way — Swift extensions can't add new ones).
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
    // confetti: repeating bursts (not tied to itemAt — this one loops for as long as the prop is
    // a trophy/popper, not just once when it arrives)
    var confettiAt = Double.random(in: 1...3)
    // knock on the bubble (ask mood only): a quick double-tap gesture with the right arm, the
    // bubble jiggling in sync (read from here by Bubble.swift, same as phraseAt/swapped above)
    var knockAt = Double.random(in: 4...8)
    let knockDuration = 0.6
    // head scratch (ask mood only): the left arm (knock already uses the right one) rubs the
    // top of the head, with a small "?" popping up over it
    var scratchAt = Double.random(in: 3...7)
    let scratchDuration = 1.0
    // prop toss: the held item leaves the hand, spins in the air, and drops back in
    var tossAt = Double.random(in: 8...18)
    let tossDuration = 0.7
    // blink: a quick squash-and-release of the eyes at random intervals, so idle isn't dead still
    var blinkAt = Double.random(in: 1...3)
    let blinkDuration = 0.12
    // backflip: an extra-high hop with one full spin, every so often (done mood only)
    var backflipAt = Double.random(in: 10...20)
    let backflipDuration = 0.55
    // twirl: squashes sideways to a sliver and back out, like spinning around on the spot
    var twirlAt = Double.random(in: 5...12)
    let twirlDuration = 0.4
    // getting sleepy: mouse *movement* resets this (not mere proximity — a cursor resting nearby,
    // unmoving, must not count as "still looking" or it would never doze off). Once it's been a
    // while with no movement, eyes droop and motion slows, until it wakes with a startled jump.
    var lastActivityAt = 0.0
    var lastMousePos: NSPoint? = nil
    var prevSleepiness: CGFloat = 0
    var wokeAt = -10.0
    // holds the global key-press monitor main.swift installs, so ARC doesn't tear it down; see
    // noteActivity() below and the "Jump to session"-style note in the project skill
    var keyMonitor: Any? = nil

    // called from that key monitor: a keypress elsewhere counts as activity too, same as mouse
    // movement (checked directly in drawMascot). Only the fact that a key was pressed is used —
    // which key is never read or stored.
    func noteActivity() {
        lastActivityAt = Date().timeIntervalSince(start)
    }

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

    // stacking: banners from several sessions sit one under the other, oldest on top. Each banner's
    // place is the number of older Claudio windows on screen (by pid), so when one closes the ones
    // below it glide up. Checked a few times a second; the window list needs no permission.
    var slot = 0
    var slotY: CGFloat = 0        // current offset from the top slot, eased toward the slot's
    var slotCheckedAt = -1.0

    func updateSlot(_ t: Double, _ screen: NSRect) {
        guard t - slotCheckedAt >= 0.25 else { return }
        let first = slotCheckedAt < 0
        slotCheckedAt = t
        let me = getpid(), name = ProcessInfo.processInfo.processName
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        let older = Set(windows.compactMap { w -> pid_t? in
            guard w[kCGWindowOwnerName as String] as? String == name,
                  let pid = w[kCGWindowOwnerPID as String] as? pid_t, pid < me else { return nil }
            return pid
        })
        // as many as fit on the screen; beyond that the newest ones overlap in the last place
        let fit = max(1, Int((screen.height - 8) / (bounds.height + 8)))
        slot = min(older.count, fit - 1)
        if first { slotY = slotOffset }   // a new banner starts in its place instead of gliding there
    }
    var slotOffset: CGFloat { CGFloat(slot) * (bounds.height + 8) }

    func tick() {
        let t = Date().timeIntervalSince(start)
        // slide + fade: in from the right, out to the right
        let prog = min(smooth(t / slideTime), smooth((endAt - t) / slideTime))
        window?.alphaValue = CGFloat(prog)   // fade together with the slide
        let hidden = (1 - prog) * (bounds.width + 40)
        let screen = NSScreen.main!.visibleFrame
        updateSlot(t, screen)
        slotY += (slotOffset - slotY) * 0.15
        window?.setFrameOrigin(NSPoint(x: screen.maxX - bounds.width - 12 + hidden,
                                       y: screen.maxY - bounds.height - 8 - slotY))
        pollPhrase(t)
        if t >= endAt {
            if let f = phraseFile { try? FileManager.default.removeItem(atPath: f) }
            NSApp.terminate(nil)
        }
        needsDisplay = true
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
}
