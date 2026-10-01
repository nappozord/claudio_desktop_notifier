import Cocoa

// Objects the mascot holds, and how one is picked.

extension MascotView {
    func drawCrown(_ cx: CGFloat) {
        poly([NSPoint(x: cx - 46, y: 235), NSPoint(x: cx + 46, y: 235), NSPoint(x: cx + 46, y: 292),
              NSPoint(x: cx + 23, y: 262), NSPoint(x: cx, y: 298), NSPoint(x: cx - 23, y: 262),
              NSPoint(x: cx - 46, y: 292)], gold)
        block(cx - 46, 232, 92, 14, goldDark, r: 3)
        disc(cx - 26, 252, 12, 12, NSColor(calibratedRed: 0.2, green: 0.45, blue: 0.9, alpha: 1))
        disc(cx, 254, 14, 14, NSColor(calibratedRed: 0.9, green: 0.15, blue: 0.25, alpha: 1))
        disc(cx + 26, 252, 12, 12, NSColor(calibratedRed: 0.2, green: 0.7, blue: 0.35, alpha: 1))
    }

    // hx, hy = centre of the right hand, in mascot coordinates
    func drawItem(_ item: String, _ t: Double, _ hx: CGFloat, _ hy: CGFloat, _ shout: CGFloat, _ ctx: CGContext) {
        switch item {
        case "icecream":
            poly([NSPoint(x: hx - 24, y: hy + 56), NSPoint(x: hx + 24, y: hy + 56), NSPoint(x: hx, y: hy - 8)], cone)
            let waffle = NSBezierPath(); waffle.lineWidth = 3
            waffle.move(to: NSPoint(x: hx - 14, y: hy + 54)); waffle.line(to: NSPoint(x: hx + 8, y: hy + 10))
            waffle.move(to: NSPoint(x: hx + 14, y: hy + 54)); waffle.line(to: NSPoint(x: hx - 8, y: hy + 10))
            coneDark.setStroke(); waffle.stroke()
            disc(hx, hy + 78, 66, 56, pink)
            let drip = CGFloat((t * 10).truncatingRemainder(dividingBy: 26))
            disc(hx + 20, hy + 56 - drip, 10, 14, pink)
            disc(hx + 6, hy + 112, 18, 18, cherry)

        case "wand":
            let stick = NSBezierPath(); stick.lineWidth = 10; stick.lineCapStyle = .round
            stick.move(to: NSPoint(x: hx - 4, y: hy - 10)); stick.line(to: NSPoint(x: hx + 14, y: hy + 92))
            ink.setStroke(); stick.stroke()
            let sx = hx + 16, sy = hy + 108
            for i in 0..<6 {
                let ph = (t * 0.8 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
                let a = Double(i) * 2.4 + 1
                let d = 30 + ph * 45
                sparkle(sx + CGFloat(cos(a) * d), sy + CGFloat(sin(a) * d), CGFloat(12 * (1 - ph) + 4),
                        starYellow.withAlphaComponent(CGFloat(1 - ph)))
            }
            starYellow.setFill(); star(sx, sy, 28, CGFloat(t * 1.5)).fill()

        case "balloon":
            let sway = CGFloat(sin(t * 2.2)) * 12
            let string = NSBezierPath(); string.lineWidth = 3
            string.move(to: NSPoint(x: hx, y: hy + 10))
            string.curve(to: NSPoint(x: hx + sway, y: hy + 92),
                         controlPoint1: NSPoint(x: hx - 12, y: hy + 40),
                         controlPoint2: NSPoint(x: hx + sway + 12, y: hy + 70))
            ink.setStroke(); string.stroke()
            poly([NSPoint(x: hx + sway - 7, y: hy + 88), NSPoint(x: hx + sway + 7, y: hy + 88),
                  NSPoint(x: hx + sway, y: hy + 97)], balloonRed)
            disc(hx + sway, hy + 128, 62, 74, balloonRed)
            disc(hx + sway - 14, hy + 144, 12, 20, NSColor.white.withAlphaComponent(0.6))

        case "trophy":
            block(hx - 7, hy + 4, 14, 32, goldDark)
            block(hx - 32, hy + 34, 64, 54, gold, r: 22)
            block(hx - 32, hy + 64, 64, 24, gold)
            block(hx - 36, hy + 84, 72, 9, goldDark, r: 3)
            for side in [-1.0, 1.0] {
                let h = NSBezierPath(ovalIn: NSRect(x: hx + CGFloat(side) * 34 - 12, y: hy + 50, width: 24, height: 28))
                h.lineWidth = 6; gold.setStroke(); h.stroke()
            }
            goldDark.setFill(); star(hx, hy + 62, 11, 0).fill()
            let glint = max(0, 1 - t.truncatingRemainder(dividingBy: 2.5) / 0.5)
            let g = NSBezierPath(); g.lineWidth = 6; g.lineCapStyle = .round
            g.move(to: NSPoint(x: hx - 18, y: hy + 48)); g.line(to: NSPoint(x: hx - 8, y: hy + 78))
            NSColor.white.withAlphaComponent(CGFloat(glint)).setStroke(); g.stroke()

        case "megaphone":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy + 12)
            ctx.rotate(by: 0.35)
            block(-6, -16, 12, 22, ink, r: 3)
            poly([NSPoint(x: -4, y: 2), NSPoint(x: -4, y: 24), NSPoint(x: 62, y: 46), NSPoint(x: 62, y: -20)], balloonRed)
            disc(62, 13, 14, 70, .white)
            for i in 1...2 {
                let r = CGFloat(i) * 16 + shout * 6
                let arc = NSBezierPath()
                arc.appendArc(withCenter: NSPoint(x: 66, y: 13), radius: 20 + r, startAngle: -35, endAngle: 35)
                arc.lineWidth = 6; arc.lineCapStyle = .round
                balloonRed.withAlphaComponent(shout * (1 - CGFloat(i) * 0.3)).setStroke(); arc.stroke()
            }
            ctx.restoreGState()

        case "bell":
            let swing = CGFloat(sin(t * 12)) * 0.35
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: swing)
            block(-7, -6, 14, 38, wood, r: 4)
            disc(CGFloat(sin(t * 12 + 1)) * 8, 26, 16, 16, goldDark)
            block(-32, 40, 64, 38, gold)
            disc(0, 78, 64, 60, gold)
            block(-40, 32, 80, 14, goldDark, r: 6)
            disc(0, 112, 14, 14, goldDark)
            ctx.restoreGState()
            let ring = NSBezierPath(); ring.lineWidth = 5; ring.lineCapStyle = .round
            for side in [-1.0, 1.0] {
                let x = hx + CGFloat(side) * 50
                ring.move(to: NSPoint(x: x, y: hy + 60)); ring.line(to: NSPoint(x: x + CGFloat(side) * 12, y: hy + 70))
                ring.move(to: NSPoint(x: x, y: hy + 80)); ring.line(to: NSPoint(x: x + CGFloat(side) * 14, y: hy + 84))
            }
            goldDark.withAlphaComponent(abs(swing) / 0.35).setStroke(); ring.stroke()

        case "popper":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: -0.5)
            poly([NSPoint(x: -6, y: -4), NSPoint(x: 6, y: -4), NSPoint(x: 26, y: 70), NSPoint(x: -26, y: 70)], popperPurple)
            block(-14, 20, 28, 9, starYellow)
            block(-20, 44, 40, 9, starYellow)
            ctx.restoreGState()
            // confetti burst out of the mouth every 4s
            let ph = t.truncatingRemainder(dividingBy: 4) / 1.4
            if ph < 1 {
                let mx = hx + 34, my = hy + 61
                let colors = [cherry, starYellow, pink, skyBlue, leafGreen]
                for i in 0..<14 {
                    let a = 1.07 + (Double(i) / 13 - 0.5) * 1.6
                    let v = 60 + Double(i % 4) * 18
                    let x = mx + CGFloat(cos(a) * v * ph)
                    let y = my + CGFloat(sin(a) * v * ph - 50 * ph * ph)
                    colors[i % colors.count].withAlphaComponent(CGFloat(1 - ph)).setFill()
                    NSBezierPath(rect: NSRect(x: x - 4, y: y - 3, width: 8, height: 6)).fill()
                }
            }

        case "flag":
            let pole = NSBezierPath(); pole.lineWidth = 7; pole.lineCapStyle = .round
            pole.move(to: NSPoint(x: hx, y: hy - 12)); pole.line(to: NSPoint(x: hx, y: hy + 124))
            ink.setStroke(); pole.stroke()
            let top = hy + 122, fh: CGFloat = 44
            let flag = NSBezierPath()
            flag.move(to: NSPoint(x: hx, y: top))
            for i in 1...8 {
                let x = CGFloat(i) * 9
                flag.line(to: NSPoint(x: hx + x, y: top + CGFloat(sin(t * 7 - Double(i) * 0.7)) * x * 0.12))
            }
            for i in stride(from: 8, through: 0, by: -1) {
                let x = CGFloat(i) * 9
                flag.line(to: NSPoint(x: hx + x, y: top - fh + CGFloat(sin(t * 7 - Double(i) * 0.7)) * x * 0.12))
            }
            flag.close()
            skyBlue.setFill(); flag.fill()
            disc(hx, hy + 128, 12, 12, gold)

        case "coffee":
            block(hx - 26, hy + 2, 46, 52, .white, r: 8)
            let handle = NSBezierPath(ovalIn: NSRect(x: hx + 12, y: hy + 14, width: 24, height: 26))
            handle.lineWidth = 7; NSColor.white.setStroke(); handle.stroke()
            block(hx - 26, hy + 22, 46, 9, balloonRed)
            disc(hx - 3, hy + 52, 40, 10, coffeeBrown)
            for i in 0..<3 {
                let ph = (t * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let x0 = hx - 14 + CGFloat(i) * 11, y0 = hy + 62 + CGFloat(ph) * 30
                let s = NSBezierPath(); s.lineWidth = 5; s.lineCapStyle = .round
                s.move(to: NSPoint(x: x0, y: y0))
                s.curve(to: NSPoint(x: x0, y: y0 + 26), controlPoint1: NSPoint(x: x0 + 8, y: y0 + 8),
                        controlPoint2: NSPoint(x: x0 - 8, y: y0 + 18))
                NSColor(white: 0.75, alpha: CGFloat(1 - ph) * 0.8).setStroke(); s.stroke()
            }

        case "pizza":
            // held by the crust, tip pointing up
            poly([NSPoint(x: hx - 34, y: hy + 8), NSPoint(x: hx + 34, y: hy + 8), NSPoint(x: hx, y: hy + 104)], starYellow)
            block(hx - 38, hy, 76, 15, cone, r: 7)
            disc(hx - 12, hy + 32, 16, 16, cherry)
            disc(hx + 12, hy + 28, 14, 14, cherry)
            disc(hx, hy + 60, 12, 12, cherry)
            let drip = CGFloat(abs(sin(t * 1.5))) * 16
            block(hx + 18, hy + 40 - drip, 7, 10 + drip, starYellow, r: 3)

        case "donut":
            let ring = NSBezierPath(ovalIn: NSRect(x: hx - 30, y: hy + 14, width: 60, height: 60))
            ring.lineWidth = 24; cone.setStroke(); ring.stroke()
            ring.lineWidth = 17; pink.setStroke(); ring.stroke()
            let colors = [starYellow, NSColor.white, skyBlue]
            for i in 0..<9 {
                let a = Double(i) * 0.7 + 0.3
                let x = hx + CGFloat(cos(a)) * 30, y = hy + 44 + CGFloat(sin(a)) * 30
                let sp = NSBezierPath(); sp.lineWidth = 3.5; sp.lineCapStyle = .round
                sp.move(to: NSPoint(x: x - 3, y: y - 2)); sp.line(to: NSPoint(x: x + 3, y: y + 2))
                colors[i % 3].setStroke(); sp.stroke()
            }

        case "sword":
            block(hx - 6, hy - 14, 12, 36, wood, r: 3)
            disc(hx, hy - 16, 14, 14, goldDark)
            block(hx - 28, hy + 18, 56, 11, goldDark, r: 4)
            poly([NSPoint(x: hx - 9, y: hy + 29), NSPoint(x: hx + 9, y: hy + 29), NSPoint(x: hx + 9, y: hy + 118),
                  NSPoint(x: hx, y: hy + 136), NSPoint(x: hx - 9, y: hy + 118)], NSColor(white: 0.85, alpha: 1))
            block(hx - 1.5, hy + 34, 3, 84, NSColor(white: 0.65, alpha: 1))
            let glint = max(0, 1 - t.truncatingRemainder(dividingBy: 3) / 0.6)
            sparkle(hx, hy + 136, CGFloat(16 * glint) + 0.1, NSColor.white.withAlphaComponent(CGFloat(glint)))

        case "potion":
            let glass = NSColor(white: 0.92, alpha: 0.9)
            block(hx - 9, hy + 70, 18, 28, glass, r: 3)
            block(hx - 11, hy + 94, 22, 13, wood, r: 3)
            disc(hx, hy + 48, 60, 60, glass)
            disc(hx, hy + 45, 52, 50, potionPurple)
            disc(hx - 12, hy + 58, 10, 14, NSColor.white.withAlphaComponent(0.6))
            for i in 0..<4 {
                let ph = (t * 0.7 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
                let x = hx + CGFloat(sin(Double(i) * 2.1 + t * 3)) * 5
                let s = CGFloat(6 + i * 2)
                disc(x, hy + 40 + CGFloat(ph) * 90, s, s, potionPurple.withAlphaComponent(CGFloat(1 - ph)))
            }

        case "umbrella":
            let shaft = NSBezierPath(); shaft.lineWidth = 6
            shaft.move(to: NSPoint(x: hx, y: hy - 12)); shaft.line(to: NSPoint(x: hx, y: hy + 92))
            ink.setStroke(); shaft.stroke()
            // canopy: alternating wedges that rotate, clipped to the upper half
            let c = NSPoint(x: hx, y: hy + 90)
            let off = (t * 90).truncatingRemainder(dividingBy: 90)
            for i in -2..<5 {
                let s = max(0, Double(i) * 45 + off), e = min(180, Double(i) * 45 + off + 45)
                guard e > s else { continue }
                let w = NSBezierPath()
                w.move(to: c)
                w.appendArc(withCenter: c, radius: 62, startAngle: CGFloat(s), endAngle: CGFloat(e))
                w.close()
                ((i % 2 + 2) % 2 == 0 ? cherry : NSColor.white).setFill(); w.fill()
            }
            disc(hx, hy + 154, 8, 10, ink)

        case "fish":
            let flop = t.truncatingRemainder(dividingBy: 2.6) < 0.5 ? sin(t * 30) * 0.35 : sin(t * 2) * 0.08
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy + 6)
            ctx.rotate(by: CGFloat(flop))
            poly([NSPoint(x: -18, y: -4), NSPoint(x: 18, y: -4), NSPoint(x: 0, y: 22)], fishBlue)
            disc(0, 62, 40, 84, fishBlue)
            poly([NSPoint(x: -20, y: 62), NSPoint(x: -34, y: 50), NSPoint(x: -20, y: 46)], fishDark)
            block(-14, 46, 28, 4, fishDark, r: 2)
            block(-17, 64, 34, 4, fishDark, r: 2)
            disc(8, 88, 14, 14, .white)
            disc(10, 88, 7, 7, ink)
            disc(2, 103, 10, 6, fishDark)
            ctx.restoreGState()

        case "wrench":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: CGFloat(-0.3 + sin(t * 8) * 0.25))
            block(-8, -12, 16, 90, steel, r: 6)
            let head = NSBezierPath()
            head.appendArc(withCenter: NSPoint(x: 0, y: 92), radius: 22, startAngle: 130, endAngle: 410)
            head.lineWidth = 16; steel.setStroke(); head.stroke()
            ctx.restoreGState()

        case "extinguisher":
            block(hx - 20, hy - 6, 40, 92, balloonRed, r: 14)
            block(hx - 20, hy + 34, 40, 18, .white)
            block(hx - 6, hy + 86, 12, 14, ink, r: 2)
            let hose = NSBezierPath(); hose.lineWidth = 6; hose.lineCapStyle = .round
            hose.move(to: NSPoint(x: hx, y: hy + 98))
            hose.curve(to: NSPoint(x: hx + 40, y: hy + 104), controlPoint1: NSPoint(x: hx + 10, y: hy + 118),
                       controlPoint2: NSPoint(x: hx + 30, y: hy + 118))
            ink.setStroke(); hose.stroke()
            for i in 0..<5 {
                let ph = (t * 1.2 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                let s = CGFloat(10 + ph * 20)
                disc(hx + 46 + CGFloat(ph) * 34, hy + 102 + CGFloat(sin(Double(i) * 1.7) * 10 * ph), s, s,
                     NSColor(white: 0.97, alpha: CGFloat(0.9 * (1 - ph))))
            }

        case "flashlight":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: CGFloat(sin(t * 2.5)) * 0.35 + 0.5)
            poly([NSPoint(x: 58, y: 8), NSPoint(x: 112, y: 36), NSPoint(x: 112, y: -20)], starYellow.withAlphaComponent(0.35))
            block(-10, -6, 56, 28, NSColor(white: 0.25, alpha: 1), r: 6)
            block(40, -10, 20, 36, NSColor(white: 0.45, alpha: 1), r: 4)
            disc(60, 8, 8, 30, starYellow)
            ctx.restoreGState()

        case "sign":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: CGFloat(sin(t * 6)) * 0.12)
            block(-5, -14, 10, 96, wood, r: 3)
            let board = NSBezierPath(roundedRect: NSRect(x: -40, y: 70, width: 80, height: 62), xRadius: 6, yRadius: 6)
            NSColor.white.setFill(); board.fill()
            board.lineWidth = 4; wood.setStroke(); board.stroke()
            let q = NSAttributedString(string: "?", attributes: [
                .font: NSFont.systemFont(ofSize: 50, weight: .black), .foregroundColor: balloonRed])
            let qs = q.size()
            q.draw(at: NSPoint(x: -qs.width / 2, y: 101 - qs.height / 2))
            ctx.restoreGState()

        case "pencil":
            ctx.saveGState()
            ctx.translateBy(x: hx, y: hy)
            ctx.rotate(by: -0.4 + CGFloat(sin(t * 9)) * 0.2)
            block(-9, -16, 18, 14, pink, r: 3)
            block(-9, -4, 18, 8, NSColor(white: 0.75, alpha: 1))
            block(-9, 4, 18, 84, starYellow)
            block(-3, 4, 6, 84, goldDark.withAlphaComponent(0.5))
            poly([NSPoint(x: -9, y: 88), NSPoint(x: 9, y: 88), NSPoint(x: 0, y: 112)], cone)
            poly([NSPoint(x: -3.5, y: 104), NSPoint(x: 3.5, y: 104), NSPoint(x: 0, y: 112)], ink)
            ctx.restoreGState()

        case "pumpkin":
            let px = hx, py = hy + 44
            disc(px - 20, py, 42, 60, pumpkinDark)
            disc(px + 20, py, 42, 60, pumpkinDark)
            disc(px, py, 46, 64, pumpkinOrange)
            block(px - 4, py + 28, 9, 16, leafGreen, r: 3)
            let glow = NSColor(calibratedRed: 1, green: 0.88, blue: 0.3, alpha: CGFloat(0.75 + 0.25 * sin(t * 15)))
            poly([NSPoint(x: px - 20, y: py + 4), NSPoint(x: px - 6, y: py + 4), NSPoint(x: px - 13, y: py + 16)], glow)
            poly([NSPoint(x: px + 6, y: py + 4), NSPoint(x: px + 20, y: py + 4), NSPoint(x: px + 13, y: py + 16)], glow)
            poly([NSPoint(x: px - 18, y: py - 8), NSPoint(x: px + 18, y: py - 8), NSPoint(x: px + 12, y: py - 18),
                  NSPoint(x: px + 5, y: py - 12), NSPoint(x: px - 1, y: py - 19), NSPoint(x: px - 7, y: py - 12),
                  NSPoint(x: px - 13, y: py - 18)], glow)

        case "tree":
            block(hx - 6, hy - 10, 12, 30, wood)
            poly([NSPoint(x: hx - 40, y: hy + 18), NSPoint(x: hx + 40, y: hy + 18), NSPoint(x: hx, y: hy + 66)], treeGreen)
            poly([NSPoint(x: hx - 32, y: hy + 48), NSPoint(x: hx + 32, y: hy + 48), NSPoint(x: hx, y: hy + 92)], treeGreen)
            poly([NSPoint(x: hx - 24, y: hy + 76), NSPoint(x: hx + 24, y: hy + 76), NSPoint(x: hx, y: hy + 112)], treeGreen)
            let baubles: [(CGFloat, CGFloat, NSColor)] = [(-18, 28, cherry), (16, 36, starYellow), (-8, 58, skyBlue), (12, 82, pink)]
            for (i, b) in baubles.enumerated() {
                disc(hx + b.0, hy + b.1, 11, 11, b.2.withAlphaComponent(CGFloat(0.55 + 0.45 * sin(t * 4 + Double(i)))))
            }
            starYellow.setFill(); star(hx, hy + 116, 13, 0).fill()

        case "flower":
            let stem = NSBezierPath(); stem.lineWidth = 6; stem.lineCapStyle = .round
            stem.move(to: NSPoint(x: hx, y: hy - 8))
            stem.curve(to: NSPoint(x: hx + 4, y: hy + 82), controlPoint1: NSPoint(x: hx - 10, y: hy + 30),
                       controlPoint2: NSPoint(x: hx + 12, y: hy + 55))
            leafGreen.setStroke(); stem.stroke()
            poly([NSPoint(x: hx + 2, y: hy + 36), NSPoint(x: hx + 28, y: hy + 52), NSPoint(x: hx + 6, y: hy + 48)], leafGreen)
            for i in 0..<6 {
                let a = Double(i) / 6 * 2 * .pi + t * 0.6
                disc(hx + 4 + CGFloat(cos(a)) * 18, hy + 98 + CGFloat(sin(a)) * 18, 24, 24, i % 2 == 0 ? pink : .white)
            }
            disc(hx + 4, hy + 98, 22, 22, starYellow)

        case "candle":
            block(hx - 26, hy - 4, 52, 10, NSColor(white: 0.75, alpha: 1), r: 5)
            block(hx - 12, hy + 4, 24, 60, NSColor(white: 0.97, alpha: 1), r: 3)
            block(hx - 1.5, hy + 64, 3, 8, ink)
            let sway = CGFloat(sin(t * 17) * 0.12 + sin(t * 7) * 0.08)
            disc(hx, hy + 82, 38, 48, starYellow.withAlphaComponent(0.25))
            let flame = NSBezierPath()
            flame.move(to: NSPoint(x: hx, y: hy + 70))
            flame.curve(to: NSPoint(x: hx + sway * 30, y: hy + 100), controlPoint1: NSPoint(x: hx + 12, y: hy + 74),
                        controlPoint2: NSPoint(x: hx + 8, y: hy + 88))
            flame.curve(to: NSPoint(x: hx, y: hy + 70), controlPoint1: NSPoint(x: hx - 8, y: hy + 88),
                        controlPoint2: NSPoint(x: hx - 12, y: hy + 74))
            flameOrange.setFill(); flame.fill()
            disc(hx, hy + 78, 8, 12, starYellow)

        default: break
        }
    }
}

let gold = NSColor(calibratedRed: 0.97, green: 0.76, blue: 0.18, alpha: 1)
let goldDark = NSColor(calibratedRed: 0.82, green: 0.58, blue: 0.1, alpha: 1)
let cone = NSColor(calibratedRed: 0.87, green: 0.67, blue: 0.38, alpha: 1)
let coneDark = NSColor(calibratedRed: 0.7, green: 0.5, blue: 0.25, alpha: 1)
let pink = NSColor(calibratedRed: 1, green: 0.62, blue: 0.72, alpha: 1)
let cherry = NSColor(calibratedRed: 0.85, green: 0.1, blue: 0.2, alpha: 1)
let balloonRed = NSColor(calibratedRed: 0.9, green: 0.25, blue: 0.3, alpha: 1)
let starYellow = NSColor(calibratedRed: 1, green: 0.85, blue: 0.2, alpha: 1)
let wood = NSColor(calibratedRed: 0.45, green: 0.28, blue: 0.15, alpha: 1)

let popperPurple = NSColor(calibratedRed: 0.55, green: 0.3, blue: 0.85, alpha: 1)
let skyBlue = NSColor(calibratedRed: 0.25, green: 0.6, blue: 0.95, alpha: 1)
let leafGreen = NSColor(calibratedRed: 0.3, green: 0.7, blue: 0.35, alpha: 1)
let treeGreen = NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.3, alpha: 1)
let coffeeBrown = NSColor(calibratedRed: 0.35, green: 0.2, blue: 0.1, alpha: 1)
let potionPurple = NSColor(calibratedRed: 0.6, green: 0.35, blue: 0.9, alpha: 1)
let fishBlue = NSColor(calibratedRed: 0.35, green: 0.65, blue: 0.85, alpha: 1)
let fishDark = NSColor(calibratedRed: 0.2, green: 0.45, blue: 0.65, alpha: 1)
let steel = NSColor(white: 0.7, alpha: 1)
let pumpkinOrange = NSColor(calibratedRed: 0.98, green: 0.55, blue: 0.12, alpha: 1)
let pumpkinDark = NSColor(calibratedRed: 0.88, green: 0.42, blue: 0.08, alpha: 1)
let flameOrange = NSColor(calibratedRed: 1, green: 0.6, blue: 0.15, alpha: 1)

// everyday props, picked at random on spawn
let randomDone = ["icecream", "wand", "balloon", "trophy", "popper", "flag", "coffee",
                  "pizza", "donut", "sword", "potion", "umbrella", "fish"]
let randomAsk = ["megaphone", "bell", "flashlight", "sign", "pencil"]
let specials = ["pumpkin", "tree", "flower", "candle"]
// props phrase.sh (Haiku) may pick when one clearly fits the task
let doneItems = randomDone + ["wrench", "extinguisher", "pencil"] + specials
let askItems = randomAsk + specials

let now = Calendar.current.dateComponents([.month, .hour], from: Date())
let month = now.month ?? 1, hour = now.hour ?? 12
let seasonal: String? = month == 10 ? "pumpkin" : (month == 12 ? "tree" : ((3...5).contains(month) ? "flower" : nil))

func pickItem() -> String {
    var pool = isAsk ? randomAsk : randomDone
    // extra copies make the seasonal / time-of-day props show up more often
    if let s = seasonal { pool += Array(repeating: s, count: max(1, pool.count / 3)) }
    if hour >= 22 || hour < 5 { pool += Array(repeating: "candle", count: max(1, pool.count / 4)) }
    if !isAsk && (6...10).contains(hour) { pool += Array(repeating: "coffee", count: 3) }
    return pool.randomElement()!
}

// a forced object (or "crown") for previewing: the ITEM= argument, a prop name given as the mode,
// or CLAUDIO_ITEM. An empty or unknown name is ignored (main.swift rejects a bad ITEM= argument).
let allItems = Set(doneItems + askItems)
func isProp(_ name: String) -> Bool { allItems.contains(name) || name == "crown" }
let requestedItem = options["ITEM"] ?? (isProp(mode) ? mode : nil)
    ?? ProcessInfo.processInfo.environment["CLAUDIO_ITEM"]
let forced = requestedItem.flatMap { isProp($0) ? $0 : nil }
let initialItem = forced.flatMap { allItems.contains($0) ? $0 : nil } ?? pickItem()
let crowned = forced == "crown" || (forced == nil && Int.random(in: 0..<50) == 0)
