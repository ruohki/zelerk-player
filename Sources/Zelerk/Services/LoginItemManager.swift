import Foundation
import ServiceManagement

class LoginItemManager {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    static var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                        print("[LoginItem] Enabled start at login")
                    } else {
                        try SMAppService.mainApp.unregister()
                        print("[LoginItem] Disabled start at login")
                    }
                } catch {
                    print("[LoginItem] Failed to \(newValue ? "enable" : "disable"): \(error)")
                }
            }
        }
    }
}
