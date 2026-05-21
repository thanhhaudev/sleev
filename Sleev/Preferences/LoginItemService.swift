import ServiceManagement

/// Wraps `SMAppService.mainApp` so the Preferences UI can read and set whether
/// sleev launches at login.
struct LoginItemService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
