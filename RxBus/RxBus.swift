import RxSwift

public protocol BusEvent {
    static var name: String { get }
}

public extension BusEvent {
    static var name: String {
        return "\(self)"
    }
}

public final class RxBus {
    public static let shared = RxBus()
    
    private init() { }
    
    // MARK: -
    
    private typealias EventName = String
    private typealias EventPriority = Int
    
    private var subjects = [EventName: [EventPriority: Any]]()
    private var stickyMap = [EventName: Any]()
    private var subscriptionCounts = [EventName: [EventPriority: Int]]()
    
    private var onDisposes = [String: () -> Void]()
    
    // MARK: -
    
    private func increaseSubscriptionCount(onEventName name: EventName, priority: EventPriority) {
        if subscriptionCounts[name] == nil {
            subscriptionCounts[name] = [priority: 1]
        } else if subscriptionCounts[name]![priority] == nil {
            subscriptionCounts[name]![priority] = 1
        } else {
            let count = subscriptionCounts[name]![priority]!
            subscriptionCounts[name]![priority] = count + 1
        }
    }
    
    private func decreaseSubscriptionCount(onEventName name: EventName, priority: EventPriority) {
        if let count = subscriptionCounts[name]?[priority] {
            subscriptionCounts[name]![priority] = count - 1
        }
        if (subscriptionCounts[name]?[priority] ?? 0) == 0 {
            subjects[name]?.removeValue(forKey: priority)
            subscriptionCounts[name]?.removeValue(forKey: priority)
            if subjects[name]?.isEmpty ?? false {
                subjects.removeValue(forKey: name)
                onDisposes.removeValue(forKey: makeNSObserverDisposeKey(name: name, priority: priority))
            }
            if subscriptionCounts[name]?.isEmpty ?? false {
                subscriptionCounts.removeValue(forKey: name)
            }
        }
    }
    
    // MARK: -
    
    public func asObservable<T: BusEvent>(event: T.Type, sticky: Bool = false, priority: Int = 0) -> Observable<T> {
        if subjects[event.name] == nil {
            subjects[event.name] = [priority: PublishSubject<T>()]
        } else if subjects[event.name]![priority] == nil {
            subjects[event.name]![priority] = PublishSubject<T>()
        }
        let observable = subjects[event.name]![priority] as! PublishSubject<T>
        if sticky,
            let lastEvent = removeSticky(event: event) {
                return Observable.of(observable, Observable.create({ subscriber -> Disposable in
                    subscriber.onNext(lastEvent)
                    return Disposables.create()
                })).merge()
        }
        return observable.do(onNext: nil, onError: nil, onCompleted: nil, onSubscribe: {
            self.increaseSubscriptionCount(onEventName: event.name, priority: priority)
        }, onSubscribed: nil, onDispose: {
            self.decreaseSubscriptionCount(onEventName: event.name, priority: priority)
        })
    }
    
    public func post<T: BusEvent>(event: T, sticky: Bool = false) {
        let eventName = "\(type(of: event))"
        if sticky {
            stickyMap[eventName] = event
        }
        if let subjects = subjects[eventName] {
            subjects.keys.sorted(by: { $0 > $1 })
                .forEach { priority in
                    (subjects[priority] as? PublishSubject<T>)?.onNext(event)
                }
        }
    }
    
    public func stickyEvent<T: BusEvent>(_ event: T.Type) -> T? {
        return stickyMap[event.name] as? T
    }
    
    public func removeSticky<T: BusEvent>(event: T.Type) -> T? {
        return stickyMap.removeValue(forKey: event.name) as? T
    }
    
    // MARK: -
    
    private func makeNSObserverDisposeKey(name: String, priority: Int) -> String {
        return "\(name)_\(priority)"
    }
    
    private func makeNotificationObserable(name: Notification.Name, priority: Int) -> Observable<Notification> {
        let observable = PublishSubject<Notification>()
        let base = NotificationCenter.default.rx.base
        let nsObserver = base.addObserver(forName: name, object: nil, queue: nil) { notification in
            observable.asObserver().onNext(notification)
        }
        onDisposes[makeNSObserverDisposeKey(name: name.rawValue, priority: priority)] = {
            base.removeObserver(nsObserver)
        }
        return observable
    }
    
    public func asObservable(notificationName name: Notification.Name, sticky: Bool = false, priority: Int = 0) -> Observable<Notification> {
        if subjects[name.rawValue] == nil {
            subjects[name.rawValue] = [priority: makeNotificationObserable(name: name, priority: priority)]
        } else if subjects[name.rawValue]![priority] == nil {
            subjects[name.rawValue]![priority] = makeNotificationObserable(name: name, priority: priority)
        }
        let observable = subjects[name.rawValue]![priority] as! Observable<Notification>
        if sticky,
            let lastNotification = removeStickyNotification(name: name) {
                return Observable.of(observable, Observable.create({ subscriber -> Disposable in
                    subscriber.onNext(lastNotification)
                    return Disposables.create()
                })).merge()
        }
        let onDispose = onDisposes[makeNSObserverDisposeKey(name: name.rawValue, priority: priority)]
        return observable.do(onNext: nil, onError: nil, onCompleted: nil, onSubscribe: {
            self.increaseSubscriptionCount(onEventName: name.rawValue, priority: priority)
        }, onSubscribed: nil, onDispose: {
            onDispose?()
            self.decreaseSubscriptionCount(onEventName: name.rawValue, priority: priority)
        })
    }
    
    public func post(notificationName name: Notification.Name, userInfo: [AnyHashable : Any]? = nil, sticky: Bool = false) {
        let notification = Notification(name: name, object: nil, userInfo: userInfo)
        post(notification: notification, sticky: sticky)
    }
    
    public func post(notification: Notification, sticky: Bool = false) {
        let name = notification.name.rawValue
        if sticky {
            stickyMap[name] = notification
        }
        if let subjects = subjects[name] {
            subjects.keys.sorted(by: { $0 > $1 })
                .forEach { _ in
                    NotificationCenter.default.post(notification)
                }
        }
    }
    
    public func stickyNotification(name: Notification.Name) -> Notification? {
        return stickyMap[name.rawValue] as? Notification
    }
    
    public func removeStickyNotification(name: Notification.Name) -> Notification? {
        return stickyMap.removeValue(forKey: name.rawValue) as? Notification
    }
}
