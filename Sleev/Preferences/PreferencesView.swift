import AppKit
import SleevCore
import SwiftUI

/// The Preferences window content — General, Shortcuts, and Auto-hide sections.
///
/// Laid out with `VStack` + `GroupBox` (not a `.grouped` `Form`) so the view
/// has an intrinsic height — the window is hosted directly in an `NSWindow`,
/// not a SwiftUI `Settings` scene, so it must size itself to its content.
struct PreferencesView: View {
    let onAutoHideSettingsChanged: () -> Void
    let onHotkeyChanged: (HotkeyAction, Hotkey?) -> Void

    @AppStorage(Preferences.Key.autoHideEnabled, store: AppGroupDefaults.shared())
    private var autoHideEnabled = false

    @AppStorage(Preferences.Key.autoHideDelay, store: AppGroupDefaults.shared())
    private var autoHideDelay = Preferences.defaultAutoHideDelay

    @State private var openAtLogin = false
    @State private var toggleSleeveHotkey: Hotkey?
    @State private var openPopoverHotkey: Hotkey?
    @State private var recordingAction: HotkeyAction?
    private let loginItem = LoginItemService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Open at login", isOn: Binding(
                        get: { openAtLogin },
                        set: { setOpenAtLogin($0) }
                    ))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Toggle sleeve")
                        Spacer()
                        HotkeyRecorder(
                            id: HotkeyAction.toggleSleeve,
                            activeRecorder: $recordingAction,
                            hotkey: toggleSleeveHotkey
                        ) { newValue in
                            toggleSleeveHotkey = newValue
                            onHotkeyChanged(.toggleSleeve, newValue)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Open popover")
                        Spacer()
                        HotkeyRecorder(
                            id: HotkeyAction.openPopover,
                            activeRecorder: $recordingAction,
                            hotkey: openPopoverHotkey
                        ) { newValue in
                            openPopoverHotkey = newValue
                            onHotkeyChanged(.openPopover, newValue)
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Auto-hide") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Hide menu bar icons automatically", isOn: $autoHideEnabled)

                    Divider()

                    HStack(spacing: 8) {
                        Text("Hide after")
                        Spacer()
                        Slider(value: $autoHideDelay, in: 3 ... 30, step: 1)
                            .frame(width: 160)
                        Text("\(Int(autoHideDelay))s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }
                    .disabled(!autoHideEnabled)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(width: 420)
        .task {
            let preferences = Preferences()
            openAtLogin = loginItem.isEnabled
            toggleSleeveHotkey = preferences.toggleSleeveHotkey
            openPopoverHotkey = preferences.openPopoverHotkey
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            openAtLogin = loginItem.isEnabled
        }
        .onChange(of: autoHideEnabled) { _, _ in onAutoHideSettingsChanged() }
        .onChange(of: autoHideDelay) { _, _ in onAutoHideSettingsChanged() }
    }

    /// Applies the toggle through `LoginItemService`; on failure, logs and
    /// resets the toggle to the true system state.
    private func setOpenAtLogin(_ enabled: Bool) {
        do {
            try loginItem.setEnabled(enabled)
            openAtLogin = enabled
        } catch {
            Log.app.error("Login item update failed: \(String(describing: error), privacy: .public)")
            openAtLogin = loginItem.isEnabled
        }
    }
}
