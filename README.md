# RxBus
Event bus framework supports sticky events and subscribers priority based on RxSwift.

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)
[![Platform](https://img.shields.io/cocoapods/p/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)
[![License](https://img.shields.io/cocoapods/l/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)

## Requirements
- Xcode 8.0+
- Swift 3
- iOS8+
- watchOS 2.0+
- macOS 10.10+
- tvOS 9.0+

## Installation
This library is distributed by [CocoaPods](https://cocoapods.org).

 CocoaPods is a dependency manager for Cocoa projects. You can install it with the following command:

```
$ gem install cocoapods
```

To integrate RxBus into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Target name in your project>' do
    pod 'RxBus'
end
```

Then, run the following command:

```
$ pod install
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
}.addDisposableTo(disposeBag)
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
}.addDisposableTo(disposeBag)
```

```
LoggedOut
```

#### Subscription priority

```swift
RxBus.shared.asObservable(event: Events.Purchased.self, sticky: false, priority: -1).subscribe { event in
    print("Purchased(priority: -1), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
RxBus.shared.asObservable(event: Events.Purchased.self, sticky: false, priority: 1).subscribe { event in
    print("Purchased(priority: 1), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
RxBus.shared.asObservable(event: Events.Purchased.self).subscribe { event in
    print("Purchased(priority: 0 = default), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
RxBus.shared.post(event: Events.Purchased(tid: 1001))
```

```
Purchased(priority: 1), tid = 1001
Purchased(priority: 0 = default), tid = 1001
Purchased(priority: -1), tid = 1001
```

#### System Notification subscription

```swift
RxBus.shared.asObservable(notificationName: .UIKeyboardWillShow).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo)")
}.addDisposableTo(disposeBag)
textField.becomeFirstResponder()
```

```
UIKeyboardWillShowNotification, userInfo: [AnyHashable("UIKeyboardCenterBeginUserInfoKey"): NSPoint: {160, 694.5}, AnyHashable("UIKeyboardIsLocalUserInfoKey"): 1, AnyHashable("UIKeyboardCenterEndUserInfoKey"): NSPoint: {160, 441.5}, AnyHashable("UIKeyboardBoundsUserInfoKey"): NSRect: {{0, 0}, {320, 253}}, AnyHashable("UIKeyboardFrameEndUserInfoKey"): NSRect: {{0, 315}, {320, 253}}, AnyHashable("UIKeyboardAnimationCurveUserInfoKey"): 7, AnyHashable("UIKeyboardFrameBeginUserInfoKey"): NSRect: {{0, 568}, {320, 253}}, AnyHashable("UIKeyboardAnimationDurationUserInfoKey"): 0.25]
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
}.addDisposableTo(disposeBag)
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
}.addDisposableTo(disposeBag)
```

```
Custom, userInfo: [AnyHashable("value"): 5]
```

