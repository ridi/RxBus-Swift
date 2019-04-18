import Foundation
import RxBus
import RxSwift
import WatchKit

// Defining Events struct
struct Events {
    struct LoggedIn: BusEvent {
        let userId: String
    }
    struct LoggedOut: BusEvent { }
    struct Purchased: BusEvent {
        let tid: Int
    }
}

// Defining Custom Notification
extension Notification.Name {
    static let ViewControllerDidLoad = Notification.Name("ViewControllerDidLoadNotification")
}

class InterfaceController: WKInterfaceController {
    private let disposeBag = DisposeBag()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if NSClassFromString("XCTest") != nil {
            return
        }
        
        let bus = RxBus.shared
        
        // Event subscription/posting
        
        bus.asObservable(event: Events.LoggedIn.self).subscribe { event in
            print("LoggedIn, userId = \(event.element!.userId)")
        }.disposed(by: disposeBag)
        bus.post(event: Events.LoggedIn(userId: "davin.ahn"))
        
        // Sticky events
        
        bus.post(event: Events.LoggedOut(), sticky: true)
        bus.asObservable(event: Events.LoggedOut.self, sticky: true).subscribe { _ in
            print("LoggedOut")
        }.disposed(by: disposeBag)
        
        // Subscription priority
        
        bus.asObservable(event: Events.Purchased.self, sticky: false, priority: -1).subscribe { event in
            print("Purchased(priority: -1), tid = \(event.element!.tid)")
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self, sticky: false, priority: 1).subscribe { event in
            print("Purchased(priority: 1), tid = \(event.element!.tid)")
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self).subscribe { event in
            print("Purchased(priority: 0 = default), tid = \(event.element!.tid)")
        }.disposed(by: disposeBag)
        bus.post(event: Events.Purchased(tid: 1001))
        
        // System Notification subscription
        
        bus.asObservable(notificationName: .NSUndoManagerDidUndoChange).subscribe { event in
            print("\(event.element!.name.rawValue)")
        }.disposed(by: disposeBag)
        
        let array = NSMutableArray()
        let undoManager = UndoManager()
        undoManager.registerUndo(withTarget: array) { (_) in }
        array.add(0)
        undoManager.undo()
        
        // Custom Notification subscription/posting
        
        bus.post(notificationName: .ViewControllerDidLoad, userInfo: ["message": "Hi~"], sticky: true)
        bus.asObservable(notificationName: .ViewControllerDidLoad, sticky: true).subscribe { event in
            print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo!)")
        }.disposed(by: disposeBag)
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
