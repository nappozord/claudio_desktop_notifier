import Cocoa

// The mascot's body and its moves: the always-on jump/wave/mouth loop, plus the random one-off
// animations (blink, backflip, twirl, prop toss, getting sleepy) layered on top of it. Most are a
// pure function of `t` — their own `xAt` timestamp (declared in MascotView.swift) plus a fixed
// duration — so there's no separate timer or state machine; see the "Idle mascot animations"
// section of the project skill for the pattern and the timing of each one.
extension MascotView {
    func drawMascot(_ t: Double, _ ctx: CGContext) {
        let cx: CGFloat = 210

        // mouse position relative to the face, used for eye-tracking below
        let mouse = NSEvent.mouseLocation
        let o = window!.frame.origin
        let dx = mouse.x - (o.x + 70 * uiScale), dy = mouse.y - (o.y + 75 * uiScale)
        let d = max(1, hypot(dx, dy)), reach = min(1, d / 250)
        let ox = dx / d * 8 * reach, oy = dy / d * 6 * reach

        // getting sleepy: only actual mouse *movement* counts as "someone's there" — a cursor
        // that's merely resting nearby, unmoving, must not keep resetting the idle clock, or it
        // would never doze off. (Approaching the banner to look at it is itself movement, so this
        // still wakes it, same as before.) Once idle past dozeStart it starts dozing off, fully
        // asleep dozeSpan later (45s/15s normally; CLAUDIO_SLEEP_TEST shrinks both for previewing).
        // Waking (idle clock resets while it was mostly asleep) triggers a one-off startled jump,
        // timed the same pure-t way as blink.
        if let last = lastMousePos, hypot(mouse.x - last.x, mouse.y - last.y) > 2 { lastActivityAt = t }
        lastMousePos = mouse
        let idleFor = t - lastActivityAt
        // never while waiting for input — an ask banner needs the user, so it shouldn't doze off
        let sleepiness: CGFloat = isAsk ? 0 : CGFloat(min(1, max(0, (idleFor - dozeStart) / dozeSpan)))
        if prevSleepiness > 0.5 && sleepiness < 0.5 { wokeAt = t }
        prevSleepiness = sleepiness
        let energy = 1 - 0.7 * sleepiness
        let sinceWake = t - wokeAt
        let startled: CGFloat = (0...0.3).contains(sinceWake) ? CGFloat(sin(sinceWake / 0.3 * .pi)) : 0
        let drowsy = sleepiness > 0.5   // backflip/twirl/toss pause once it's properly asleep
        // body + arms + head slump down over the (still planted) legs as it dozes off
        let sink = sleepiness * 50

        // animT, not t, drives the continuous jump/wave/mouth loop below, so the whole thing can
        // be paced without touching any of the one-off animations' real-time scheduling above
        // and below (they all still compare against raw t)
        let animT = t * animSpeed

        // jump + shake (slower and smaller the sleepier it is, with a startled bounce on waking)
        let shout = CGFloat(0.5 + 0.5 * sin(animT * 13))
        ctx.translateBy(x: CGFloat(sin(animT * 40 * Double(energy))) * (isAsk ? 5 : 2) * energy,
                        y: CGFloat(abs(sin(animT * 7 * Double(energy)))) * (isAsk ? 22 : 30) * energy
                            + startled * 40)

        // backflip: an extra hop with one full spin around the character's own center, reschedules
        // itself once it ends (same pure-function-of-t pattern as blink). Done mood only, and not
        // while mostly asleep.
        let sinceFlip = t - backflipAt
        let inFlip = !isAsk && !drowsy && (0...backflipDuration).contains(sinceFlip)
        if inFlip {
            let p = CGFloat(sinceFlip / backflipDuration)
            let pivot = NSPoint(x: cx, y: 140)
            ctx.translateBy(x: 0, y: sin(p * .pi) * 70)
            ctx.translateBy(x: pivot.x, y: pivot.y)
            ctx.rotate(by: p * 2 * .pi)
            ctx.translateBy(x: -pivot.x, y: -pivot.y)
        }
        if sinceFlip > backflipDuration { backflipAt = t + Double.random(in: 18...35) }

        // twirl: squash to a thin sliver and back out, as if spinning around on the spot.
        // Skipped while a backflip plays or it's mostly asleep.
        let sinceTwirl = t - twirlAt
        if !inFlip && !drowsy && (0...twirlDuration).contains(sinceTwirl) {
            let p = CGFloat(sinceTwirl / twirlDuration)
            let sx = 1 - 0.85 * sin(p * .pi)
            ctx.translateBy(x: cx, y: 0)
            ctx.scaleBy(x: sx, y: 1)
            ctx.translateBy(x: -cx, y: 0)
        }
        if sinceTwirl > twirlDuration { twirlAt = t + Double.random(in: 15...28) }

        // shout lines radiating from the face, pulsing with the shout (fading out while sleepy).
        // Stay put (not sunk) — they read as "energy", which is exactly what's draining away.
        ctx.saveGState()
        ctx.translateBy(x: cx, y: 190)
        for i in 0..<12 {
            let a = CGFloat(i) / 12 * 2 * .pi + CGFloat(t) * 0.3
            let r0: CGFloat = 130 + shout * 8 * energy, r1: CGFloat = r0 + (22 + shout * 18) * energy
            let line = NSBezierPath()
            line.lineWidth = 9; line.lineCapStyle = .round
            line.move(to: NSPoint(x: cos(a) * r0, y: sin(a) * r0 * 0.8))
            line.line(to: NSPoint(x: cos(a) * r1, y: sin(a) * r1 * 0.8))
            shade.withAlphaComponent((0.35 + 0.65 * shout) * energy).setStroke()
            line.stroke()
        }
        ctx.restoreGState()

        // legs: only the two outer ones step, opposite phase and a smaller lift than the arms
        // (same swing as the arms, slower/smaller while sleepy). Drawn here, before the body sinks
        // down over them, so they stay planted while everything above slumps.
        let wave = CGFloat(sin(animT * (isAsk ? 14 : 9) * Double(energy))) * 14 * energy

        // knock on the bubble: two sharp taps (narrow pulses at kp≈0.2 and kp≈0.6) reaching the
        // right arm up and out toward the bubble's side, with the bubble jiggling in sync (see
        // Bubble.swift, which reads the same knockAt/knockDuration off this instance). Ask mood
        // only — a "hey, look here" gesture — and reschedules every 6-10s regardless of mood, the
        // same pattern as backflip/twirl, so it lines up correctly whenever the mood is ask.
        let sinceKnock = t - knockAt
        var knockLift: CGFloat = 0
        if isAsk && !drowsy && (0...knockDuration).contains(sinceKnock) {
            let kp = sinceKnock / knockDuration
            let tap1 = max(0, 1 - abs((kp - 0.2) / 0.12)), tap2 = max(0, 1 - abs((kp - 0.6) / 0.12))
            knockLift = CGFloat(max(tap1, tap2)) * 46
        }
        if sinceKnock > knockDuration { knockAt = t + Double.random(in: 6...10) }

        // head scratch: the left arm rises and wobbles side to side (a quick rubbing motion)
        // while a "?" fades in above the head, both following the same rise-hold-fall envelope.
        // Ask mood only, same reasoning as the knock.
        let sinceScratch = t - scratchAt
        var scratchLift: CGFloat = 0, scratchWobble: CGFloat = 0, scratchEnvelope: CGFloat = 0
        if isAsk && !drowsy && (0...scratchDuration).contains(sinceScratch) {
            let sp = sinceScratch / scratchDuration
            scratchEnvelope = CGFloat(min(min(sp, 1 - sp) / 0.25, 1))
            scratchLift = scratchEnvelope * 70
            scratchWobble = CGFloat(sin(sinceScratch * 30)) * scratchEnvelope * 10
        }
        if sinceScratch > scratchDuration { scratchAt = t + Double.random(in: 7...11) }

        for i in 0..<4 {
            let lift: CGFloat = i == 0 ? wave * 0.5 : (i == 3 ? -wave * 0.5 : 0)
            block(cx - 82 + CGFloat(i) * 44, 40 + lift, 24, 50, orange)
        }

        // body + arms + head sink down over the legs as sleepiness rises (drawn on top of them,
        // so sinking hides all but a sliver near the ground)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: -sink)
        // arms droop further than the body itself, going slack rather than staying at shoulder height
        let armDroop = sleepiness * 45

        // arms (wave up)
        block(cx - 140 + scratchWobble, 165 + wave - armDroop + scratchLift, 40, 36, orange)
        block(cx + 100 + knockLift * 0.4, 165 - wave - armDroop + knockLift, 40, 36, orange)
        // body
        block(cx - 100, 85, 200, 150, orange, r: 8)
        block(cx - 100, 85, 200, 14, shade, r: 4)

        // blink: squash to near-closed at mid-blink, open at both ends; reschedule once it's done
        let sinceBlink = t - blinkAt
        let blink: CGFloat = (0...blinkDuration).contains(sinceBlink)
            ? 1 - 0.92 * CGFloat(sin(sinceBlink / blinkDuration * .pi)) : 1
        if sinceBlink > blinkDuration { blinkAt = t + Double.random(in: 2...6) }
        // closed + widened while sleepy (a flat, wide bar reads as "shut"), and drops further
        // down within the head — the chin tucking toward the chest, on top of the body's own
        // sink. A brief wide-eyed snap open right after waking.
        let eyeOpen = (1 - 0.7 * sleepiness) * (1 + 0.3 * startled)
        let eyeWidth: CGFloat = 22 + 10 * sleepiness
        let headDroop = sleepiness * 45
        for side in [-1.0, 1.0] {
            let ey: CGFloat = (isAsk ? 190 : 196) - headDroop
            let eh = (isAsk ? 46 : 38) * blink * eyeOpen
            block(cx + CGFloat(side) * 44 - eyeWidth / 2 + ox * energy,
                  ey + oy * energy + ((isAsk ? 46 : 38) - eh) / 2, eyeWidth, eh, ink, r: 3)
        }
        drawAccessory(cx, headDroop)

        // open mouth: shouts without making a sound. While dozing off it first sags further down
        // the face (not shrinking or fading yet), and only once it's fully down does it fade out —
        // the snoozing bubble below takes over as the "asleep" sign from there.
        let mouthDrop = min(1, sleepiness / 0.3) * 40
        let mouthVisible = max(0, min(1, (0.45 - sleepiness) / 0.15))
        if mouthVisible > 0.01 {
            let mh = 10 + 40 * shout * energy
            block(cx - 32, 150 - headDroop - mouthDrop - (mh - 10) * 0.5, 64, mh,
                  mouthColor.withAlphaComponent(mouthVisible), r: 6)
            if mh > 28 {
                block(cx - 20, 150 - headDroop - mouthDrop - (mh - 10) * 0.5 + 4, 40, 8,
                      NSColor.white.withAlphaComponent(mouthVisible), r: 2)
            }
        }

        // snot bubble: one bubble inflating from the mouth, then popping, over and over —
        // the classic cartoon "fast asleep" sign, rather than a thought bubble with "Z" in it.
        // Only once the doze-off transition has fully finished (sleepiness pinned at 1), not
        // partway through it.
        if sleepiness >= 0.999 {
            let snorePeriod = 2.2
            let phase = (t / snorePeriod).truncatingRemainder(dividingBy: 1)
            let inflate = phase < 0.82 ? CGFloat(phase / 0.82) : 0   // holds at 0 right after each pop
            let size = (6 + inflate * 68) * sleepiness   // double the previous size
            if size > 1.5 {
                let anchor = NSPoint(x: cx + 6, y: 150 - headDroop + 10)
                let bubble = NSRect(x: anchor.x - size / 2, y: anchor.y - size * 0.15,
                                     width: size, height: size * 0.95)
                ctx.saveGState()
                // a radial shade (lighter toward the upper-left, as if lit from there) instead of
                // a flat fill, so it reads as a round, glossy bubble rather than a disc
                let bubblePath = NSBezierPath(ovalIn: bubble)
                NSGradient(colors: [NSColor(white: 1, alpha: 0.75 * sleepiness),
                                    NSColor(white: 0.8, alpha: 0.4 * sleepiness)])?
                    .draw(in: bubblePath, relativeCenterPosition: NSPoint(x: -0.35, y: 0.35))
                NSColor(white: 0.5, alpha: 0.5 * sleepiness).setStroke()
                bubblePath.stroke()
                // a little shine so it reads as a wet bubble, not a flat circle
                let shine = NSRect(x: bubble.minX + size * 0.18, y: bubble.maxY - size * 0.4,
                                    width: size * 0.22, height: size * 0.18)
                NSColor(white: 1, alpha: 0.8 * sleepiness).setFill()
                NSBezierPath(ovalIn: shine).fill()
                ctx.restoreGState()
            }
        }

        // "Zzz", overlapping the forehead, in the same light gray as the speech bubble. Each
        // letter sways gently side to side (a dreamy drift, not a rise) while fading in and out on
        // its own loop. Eyes sit around local y=151 once fully drooped and the body's top edge is
        // at 235, so ~205 sits just above them, square on the forehead. Font is sized up so the
        // letters still read clearly once scaled down to the banner's actual on-screen size.
        if sleepiness >= 0.999 {
            for i in 0..<3 {
                let phase = (t / 1.6 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let fp = CGFloat(phase)
                let alpha = CGFloat(sin(Double(fp) * .pi))
                guard alpha > 0.02 else { continue }
                let sway = CGFloat(sin(t * 1.3 + Double(i) * 2.1)) * 14
                NSAttributedString(string: "Z", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 34 + fp * 20),
                    .foregroundColor: bubbleColor.withAlphaComponent(alpha)
                ]).draw(at: NSPoint(x: cx - 10 + CGFloat(i) * 14 + sway, y: 218 + fp * 10))
            }
        }

        // a crowned mascot keeps its hands free (crown sinks and droops with the rest of the head)
        if crowned { drawCrown(cx); ctx.restoreGState(); return }
        guard let item = item else { ctx.restoreGState(); return }
        ctx.restoreGState()   // back to the un-sunk frame: the item gets its own position below

        // held object (pops in when swapped); as it dozes off the item slips from the (sinking)
        // hand and settles on the ground, tipping over as it lands
        // where the hand currently is (sink and the knock gesture both included, so a held prop
        // doesn't look detached from the hand while it's knocking)
        let hx = cx + 120 + knockLift * 0.4, hy = 183 - wave - sink + knockLift
        let groundX: CGFloat = cx + 40, groundY: CGFloat = 46
        let ix = hx + (groundX - hx) * sleepiness, iy = hy + (groundY - hy) * sleepiness
        let itemRotation = sleepiness * (-5 * .pi / 12)   // tipped over, tilted up a bit so it clears the ground
        let k = min(1, (t - itemAt) / 0.35)
        let pop = CGFloat(k < 1 ? 1 + 0.25 * sin(k * .pi) - (1 - k) * (1 - k) : 1)

        // prop toss: skipped during a backflip, while mostly asleep, and until the item has
        // finished popping in (k >= 1), so a just-swapped item never launches mid-pop
        let sinceToss = t - tossAt
        let inToss = !inFlip && !drowsy && k >= 1 && (0...tossDuration).contains(sinceToss)
        let tossP = CGFloat(inToss ? sinceToss / tossDuration : 0)
        let tossLift: CGFloat = inToss ? sin(tossP * .pi) * 90 : 0
        let tossSpin: CGFloat = inToss ? tossP * 4 * .pi : 0
        if sinceToss > tossDuration { tossAt = t + Double.random(in: 14...26) }

        ctx.saveGState()
        ctx.translateBy(x: ix, y: iy + tossLift)
        ctx.rotate(by: tossSpin + itemRotation)
        ctx.scaleBy(x: pop, y: pop)
        ctx.translateBy(x: -hx, y: -hy)
        drawItem(item, t, hx, hy, shout, ctx)
        ctx.restoreGState()

        // confetti: repeating bursts from the prop itself for as long as it's a trophy or a
        // popper — Haiku only picks those for a real success, so this reuses that pipeline
        // rather than adding a new one. Each burst's piece paths are a pure function of
        // (t - confettiAt), which reschedules every ~5s the same way backflip/twirl do; the
        // deterministic "golden angle" per index spreads 14 pieces evenly without actually
        // storing a random launch direction for each.
        let sinceConfetti = t - confettiAt
        if (item == "trophy" || item == "popper") && !drowsy && (0...1.1).contains(sinceConfetti) {
            let p = CGFloat(sinceConfetti / 1.1)
            for idx in 0..<14 {
                let angle = Double(idx) * 2.399963
                let speed: CGFloat = 100 + CGFloat(idx % 5) * 26
                let vx = CGFloat(cos(angle)) * speed, vy = CGFloat(sin(angle)) * speed + 120
                let px = hx + vx * p, py = hy + vy * p - 300 * p * p
                let alpha = 1 - p
                ctx.saveGState()
                ctx.translateBy(x: px, y: py)
                ctx.rotate(by: CGFloat(Double(idx) * 0.7 + sinceConfetti * 6))
                confettiColors[idx % confettiColors.count].withAlphaComponent(alpha).setFill()
                NSBezierPath(rect: NSRect(x: -9, y: -4.5, width: 18, height: 9)).fill()
                ctx.restoreGState()
            }
        }
        if sinceConfetti > 1.1 { confettiAt = t + Double.random(in: 2...3) }

        // rain cloud: a small gray cloud over the head with a couple of drops falling in a loop,
        // for as long as the prop is the fire extinguisher — Haiku only picks that one when
        // something actually failed. Fixed above the head regardless of sink/droop: a persistent
        // mood, not tied to the sleepy animation.
        if item == "extinguisher" {
            ctx.saveGState()
            let cloudX = cx + 15, cloudY: CGFloat = 270
            NSColor(white: 0.55, alpha: 0.9).setFill()
            for (px, py, r): (CGFloat, CGFloat, CGFloat) in [(-34, 0, 32), (0, 12, 40), (34, 0, 32), (-12, -12, 28), (20, -12, 28)] {
                NSBezierPath(ovalIn: NSRect(x: cloudX + px - r / 2, y: cloudY + py - r / 2, width: r, height: r)).fill()
            }
            for i in 0..<3 {
                let phase = (t / 0.9 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1)
                let fp = CGFloat(phase)
                let dropX = cloudX - 20 + CGFloat(i) * 20, dropY = cloudY - 26 - fp * 55
                NSColor(calibratedRed: 0.35, green: 0.55, blue: 0.85, alpha: (1 - fp) * 0.8).setFill()
                NSBezierPath(ovalIn: NSRect(x: dropX - 4, y: dropY - 8, width: 8, height: 16)).fill()
            }
            ctx.restoreGState()
        }

        // right hand, redrawn on top so a still-held item looks gripped (an arm that's dropped
        // its item just rests at the same spot — no special-casing needed)
        // (matches armDroop above, and adds the same knockLift as the arm's other draw)
        block(cx + 100 + knockLift * 0.4, 165 - wave - sink - sleepiness * 45 + knockLift, 40, 36, orange)
    }
}
