import RxBus
import RxSwift
import XCTest

struct Events {
    struct LoggedIn: BusEvent {
        let userId: String
    }
    struct LoggedOut: BusEvent { }
    struct Purchased: BusEvent {
        let tid: Int
    }
}

extension Notification.Name {
    static let UserNotification = Notification.Name("UserNotification")
}

extension NSPasteboard {
    static let changedNotification = Notification.Name("NSPasteboardChangedNotification")
}

class RxBus_Demo_macOS_Tests: XCTestCase {
    private let bus = RxBus.shared
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        bus.removeAllStickys()
        XCTAssertEqual(bus.count, 0)
    }
    
    private func sendSystemNotification() {
        let array = NSMutableArray()
        let manager = UndoManager()
        array.add(0)
        if #available(OSX 10.11, *) {
            manager.registerUndo(withTarget: array, handler: ({ _ in }))
        }
        manager.undo()
    }
    
    func testEventSubscriptionAndPosting() {
        let executeExpectation = XCTestExpectation(description: "Test event subscription and posting...")
        
        bus.asObservable(event: Events.LoggedIn.self).subscribe { event in
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        bus.post(event: Events.LoggedIn(userId: "davin.ahn"))
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssertEqual(bus.count, 1)
    }
    
    func testStickyEvent() {
        let executeExpectation = XCTestExpectation(description: "Test sticky event...")
        
        bus.post(event: Events.LoggedOut(), sticky: true)
        bus.asObservable(event: Events.LoggedOut.self, sticky: true).subscribe { _ in
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssertEqual(bus.count, 1)
    }
    
    func testEventSubscriptionPriority() {
        let executeExpectation = XCTestExpectation(description: "Test event subscription priority...")
        
        let expect = [10, 2, 1, 0, -1]
        var actual = [Int]()
        bus.asObservable(event: Events.Purchased.self, priority: -1).subscribe { event in
            actual.append(-1)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self, priority: 2).subscribe { event in
            actual.append(2)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self, priority: 10).subscribe { event in
            actual.append(10)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self, priority: 1).subscribe { event in
            actual.append(1)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(event: Events.Purchased.self).subscribe { event in
            actual.append(0)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.post(event: Events.Purchased(tid: 1001))
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssert(actual.elementsEqual(expect))
        XCTAssertEqual(bus.count, 5)
    }
    
    func testSystemNotificationSubscriptionAndPosting() {
        let executeExpectation = XCTestExpectation(description: "Test system notification subscription and posting...")
        
        bus.asObservable(notificationName: .NSUndoManagerDidUndoChange).subscribe { event in
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        sendSystemNotification()
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssertEqual(bus.count, 1)
    }
    
    func testUserNotificationSubscriptionAndPosting() {
        let executeExpectation = XCTestExpectation(description: "Test user notification subscription and posting...")
        
        bus.asObservable(notificationName: .UserNotification).subscribe { event in
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        bus.post(notificationName: .UserNotification)
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssertEqual(bus.count, 1)
    }
    
    func testStickyUserNotification() {
        let executeExpectation = XCTestExpectation(description: "Test sticky user notification...")
        
        bus.post(notificationName: .UserNotification, sticky: true)
        bus.asObservable(notificationName: .UserNotification, sticky: true).subscribe { event in
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssertEqual(bus.count, 1)
    }
    
    func testUserNotificationSubscriptionPriority() {
        let executeExpectation = XCTestExpectation(description: "Test user notification subscription priority...")
        
        let expect = [10, 2, 1, 0, -1]
        var actual = [Int]()
        bus.asObservable(notificationName: .UserNotification, priority: -1).subscribe { event in
            actual.append(-1)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(notificationName: .UserNotification, priority: 2).subscribe { event in
            actual.append(2)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(notificationName: .UserNotification, priority: 10).subscribe { event in
            actual.append(10)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(notificationName: .UserNotification, priority: 1).subscribe { event in
            actual.append(1)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.asObservable(notificationName: .UserNotification).subscribe { event in
            actual.append(0)
            if (actual.count == 5) { executeExpectation.fulfill() }
        }.disposed(by: disposeBag)
        bus.post(notificationName: .UserNotification)
        
        wait(for: [executeExpectation], timeout: 1.0)
        
        XCTAssert(actual.elementsEqual(expect))
        XCTAssertEqual(bus.count, 5)
    }
    
    func testSticky() {
        let executeExpectation = XCTestExpectation(description: "Test sticky...")
        
        bus.post(event: Events.Purchased(tid: 1000), sticky: true)
        bus.post(event: Events.Purchased(tid: 1001), sticky: false)
        bus.post(event: Events.Purchased(tid: 1002), sticky: true)
        bus.asObservable(event: Events.Purchased.self, sticky: true).subscribe { event in
            if executeExpectation.expectedFulfillmentCount == 0 {
                XCTAssertEqual(event.element!.tid, 1002)
            }
            executeExpectation.fulfill()
        }.disposed(by: disposeBag)
        bus.post(event: Events.Purchased(tid: 1003), sticky: true)
        
        wait(for: [executeExpectation], timeout: 1.0)
    }
    
    func testThreadSafe() {
        let executeExpectation = XCTestExpectation(description: "Test thread safe...")
        
        var callCount = 0
        for i in stride(from: 0, to: 100, by: 2) {
            DispatchQueue(label: "LoggedOut \(i)").async {
                self.bus.asObservable(event: Events.LoggedOut.self)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
            DispatchQueue(label: "LoggedOut \(i + 1)").async {
                self.bus.asObservable(event: Events.LoggedOut.self)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
            DispatchQueue(label: "LoggedIn \(i)").async {
                self.bus.asObservable(event: Events.LoggedIn.self)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
            DispatchQueue(label: "LoggedIn \(i + 1)").async {
                self.bus.asObservable(event: Events.LoggedIn.self, priority: i + 1)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
            DispatchQueue(label: "NSUndoManagerDidUndoChange \(i)").async {
                self.bus.asObservable(notificationName: .NSUndoManagerDidUndoChange)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
            DispatchQueue(label: "NSUndoManagerDidUndoChange \(i + 1)").async {
                self.bus.asObservable(notificationName: .NSUndoManagerDidUndoChange, priority: i + 1)
                    .subscribeOn(MainScheduler.instance)
                    .subscribe { _ in
                        callCount += 1
                    }
                    .disposed(by: self.disposeBag)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.bus.post(event: Events.LoggedOut())
            self.bus.post(event: Events.LoggedIn(userId: "davin.ahn"))
            self.sendSystemNotification()
            executeExpectation.fulfill()
        }
        
        wait(for: [executeExpectation], timeout: 5.0)
        
        XCTAssertEqual(bus.count, callCount)
    }
}
