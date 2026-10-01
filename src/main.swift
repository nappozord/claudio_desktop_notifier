import Cocoa

// `claudio --props` lists the names ITEM accepts (also used by `make preview`)
if mode == "--props" {
    print((allItems.sorted() + ["crown"]).joined(separator: "\n"))
    exit(0)
}
if mode == "--help" || mode == "-h" { print(usage); exit(0) }
let propList = (allItems.sorted() + ["crown"]).joined(separator: " ")
if let item = options["ITEM"], !isProp(item) {
    fputs("Unknown ITEM '\(item)'. Props: \(propList)\n", stderr)
    exit(1)
}
if mode != "done" && mode != "ask" && !isProp(mode) {
    fputs("Unknown mode '\(mode)': use done or ask (props go in ITEM=, e.g. claudio ITEM=pizza)\n\n\(usage)\n", stderr)
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let size = NSSize(width: design.width * uiScale, height: design.height * uiScale)
let screen = NSScreen.main!.visibleFrame
let win = NSWindow(contentRect: NSRect(x: screen.maxX + 40, y: screen.maxY - size.height - 8,
                                       width: size.width, height: size.height),
                   styleMask: .borderless, backing: .buffered, defer: false)
win.isOpaque = false
win.backgroundColor = .clear
win.hasShadow = false
win.level = .popUpMenu
win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
let view = MascotView(frame: NSRect(origin: .zero, size: size))
win.contentView = view
win.orderFrontRegardless()

signal(SIGUSR1, SIG_IGN)
let dismissSignal = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
dismissSignal.setEventHandler { view.dismiss() }
dismissSignal.resume()

// global key-press monitor: typing elsewhere also counts as activity for the sleepy animation
// (mouse movement is read directly each frame in drawMascot and needs no such monitor). This
// needs the Input Monitoring permission (System Settings → Privacy & Security → Input
// Monitoring) — macOS prompts the first time; until granted, key presses go unseen and only
// mouse movement keeps it from dozing off. Only the fact that a key was pressed is used here,
// never which key — nothing is read from the event or stored.
view.keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { _ in
    view.noteActivity()
}

Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in view.tick() }
app.run()
