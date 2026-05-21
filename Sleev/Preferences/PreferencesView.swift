import SleevCore
import SwiftUI

/// The Preferences window content. v1 has a single Auto-hide section; later
/// features add their own sections here.
struct PreferencesView: View {
    let onAutoHideSettingsChanged: () -> Void

    @AppStorage(Preferences.Key.autoHideEnabled, store: AppGroupDefaults.shared())
    private var autoHideEnabled = false

    @AppStorage(Preferences.Key.autoHideDelay, store: AppGroupDefaults.shared())
    private var autoHideDelay = Preferences.defaultAutoHideDelay

    var body: some View {
        Form {
            Section("Auto-hide") {
                Toggle("Hide menu bar icons automatically", isOn: $autoHideEnabled)

                LabeledContent("Hide after") {
                    HStack(spacing: 8) {
                        Slider(value: $autoHideDelay, in: 3 ... 30, step: 1)
                            .frame(width: 160)
                        Text("\(Int(autoHideDelay))s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
                .disabled(!autoHideEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .onChange(of: autoHideEnabled) { _, _ in onAutoHideSettingsChanged() }
        .onChange(of: autoHideDelay) { _, _ in onAutoHideSettingsChanged() }
    }
}
