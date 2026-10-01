import Cocoa

// Usage: claudio <done|ask> [phrase-file]
// macOS-notification-style banner (top right): small mascot on the left, speech text on the right.
// Slides in from the right, slides out to the right. Stays 5 minutes unless dismissed
// (click, or SIGUSR1 from scripts/dismiss.sh).
let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "done"
let isAsk = mode == "ask"
let lifetime: Double = 300
let slideTime = 0.45
// everything is laid out in a 440x150 design space and drawn at this scale
let uiScale: CGFloat = 0.85
let design = NSSize(width: 440, height: 150)

let orange = NSColor(calibratedRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)
let shade = NSColor(calibratedRed: 0.72, green: 0.37, blue: 0.26, alpha: 1)
let ink = NSColor(white: 0.1, alpha: 1)
let mouthColor = NSColor(calibratedRed: 0.35, green: 0.1, blue: 0.08, alpha: 1)
let bubbleColor = NSColor(white: 0.92, alpha: 1)
