# RxBus

Event bus framework supports sticky events and subscribers priority based on RxSwift.

## Requirements

- Xcode 10.2+
- Swift 5.0+
- iOS8+
- macOS 10.10+
- tvOS 9.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ridi/RxBus-swift.git", .upToNextMinor(from: "0.1.0"))
]
```

## Usage

#### Imports

```swift
import RxBus
import RxSwift
```

#### Defining Events struct

```swift
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
```

#### Event subscription/posting

```swift
RxBus.shared.asObservable(event: Events.LoggedIn.self).subscribe { event in
    print("LoggedIn, userId = \(event.element!.userId)")
}.disposed(by: disposeBag)
RxBus.shared.post(event: Events.LoggedIn(userId: "davin.ahn"))
```

```
LoggedIn, userId = davin.ahn
```

#### Sticky events

```swift
RxBus.shared.post(event: Events.LoggedOut(), sticky: true)
RxBus.shared.asObservable(event: Events.LoggedOut.self, sticky: true).subscribe { _ in
    print("LoggedOut")
}.disposed(by: disposeBag)
```

```
LoggedOut
```

#### Subscription priority

```swift
RxBus.shared.asObservable(event: Events.Purchased.self, sticky: false, priority: -1).subscribe { event in
    print("Purchased(priority: -1), tid = \(event.element!.tid)")
}.disposed(by: disposeBag)
RxBus.shared.asObservable(event: Events.Purchased.self, sticky: false, priority: 1).subscribe { event in
    print("Purchased(priority: 1), tid = \(event.element!.tid)")
}.disposed(by: disposeBag)
RxBus.shared.asObservable(event: Events.Purchased.self).subscribe { event in
    print("Purchased(priority: 0 = default), tid = \(event.element!.tid)")
}.disposed(by: disposeBag)
RxBus.shared.post(event: Events.Purchased(tid: 1001))
```

```
Purchased(priority: 1), tid = 1001
Purchased(priority: 0 = default), tid = 1001
Purchased(priority: -1), tid = 1001
```

#### System Notification subscription

```swift
RxBus.shared.asObservable(notificationName: UIResponder.keyboardWillShowNotification).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo)")
}.disposed(by: disposeBag)
textField.becomeFirstResponder()
```

```
UIKeyboardWillShowNotification, userInfo: [AnyHashable("UIKeyboardAnimationCurveUserInfoKey"): 7, AnyHashable("UIKeyboardCenterEndUserInfoKey"): NSPoint: {207, 745.5}, AnyHashable("UIKeyboardFrameBeginUserInfoKey"): NSRect: {{0, 896}, {414, 54}}, AnyHashable("UIKeyboardFrameEndUserInfoKey"): NSRect: {{0, 595}, {414, 301}}, AnyHashable("UIKeyboardBoundsUserInfoKey"): NSRect: {{0, 0}, {414, 301}}, AnyHashable("UIKeyboardIsLocalUserInfoKey"): 1, AnyHashable("UIKeyboardAnimationDurationUserInfoKey"): 0.25, AnyHashable("UIKeyboardCenterBeginUserInfoKey"): NSPoint: {207, 923}]
```

#### Defining Custom Notification

```swift
extension Notification.Name {
    static let Custom = Notification.Name("CustomNotification")
}
```

#### Custom Notification subscription/posting

```swift
RxBus.shared.asObservable(notificationName: .Custom).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo)")
}.disposed(by: disposeBag)
RxBus.shared.post(notificationName: .Custom, userInfo: ["message": "Hi~"])
```

```
Custom, userInfo: [AnyHashable("message"): "Hi~"]
```

#### Sticky Notifications

```swift
RxBus.shared.post(notificationName: .Custom, userInfo: ["value": 5], sticky: true)
RxBus.shared.asObservable(notificationName: .Custom, sticky: true).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo)")
}.disposed(by: disposeBag)
```

```
Custom, userInfo: [AnyHashable("value"): 5]
```
