import Cocoa

class FinderActionHelper {
    static let shared = FinderActionHelper()
    
    /// Trigger in-place inline renaming in Finder (simulates Return key on the selected item)
    func triggerRename() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            let script = """
            tell application "Finder" to activate
            tell application "System Events"
                tell process "Finder"
                    key code 36
                end tell
            end tell
            """
            process.arguments = ["-e", script]
            try? process.run()
            process.waitUntilExit()
            NSLog("[TouchAir] Triggered rename in Finder")
        }
    }
    
    /// Safely move files to macOS Trash (supports Undo with Cmd+Z)
    func moveToTrash(urls: [URL], completion: ((Bool) -> Void)? = nil) {
        guard !urls.isEmpty else { return }
        
        NSWorkspace.shared.recycle(urls) { (recycledDict, error) in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("[TouchAir] Failed to recycle files: \(error.localizedDescription)")
                    // Fallback to AppleScript if needed
                    self.fallbackTrashWithAppleScript(urls: urls, completion: completion)
                } else {
                    NSLog("[TouchAir] Successfully moved \(urls.count) file(s) to Trash")
                    completion?(true)
                }
            }
        }
    }
    
    private func fallbackTrashWithAppleScript(urls: [URL], completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            let script = """
            tell application "Finder"
                try
                    delete selection
                    return "OK"
                on error
                    return "FAIL"
                end try
            end tell
            """
            process.arguments = ["-e", script]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            DispatchQueue.main.async {
                completion?(str == "OK")
            }
        }
    }
}
