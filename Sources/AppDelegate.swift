import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, FinderMonitorDelegate {
    private var statusItem: NSStatusItem?
    private var finderMonitor: FinderMonitor?
    private var statusMenu: NSMenu?
    private var selectionMenuItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        finderMonitor = FinderMonitor()
        finderMonitor?.delegate = self
        
        // Initialize TouchBar Manager
        _ = TouchBarManager.shared
        
        NSLog("[TouchAir] Application started successfully")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "airdrop", accessibilityDescription: "TouchAir") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
            } else {
                button.title = "📡"
            }
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: "TouchAir - 触控栏隔空投送", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        selectionMenuItem = NSMenuItem(title: "访达未选中文件（触控栏隐藏）", action: nil, keyEquivalent: "")
        selectionMenuItem?.isEnabled = false
        if let selItem = selectionMenuItem {
            menu.addItem(selItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let testItem = NSMenuItem(title: "触发当前文件隔空投送", action: #selector(handleTriggerManual), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出 TouchAir", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        self.statusMenu = menu
    }
    
    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh selection when user opens menu
        finderMonitor?.queryFinderSelection()
    }
    
    func finderMonitor(_ monitor: FinderMonitor, didUpdateSelection urls: [URL]) {
        TouchBarManager.shared.updateSelection(urls)
        
        DispatchQueue.main.async { [weak self] in
            if urls.isEmpty {
                self?.selectionMenuItem?.title = "访达未选中文件（触控栏隐藏）"
            } else if urls.count == 1 {
                let name = urls[0].lastPathComponent
                self?.selectionMenuItem?.title = "已选中: \(name)（触控栏已亮起）"
            } else {
                self?.selectionMenuItem?.title = "已选中 \(urls.count) 个文件（触控栏已亮起）"
            }
        }
    }
    
    @objc private func handleTriggerManual() {
        let urls = finderMonitor?.currentURLs ?? []
        if urls.isEmpty {
            let alert = NSAlert()
            alert.messageText = "未选中任何文件"
            alert.informativeText = "请先在访达（Finder）中点击选中任意文件或文件夹，再尝试投送。"
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            AirDropHelper.shared.share(urls: urls)
        }
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
