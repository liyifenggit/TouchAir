import Cocoa

class AirDropHelper: NSObject, NSSharingServiceDelegate {
    static let shared = AirDropHelper()
    
    private var activeService: NSSharingService?
    
    func share(urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        DispatchQueue.main.async {
            guard let service = NSSharingService(named: .sendViaAirDrop) else {
                NSLog("[TouchAir] NSSharingService.sendViaAirDrop not available")
                return
            }
            
            service.delegate = self
            self.activeService = service
            
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            } else {
                NSLog("[TouchAir] Cannot perform AirDrop with given URLs: \(urls)")
            }
        }
    }
    
    // MARK: - NSSharingServiceDelegate
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        NSLog("[TouchAir] AirDrop successfully sent items: \(items)")
        activeService = nil
    }
    
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        NSLog("[TouchAir] AirDrop cancelled or failed: \(error.localizedDescription)")
        activeService = nil
    }
}
