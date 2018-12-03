import RxBus
import RxSwift
import UIKit

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

class ViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        bus.asObservable(notificationName: UIScreen.didConnectNotification).subscribe { event in
            print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo!)")
        }.disposed(by: disposeBag)
        
        // Custom Notification subscription/posting
        
        bus.post(notificationName: .ViewControllerDidLoad, userInfo: ["message": "Hi~"], sticky: true)
        bus.asObservable(notificationName: .ViewControllerDidLoad, sticky: true).subscribe { event in
            print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo!)")
        }.disposed(by: disposeBag)
        
    }
}
