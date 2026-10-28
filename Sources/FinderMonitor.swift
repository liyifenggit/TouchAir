import Cocoa

protocol FinderMonitorDelegate: AnyObject {
    func finderMonitor(_ monitor: FinderMonitor, didUpdateSelection urls: [URL])
}

class FinderMonitor {
    weak var delegate: FinderMonitorDelegate?
    
    private var timer: Timer?
    private(set) var currentURLs: [URL] = []
    private var isChecking = false
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        // Poll every 0.6 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.queryFinderSelection()
        }
        queryFinderSelection()
    }
    
    func queryFinderSelection() {
        guard !isChecking else { return }
        isChecking = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer { self?.isChecking = false }
            
            // Query Finder selection via system osascript
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            let script = """
            tell application "Finder"
                try
                    set sel to selection as alias list
                    if sel is {} then return ""
                    set out to ""
                    repeat with item_ref in sel
                        set out to out & (POSIX path of item_ref) & linefeed
                    end repeat
                    return out
                on error
                    return ""
                end try
            end tell
            """
            process.arguments = ["-e", script]
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8) {
                    let lines = str.split(separator: "\n").map { String($0) }
                    let newURLs = lines.filter { !$0.isEmpty }.map { URL(fileURLWithPath: $0) }
                    
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if self.newURLsAreDifferent(newURLs) {
                            self.currentURLs = newURLs
                            NSLog("[TouchAir] Finder selection updated: \(newURLs.map { $0.lastPathComponent })")
                            self.delegate?.finderMonitor(self, didUpdateSelection: newURLs)
                        }
                    }
                }
            } catch {
                NSLog("[TouchAir] osascript query error: \(error.localizedDescription)")
            }
        }
    }
    
    private func newURLsAreDifferent(_ newURLs: [URL]) -> Bool {
        if currentURLs.count != newURLs.count { return true }
        for (i, u) in newURLs.enumerated() {
            if currentURLs[i] != u { return true }
        }
        return false
    }
}
