import Cocoa

struct DiscoveredDevice {
    let name: String
    let model: String
    let rawNode: AnyObject
    
    var icon: NSImage {
        let symbol: String
        let m = model.lowercased()
        if m.contains("iphone") {
            symbol = "iphone"
        } else if m.contains("ipad") {
            symbol = "ipad"
        } else if m.contains("mac") || m.contains("book") {
            symbol = "laptopcomputer"
        } else {
            symbol = "airdrop"
        }
        if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: name) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            return img.withSymbolConfiguration(config) ?? img
        }
        return NSImage()
    }
}

class AirDropDeviceScanner: NSObject {
    static let shared = AirDropDeviceScanner()
    
    var onDevicesUpdated: (([DiscoveredDevice]) -> Void)?
    private(set) var devices: [DiscoveredDevice] = []
    
    private var browserInstance: AnyObject?
    private var isScanning = false
    
    override init() {
        super.init()
        setupBrowser()
    }
    
    private func setupBrowser() {
        guard let bundle = Bundle(path: "/System/Library/PrivateFrameworks/Sharing.framework"), bundle.load() else {
            NSLog("[TouchAir] Failed to load Sharing framework for browser")
            return
        }
        
        guard let browserClass = NSClassFromString("SFAirDropBrowser") as? NSObject.Type else {
            NSLog("[TouchAir] SFAirDropBrowser not found")
            return
        }
        
        let browser = browserClass.init()
        self.browserInstance = browser
        browser.setValue(self, forKey: "delegate")
    }
    
    func startScanning(with urls: [URL]) {
        guard let browser = browserInstance, !isScanning else { return }
        isScanning = true
        devices = []
        
        browser.setValue(urls, forKey: "urlsBeingShared")
        let sel = NSSelectorFromString("start")
        if browser.responds(to: sel) {
            browser.perform(sel)
            NSLog("[TouchAir] AirDrop device scanning started")
        }
    }
    
    func stopScanning() {
        guard let browser = browserInstance, isScanning else { return }
        isScanning = false
        
        let sel = NSSelectorFromString("stop")
        if browser.responds(to: sel) {
            browser.perform(sel)
            NSLog("[TouchAir] AirDrop device scanning stopped")
        }
        devices = []
        DispatchQueue.main.async { [weak self] in
            self?.onDevicesUpdated?([])
        }
    }
    
    // MARK: - Browser Delegate Callbacks
    @objc func browserWillChangePeople(_ b: AnyObject) {
        // Called before people list changes
    }
    
    @objc func browserDidChangePeople(_ b: AnyObject) {
        guard let people = b.value(forKey: "people") as? [AnyObject] else { return }
        
        var list: [DiscoveredDevice] = []
        for p in people {
            let name = (p.value(forKey: "displayName") as? String) ?? "附近设备"
            let model = (p.value(forKey: "model") as? String) ?? ""
            list.append(DiscoveredDevice(name: name, model: model, rawNode: p))
        }
        
        self.devices = list
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSLog("[TouchAir] Browser discovered \(list.count) devices")
            self.onDevicesUpdated?(list)
        }
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        let name = NSStringFromSelector(aSelector)
        if name.contains("browser") {
            return true
        }
        return super.responds(to: aSelector)
    }
}
