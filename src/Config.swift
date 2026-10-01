import Cocoa

// macOS-notification-style banner (top right): small mascot on the left, speech text on the right.
// Slides in from the right, slides out to the right. Stays 5 minutes unless dismissed
// (click, or SIGUSR1 from scripts/dismiss.sh).
let usage = """
    Usage: claudio [done|ask] [MODE=done|ask] [ITEM=<prop>] [TEXT=<caption>]
           claudio --props    list the props ITEM accepts
    The hook scripts run it as: claudio <done|ask> <phrase-file>
    """
let args = Array(CommandLine.arguments.dropFirst())
// MODE=, ITEM= and TEXT= arguments (key in any case), for running it by hand; the rest are positional
func keyValue(_ a: String) -> (String, String)? {
    guard let eq = a.firstIndex(of: "=") else { return nil }
    let key = a[..<eq].uppercased()
    return ["MODE", "ITEM", "TEXT"].contains(key) ? (key, String(a[a.index(after: eq)...])) : nil
}
let options = Dictionary(args.compactMap(keyValue), uniquingKeysWith: { $1 })
let positional = args.filter { keyValue($0) == nil }
let mode = options["MODE"] ?? positional.first ?? "done"
let phraseFile = positional.count > 1 ? positional[1] : nil
let isAsk = mode == "ask"
// shown at once; phrase.sh may later send a task-specific line from Haiku
let cannedDone = ["Bro I have finished!", "Check it out!", "All done, come look!", "Nailed it!", "Done and dusted!"]
let cannedAsk = ["Hey! I need your input!", "Psst, your turn!", "I'm stuck, help me out!",
                 "Need a decision here!", "Over here, I have a question!"]
let initialPhrase = options["TEXT"].flatMap { $0.isEmpty ? nil : $0 }
    ?? (isAsk ? cannedAsk : cannedDone).randomElement()!
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
