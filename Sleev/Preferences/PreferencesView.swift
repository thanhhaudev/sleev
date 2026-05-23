import AppKit
import SleevCore
import SwiftUI

/// The Preferences window content — General, Shortcuts, and Auto-hide sections.
/// Each section is a bold title above a rounded card, matching native macOS
/// System Settings.
///
/// Laid out with `VStack` (not a `.grouped` `Form`) so the view has an intrinsic
/// height — the window is hosted directly in an `NSWindow`, not a SwiftUI
/// `Settings` scene, so it must size itself to its content.
struct PreferencesView: View {
    let onAutoHideSettingsChanged: () -> Void
    let onHotkeyChanged: (HotkeyAction, Hotkey?) -> Void
    let onRecordingActiveChanged: (Bool) -> Void
    let onMenuBarAppearanceChanged: () -> Void

    @AppStorage(Preferences.Key.autoHideEnabled, store: SleevDefaults.shared())
    private var autoHideEnabled = false

    @AppStorage(Preferences.Key.autoHideDelay, store: SleevDefaults.shared())
    private var autoHideDelay = Preferences.defaultAutoHideDelay

    @AppStorage(Preferences.Key.menuBarShowPill, store: SleevDefaults.shared())
    private var menuBarShowPill = true

    @AppStorage(Preferences.Key.menuBarShowDots, store: SleevDefaults.shared())
    private var menuBarShowDots = true

    @AppStorage(Preferences.Key.menuBarShowChevron, store: SleevDefaults.shared())
    private var menuBarShowChevron = true

    @AppStorage(Preferences.Key.menuBarHandleSize, store: SleevDefaults.shared())
    private var menuBarHandleSize = Preferences.defaultHandleSize

    @AppStorage(Preferences.Key.menuBarSeparatorSize, store: SleevDefaults.shared())
    private var menuBarSeparatorSize = Preferences.defaultSeparatorSize

    @AppStorage(Preferences.Key.menuBarSeparatorOpacity, store: SleevDefaults.shared())
    private var menuBarSeparatorOpacity = Preferences.defaultSeparatorOpacity

    @State private var openAtLogin = false
    @State private var toggleSleeveHotkey: Hotkey?
    @State private var openPopoverHotkey: Hotkey?
    @State private var recordingAction: HotkeyAction?
    private let loginItem = LoginItemService()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            generalSection
            menuBarSection
            shortcutsSection
            autoHideSection
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
        .onChange(of: menuBarShowPill) { _, _ in onMenuBarAppearanceChanged() }
        .onChange(of: menuBarShowDots) { _, _ in onMenuBarAppearanceChanged() }
        .onChange(of: menuBarShowChevron) { _, _ in onMenuBarAppearanceChanged() }
        .onChange(of: menuBarHandleSize) { _, _ in onMenuBarAppearanceChanged() }
        .onChange(of: menuBarSeparatorSize) { _, _ in onMenuBarAppearanceChanged() }
        .onChange(of: menuBarSeparatorOpacity) { _, _ in onMenuBarAppearanceChanged() }
    }

    // MARK: - Sections

    private var generalSection: some View {
        section("General") {
            settingsRow {
                Text("Open at login")
                Spacer()
                Toggle("Open at login", isOn: Binding(
                    get: { openAtLogin },
                    set: { setOpenAtLogin($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
        }
    }

    private var shortcutsSection: some View {
        section("Shortcuts") {
            settingsRow {
                Text("Toggle sleeve")
                Spacer()
                HotkeyRecorder(
                    id: HotkeyAction.toggleSleeve,
                    activeRecorder: $recordingAction,
                    hotkey: toggleSleeveHotkey,
                    isDuplicate: { duplicates($0, of: openPopoverHotkey) },
                    onRecordingChanged: onRecordingActiveChanged,
                    onChange: { newValue in
                        toggleSleeveHotkey = newValue
                        onHotkeyChanged(.toggleSleeve, newValue)
                    }
                )
            }
            rowDivider
            settingsRow {
                Text("Open popover")
                Spacer()
                HotkeyRecorder(
                    id: HotkeyAction.openPopover,
                    activeRecorder: $recordingAction,
                    hotkey: openPopoverHotkey,
                    isDuplicate: { duplicates($0, of: toggleSleeveHotkey) },
                    onRecordingChanged: onRecordingActiveChanged,
                    onChange: { newValue in
                        openPopoverHotkey = newValue
                        onHotkeyChanged(.openPopover, newValue)
                    }
                )
            }
        }
    }

    private var autoHideSection: some View {
        section("Auto-hide") {
            settingsRow {
                Text("Hide menu bar icons automatically")
                Spacer()
                Toggle("Hide menu bar icons automatically", isOn: $autoHideEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            rowDivider
            settingsRow {
                Text("Hide after")
                Spacer()
                Slider(value: $autoHideDelay, in: 3 ... 30, step: 1)
                    .frame(width: 150)
                Text("\(Int(autoHideDelay))s")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            .disabled(!autoHideEnabled)
        }
    }

    private var menuBarSection: some View {
        section("Menu bar icon") {
            settingsRow {
                Text("Show pill")
                Spacer()
                Toggle("Show pill", isOn: $menuBarShowPill)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(menuBarShowPill && enabledHandleCount == 1)
            }
            rowDivider
            settingsRow {
                Text("Show three dots")
                Spacer()
                Toggle("Show three dots", isOn: $menuBarShowDots)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(menuBarShowDots && enabledHandleCount == 1)
            }
            rowDivider
            settingsRow {
                Text("Show chevron")
                Spacer()
                Toggle("Show chevron", isOn: $menuBarShowChevron)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(menuBarShowChevron && enabledHandleCount == 1)
            }
            rowDivider
            sliderRow("Handle size", value: $menuBarHandleSize, range: 10 ... 18)
            rowDivider
            sliderRow("Separator size", value: $menuBarSeparatorSize, range: 3 ... 12)
            rowDivider
            sliderRow(
                "Separator opacity",
                value: $menuBarSeparatorOpacity,
                range: 20 ... 100,
                step: 5,
                unit: "%"
            )
        }
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        unit: String = "px"
    ) -> some View {
        settingsRow {
            Text(title)
            Spacer()
            Slider(value: value, in: range, step: step)
                .frame(width: 150)
            Text("\(Int(value.wrappedValue))\(unit)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
    }

    private var enabledHandleCount: Int {
        [menuBarShowPill, menuBarShowDots, menuBarShowChevron].filter { $0 }.count
    }

    // MARK: - Building blocks

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
    }

    private func settingsRow(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 14)
    }

    private func duplicates(_ candidate: Hotkey, of other: Hotkey?) -> Bool {
        guard let other else { return false }
        return candidate.keyCode == other.keyCode
            && candidate.carbonModifiers == other.carbonModifiers
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
