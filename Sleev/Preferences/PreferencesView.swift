import SleevCore
import SwiftUI

/// The Preferences window content. v1 has a single Auto-hide section; later
/// features add their own grouped sections here.
///
/// Laid out with `VStack` + `GroupBox` (not a `.grouped` `Form`) so the view
/// has an intrinsic height — the window is hosted directly in an `NSWindow`,
/// not a SwiftUI `Settings` scene, so it must size itself to its content.
struct PreferencesView: View {
    let onAutoHideSettingsChanged: () -> Void

    @AppStorage(Preferences.Key.autoHideEnabled, store: AppGroupDefaults.shared())
    private var autoHideEnabled = false

    @AppStorage(Preferences.Key.autoHideDelay, store: AppGroupDefaults.shared())
    private var autoHideDelay = Preferences.defaultAutoHideDelay

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .onChange(of: autoHideEnabled) { _, _ in onAutoHideSettingsChanged() }
        .onChange(of: autoHideDelay) { _, _ in onAutoHideSettingsChanged() }
    }
}
