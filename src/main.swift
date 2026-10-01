import Cocoa

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

Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in view.tick() }
app.run()
