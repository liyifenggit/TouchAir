import Cocoa

class TouchBarManager: NSObject, NSTouchBarDelegate {
    static let shared = TouchBarManager()
    
    private let itemAirDrop = NSTouchBarItem.Identifier("com.touchair.action.airdrop")
    private let itemRename = NSTouchBarItem.Identifier("com.touchair.action.rename")
    private let itemTrash = NSTouchBarItem.Identifier("com.touchair.action.trash")
    private let itemClose = NSTouchBarItem.Identifier("com.touchair.action.close")
    
    private var modalTouchBar: NSTouchBar?
    private var airdropButton: NSButton?
    private var renameButton: NSButton?
    private var trashButton: NSButton?
    
    private var currentURLs: [URL] = []
    private var isPresented = false
    
    override init() {
        super.init()
        setupTouchBar()
    }
    
    private func setupTouchBar() {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        self.modalTouchBar = touchBar
    }
    
    private func updateItemIdentifiers() {
        guard let tb = modalTouchBar else { return }
        if currentURLs.count == 1 {
            tb.defaultItemIdentifiers = [itemAirDrop, itemRename, itemTrash, itemClose]
        } else {
            // Batch selection: Rename doesn't apply to multiple files
            tb.defaultItemIdentifiers = [itemAirDrop, itemTrash, itemClose]
        }
    }
    
    // MARK: - NSTouchBarDelegate
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == itemAirDrop {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: " 隔空投送", target: self, action: #selector(handleAirDropAction))
            button.bezelStyle = .rounded
            button.image = AirDropIcon.generate(size: 20, color: .systemBlue)
            button.imagePosition = .imageLeading
            button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
            button.contentTintColor = NSColor.systemBlue
            
            item.view = button
            self.airdropButton = button
            return item
        } else if identifier == itemRename {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: " 重命名", target: self, action: #selector(handleRenameAction))
            button.bezelStyle = .rounded
            
            if let icon = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Rename") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
                button.image = icon.withSymbolConfiguration(config)
                button.imagePosition = .imageLeading
            }
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.contentTintColor = NSColor.systemOrange
            
            item.view = button
            self.renameButton = button
            return item
        } else if identifier == itemTrash {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: " 移至废纸篓", target: self, action: #selector(handleTrashAction))
            button.bezelStyle = .rounded
            
            if let icon = NSImage(systemSymbolName: "trash", accessibilityDescription: "Trash") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
                button.image = icon.withSymbolConfiguration(config)
                button.imagePosition = .imageLeading
            }
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.contentTintColor = NSColor.systemRed
            
            item.view = button
            self.trashButton = button
            return item
        } else if identifier == itemClose {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: " ✕ ", target: self, action: #selector(handleCloseModal))
            button.bezelStyle = .rounded
            item.view = button
            return item
        }
        return nil
    }
    
    // MARK: - Public Selection Update
    func updateSelection(_ urls: [URL]) {
        self.currentURLs = urls
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if urls.isEmpty {
                self.dismissModal()
            } else {
                self.updateItemIdentifiers()
                
                // Update titles
                if urls.count == 1 {
                    let name = urls[0].lastPathComponent
                    let truncated = name.count > 12 ? String(name.prefix(10)) + "…" : name
                    self.airdropButton?.title = " 隔空投送: \(truncated)"
                    self.trashButton?.title = " 移至废纸篓"
                } else {
                    self.airdropButton?.title = " 隔空投送 (\(urls.count))"
                    self.trashButton?.title = " 删除 (\(urls.count))"
                }
                
                self.presentModal()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleAirDropAction() {
        guard !currentURLs.isEmpty else { return }
        NSLog("[TouchAir] AirDrop tapped from Touch Bar")
        
        airdropButton?.contentTintColor = NSColor.systemGreen
        AirDropHelper.shared.share(urls: currentURLs)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.airdropButton?.contentTintColor = NSColor.systemBlue
        }
    }
    
    @objc private func handleRenameAction() {
        NSLog("[TouchAir] Rename tapped from Touch Bar")
        renameButton?.title = " 正在改名…"
        
        FinderActionHelper.shared.triggerRename()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.dismissModal()
        }
    }
    
    @objc private func handleTrashAction() {
        guard !currentURLs.isEmpty else { return }
        NSLog("[TouchAir] Trash tapped from Touch Bar for \(currentURLs.count) file(s)")
        
        trashButton?.title = " ✓ 已移至废纸篓"
        trashButton?.contentTintColor = NSColor.systemGray
        
        FinderActionHelper.shared.moveToTrash(urls: currentURLs) { [weak self] success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.dismissModal()
            }
        }
    }
    
    // MARK: - Presentation & Dismissal
    private func presentModal() {
        guard !isPresented, let tb = modalTouchBar else { return }
        
        let cls: AnyClass = NSTouchBar.self
        let sel = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
        typealias PresentFunc = @convention(c) (AnyClass, Selector, NSTouchBar, NSString?) -> Void
        
        if let method = class_getClassMethod(cls, sel) {
            let imp = method_getImplementation(method)
            let fn = unsafeBitCast(imp, to: PresentFunc.self)
            fn(cls, sel, tb, nil)
            isPresented = true
            NSLog("[TouchAir] Modal TouchBar presented successfully")
        }
    }
    
    private func dismissModal() {
        guard isPresented, let tb = modalTouchBar else { return }
        
        let cls: AnyClass = NSTouchBar.self
        let sel = NSSelectorFromString("dismissSystemModalTouchBar:")
        typealias DismissFunc = @convention(c) (AnyClass, Selector, NSTouchBar) -> Void
        
        if let method = class_getClassMethod(cls, sel) {
            let imp = method_getImplementation(method)
            let fn = unsafeBitCast(imp, to: DismissFunc.self)
            fn(cls, sel, tb)
            isPresented = false
            NSLog("[TouchAir] Modal TouchBar dismissed")
        }
    }
    
    @objc private func handleCloseModal() {
        dismissModal()
    }
}
