import AppKit
import SleevCore

@main
final class SleevApp: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = SleevApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Sleev launched, SleevCore.version = %@", SleevCore.version)
    }
}
