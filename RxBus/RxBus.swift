import RxSwift

public protocol BusEvent {
    static var name: String { get }
}

public extension BusEvent {
    static var name: String {
        return "\(self)"
    }
}

private let accessQueue = DispatchQueue(label: "com.ridi.rxbus.accessQueue", attributes: .concurrent)

private class SynchronizedValues<Key: Hashable, Value: Any>: Sequence {
    private var _values = [Key: Value]()
    
    init() { }
    
    init(key: Key, value: Value) {
        self[key] = value
    }
    
    subscript(key: Key) -> Value? {
        get {
            var value: Value?
            accessQueue.sync {
                value = self._values[key]
            }
            return value
        }
        set {
            accessQueue.async(flags: .barrier) {
                self._values[key] = newValue
            }
        }
    }
    
    var keys: Dictionary<Key, Value>.Keys {
        var keys: Dictionary<Key, Value>.Keys!
        accessQueue.sync {
            keys = self._values.keys
        }
        return keys
    }
    
    var values: Dictionary<Key, Value>.Values {
        var values: Dictionary<Key, Value>.Values!
        accessQueue.sync {
            values = self._values.values
        }
        return values
    }
    
    var isEmpty: Bool {
        var isEmpty = false
        accessQueue.sync {
            isEmpty = self._values.isEmpty
        }
        return isEmpty
    }
    
    func removeValue(forKey key: Key) -> Value? {
        let value = _values[key]
        accessQueue.async(flags: .barrier) {
            self._values.removeValue(forKey: key)
        }
        return value
    }
    
    typealias Iterator = DictionaryIterator<Key, Value>
    
    func makeIterator() -> Dictionary<Key, Value>.Iterator {
        return _values.makeIterator()
    }
}

public final class RxBus: CustomStringConvertible {
    public static let shared = RxBus()
    
    private init() { }
    
    // MARK: -
    
    private let separator = Character("_")
    private typealias EventName = String
    private typealias EventPriority = Int
    private typealias SubscriptionKey = String // EventName + separator + EventPriority
    
    private var subjects = SynchronizedValues<SubscriptionKey, Any>()
    private var subscriptionCounts = SynchronizedValues<SubscriptionKey, Int>()
    private var stickyMap = SynchronizedValues<EventName, Any>()
    private var nsObservers = SynchronizedValues<EventName, Any>()
    
    public var count: Int {
        return subscriptionCounts.values.reduce(0, +)
    }
    
    public var description: String {
        var string = "Subscription List:\n"
        subjects.keys.sorted(by: { $0 > $1 }).forEach { key in
            string += "\t\(key)\n"
            let priority = sliceEventPriority(fromKey: key)
            let count = subscriptionCounts[key] ?? 0
            string += "\t\tPriority: \(priority), Subject: \(String(describing: subjects[key])), Count: \(count)\n"
        }
        if subjects.isEmpty {
            string += "\tEmpty\n"
        }
        string += "Sticky List:\n"
        for (key, subject) in stickyMap {
            string += "\t\(key)\n"
            string += "\t\tSubject: \(subject)\n"
        }
        if stickyMap.isEmpty {
            string += "\tEmpty\n"
        }
        return "\(string)"
    }
    
    // MARK: -
    
    private func makeSubscriptionKey(eventName: EventName, priority: EventPriority) -> SubscriptionKey {
        return "\(eventName)\(separator)\(priority)"
    }
    
    private func sliceEventName(fromKey key: SubscriptionKey) -> EventName {
        return key.split(separator: separator).dropLast().joined(separator: "\(separator)")
    }
    
    private func sliceEventPriority(fromKey key: SubscriptionKey) -> EventPriority {
        if let string = key.split(separator: separator).last {
            return Int(string) ?? 0
        }
        return 0
    }
    
    // MARK: -
    
    private func increaseSubscriptionCount(forKey key: SubscriptionKey) {
        if let count = subscriptionCounts[key] {
            subscriptionCounts[key] = count + 1
        } else {
            subscriptionCounts[key] = 1
        }
    }
    
    private func decreaseSubscriptionCount(forKey key: SubscriptionKey) {
        if let count = subscriptionCounts[key] {
            if count - 1 == 0 {
                let eventName = sliceEventName(fromKey: key)
                _ = subjects.removeValue(forKey: key)
                _ = subscriptionCounts.removeValue(forKey: key)
                if subscriptionCounts.keys.first(where: { $0.hasPrefix(eventName) }) == nil {
                    if let nsObserver = nsObservers[eventName] {
                        NotificationCenter.default.removeObserver(nsObserver)
                        _ = nsObservers.removeValue(forKey: eventName)
                    }
                }
            } else {
                subscriptionCounts[key] = count - 1
            }
        }
    }
    
    // MARK: -
    
    public func asObservable<T: BusEvent>(event: T.Type, priority: Int) -> Observable<T> {
        return asObservable(event: event, sticky: false, priority: priority)
    }
    
    public func asObservable<T: BusEvent>(event: T.Type, sticky: Bool = false, priority: Int = 0) -> Observable<T> {
        let key = makeSubscriptionKey(eventName: event.name, priority: priority)
        if subjects[key] == nil {
            subjects[key] = PublishSubject<T>()
        }
        let observable = (subjects[key] as! PublishSubject<T>).do(
            onNext: nil,
            onError: nil,
            onCompleted: nil,
            onSubscribe: {
                self.increaseSubscriptionCount(forKey: key)
            },
            onSubscribed: nil,
            onDispose: {
                self.decreaseSubscriptionCount(forKey: key)
            }
        )
        if sticky,
            let lastEvent = removeSticky(event: event) {
                return Observable.of(observable, Observable.create({ subscriber -> Disposable in
                    subscriber.onNext(lastEvent)
                    return Disposables.create()
                })).merge()
        }
        return observable
    }
    
    public func post<T: BusEvent>(event: T, sticky: Bool = false) {
        let eventName = "\(type(of: event))"
        if sticky {
            stickyMap[eventName] = event
        }
        subjects.filter { $0.key.hasPrefix(eventName) }
            .sorted(by: { $0.key > $1.key })
            .forEach { ($0.value as? PublishSubject<T>)?.onNext(event) }
    }
    
    public func stickyEvent<T: BusEvent>(_ event: T.Type) -> T? {
        return stickyMap[event.name] as? T
    }
    
    public func removeSticky<T: BusEvent>(event: T.Type) -> T? {
        return stickyMap.removeValue(forKey: event.name) as? T
    }
    
    // MARK: -
    
    private func dispatchNotification(_ notification: Notification) {
        let eventName = notification.name.rawValue
        subjects.filter { $0.key.hasPrefix(eventName) }
            .sorted(by: { $0.key > $1.key })
            .forEach { ($0.value as? PublishSubject<Notification>)?.onNext(notification) }
    }
    
    private func makeNotificationObservable(name: Notification.Name) -> Observable<Notification> {
        let observable = PublishSubject<Notification>()
        let nsObserver = nsObservers[name.rawValue]
        if nsObserver == nil {
            let base = NotificationCenter.default.rx.base
            nsObservers[name.rawValue] = base.addObserver(forName: name, object: nil, queue: nil) { notification in
                self.dispatchNotification(notification)
            }
        }
        return observable
    }
    
    public func asObservable(notificationName name: Notification.Name, priority: Int) -> Observable<Notification> {
        return asObservable(notificationName: name, sticky: false, priority: priority)
    }
    
    public func asObservable(
        notificationName name: Notification.Name,
        sticky: Bool = false,
        priority: Int = 0
    ) -> Observable<Notification> {
        let key = makeSubscriptionKey(eventName: name.rawValue, priority: priority)
        if subjects[key] == nil {
            subjects[key] = makeNotificationObservable(name: name)
        }
        let observable = (subjects[key] as! Observable<Notification>).do(
            onNext: nil,
            onError: nil,
            onCompleted: nil,
            onSubscribe: {
                self.increaseSubscriptionCount(forKey: key)
            },
            onSubscribed: nil,
            onDispose: {
                self.decreaseSubscriptionCount(forKey: key)
            }
        )
        if sticky,
            let lastNotification = removeStickyNotification(name: name) {
                return Observable.of(observable, Observable.create({ subscriber -> Disposable in
                    subscriber.onNext(lastNotification)
                    return Disposables.create()
                })).merge()
        }
        return observable
    }
    
    public func post(
        notificationName name: Notification.Name,
        userInfo: [AnyHashable: Any]? = nil,
        sticky: Bool = false
    ) {
        let notification = Notification(name: name, object: nil, userInfo: userInfo)
        post(notification: notification, sticky: sticky)
    }
    
    public func post(notification: Notification, sticky: Bool = false) {
        let name = notification.name.rawValue
        if sticky {
            stickyMap[name] = notification
        }
        NotificationCenter.default.post(notification)
    }
    
    public func stickyNotification(name: Notification.Name) -> Notification? {
        return stickyMap[name.rawValue] as? Notification
    }
    
    public func removeStickyNotification(name: Notification.Name) -> Notification? {
        return stickyMap.removeValue(forKey: name.rawValue) as? Notification
    }
}
