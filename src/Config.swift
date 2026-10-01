import Cocoa

// macOS-notification-style banner (top right): small mascot on the left, speech text on the right.
// Slides in from the right, slides out to the right. Stays 5 minutes unless dismissed
// (click, or SIGUSR1 from scripts/dismiss.sh).
let usage = """
    Usage: claudio [done|ask] [MODE=done|ask] [PROP=<prop>] [ACCESSORY=<accessory>] [MASCOT=<color>] [TEXT=<caption>]
           claudio --props          list the props PROP accepts
           claudio --accessories    list the accessories ACCESSORY accepts
           claudio --mascots        list the mascot colors MASCOT accepts
    The hook scripts run it as: claudio <done|ask> <phrase-file>
    """
let args = Array(CommandLine.arguments.dropFirst())
// MODE=, PROP=, ACCESSORY=, MASCOT= and TEXT= arguments (key in any case), for running it by
// hand; the rest are positional
func keyValue(_ a: String) -> (String, String)? {
    guard let eq = a.firstIndex(of: "=") else { return nil }
    let key = a[..<eq].uppercased()
    return ["MODE", "PROP", "ACCESSORY", "MASCOT", "TEXT"].contains(key) ? (key, String(a[a.index(after: eq)...])) : nil
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
// scales only the continuous jump/wave/mouth animation's effective clock (see animT in
// Mascot.swift) — never the one-off animations' scheduling or real-time thresholds (blink,
// backflip, sleepiness, confetti, knock...), which all stay on the real t. <1 = slower.
let animSpeed: Double = 0.75
// CLAUDIO_SLEEP_TEST=1: the "getting sleepy" animation in seconds instead of minutes, for previewing
// it without waiting around. Never set by the hooks, so production timing (45s/15s) is untouched.
let sleepTestMode = ProcessInfo.processInfo.environment["CLAUDIO_SLEEP_TEST"] != nil
let dozeStart: Double = sleepTestMode ? 3 : 45
let dozeSpan: Double = sleepTestMode ? 5 : 15
// everything is laid out in a 440x150 design space and drawn at this scale
let uiScale: CGFloat = 0.85
let design = NSSize(width: 440, height: 150)

// the fleet: a body shape archetype, plus per-mascot (body color, body's shade, an optional
// accent color). Eyes, mouth and the speech bubble stay the same regardless, so only the body
// silhouette, limbs and this one accent tell two mascots apart — enough to still read as the
// same family. MASCOT=<name>/CLAUDIO_MASCOT= forces one for previewing. "orange" is a real,
// selectable entry (not just a fallback for an unrecognized name) so `--mascots` lists it and
// `MASCOT=orange` works explicitly, same as the other two.
enum BodyStyle {
    case classic   // flat rect + separate highlight strip, blocky limbs, squared eyes (the original)
    case round     // smooth teardrop (no legs), shaded with a gradient, round eyes
    case ghost     // a dome top over a scalloped, wavy hem (no legs) — arms stay like round's
}
let mascotPalettes: [String: (NSColor, NSColor, NSColor?, BodyStyle)] = [
    "orange": (NSColor(calibratedRed: 0.85, green: 0.47, blue: 0.34, alpha: 1),
               NSColor(calibratedRed: 0.72, green: 0.37, blue: 0.26, alpha: 1),
               nil,
               .classic),
    "yellow": (NSColor(calibratedRed: 0.97, green: 0.78, blue: 0.22, alpha: 1),
               NSColor(calibratedRed: 0.88, green: 0.63, blue: 0.1, alpha: 1),
               NSColor(calibratedRed: 0.55, green: 0.32, blue: 0.05, alpha: 1),
               .round),
    "blue": (NSColor(calibratedRed: 0.35, green: 0.55, blue: 0.95, alpha: 1),
             NSColor(calibratedRed: 0.25, green: 0.42, blue: 0.8, alpha: 1),
             nil,
             .ghost),
]
let mascotNames = mascotPalettes.keys.sorted()
// random spawns, same reasoning as crowned/accessory: 5 parts orange to 2 parts each other
// mascot — built from `mascotNames` rather than listing them, so a future one added to
// mascotPalettes gets the same 2-part weight automatically, no change needed here.
func pickMascot() -> String {
    let pool = mascotNames.flatMap { name in Array(repeating: name, count: name == "orange" ? 5 : 2) }
    return pool.randomElement()!
}
let requestedMascot = options["MASCOT"] ?? (mascotNames.contains(mode) ? mode : nil)
    ?? ProcessInfo.processInfo.environment["CLAUDIO_MASCOT"]
    ?? pickMascot()
// still falls back safely (to the plain orange look) if somehow given an unrecognized name
let mascotPalette = mascotPalettes[requestedMascot]

let orange = mascotPalette?.0 ?? NSColor(calibratedRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)
let shade = mascotPalette?.1 ?? NSColor(calibratedRed: 0.72, green: 0.37, blue: 0.26, alpha: 1)
let accentColor = mascotPalette?.2
let bodyStyle = mascotPalette?.3 ?? .classic
let roundBody = bodyStyle == .round   // kept around: still the cleanest check at most call sites
// the actual top of this mascot's head/body, in mascot-local y — classic and round's top (235)
// is the long-standing reference everything else (the crown, headroom checks) was tuned against;
// ghost's dome reaches higher (295, see ghostPath in Mascot.swift), so anything anchored to "the
// top of the head" needs this instead of the old fixed 235.
let headTopY: CGFloat = bodyStyle == .ghost ? 295 : 235
let ink = NSColor(white: 0.1, alpha: 1)
let mouthColor = NSColor(calibratedRed: 0.35, green: 0.1, blue: 0.08, alpha: 1)
let bubbleColor = NSColor(white: 0.92, alpha: 1)

// bright, festive — deliberately outside the mascot's own muted palette, for the confetti burst
let confettiColors = [
    NSColor(calibratedRed: 0.95, green: 0.3, blue: 0.3, alpha: 1),
    NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.2, alpha: 1),
    NSColor(calibratedRed: 0.3, green: 0.55, blue: 0.95, alpha: 1),
    NSColor(calibratedRed: 0.35, green: 0.75, blue: 0.4, alpha: 1),
    NSColor(calibratedRed: 0.85, green: 0.45, blue: 0.85, alpha: 1),
]
