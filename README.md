# RxBus
Event bus framework supports sticky events and subscribers priority based on RxSwift.

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)
[![Platform](https://img.shields.io/cocoapods/p/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)
[![License](https://img.shields.io/cocoapods/l/RxBus.svg?style=flat)](https://cocoadocs.org/docsets/RxBus)

## Requirements
- Xcode 8.0+
- Swift 3
- iOS8+

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
```swift
import RxBus
import RxSwift

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

let bus = RxBus.shared
let disposeBag = DisposeBag()

// Event subscription/posting
bus.asObservable(event: Events.LoggedIn.self).subscribe { event in
    print("LoggedIn, userId = \(event.element!.userId)")
}.addDisposableTo(disposeBag)
bus.post(event: Events.LoggedIn(userId: "davin.ahn"))
// output:
// LoggedIn, userId = davin.ahn

// Sticky events
        
bus.post(event: Events.LoggedOut(), sticky: true)
bus.asObservable(event: Events.LoggedOut.self, sticky: true).subscribe { _ in
    print("LoggedOut")
}.addDisposableTo(disposeBag)
// output:
// LoggedOut
        
// Subscription priority
        
bus.asObservable(event: Events.Purchased.self, sticky: false, priority: -1).subscribe { event in
    print("Purchased(priority: -1), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
bus.asObservable(event: Events.Purchased.self, sticky: false, priority: 1).subscribe { event in
    print("Purchased(priority: 1), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
bus.asObservable(event: Events.Purchased.self).subscribe { event in
    print("Purchased(priority: 0 = default), tid = \(event.element!.tid)")
}.addDisposableTo(disposeBag)
bus.post(event: Events.Purchased(tid: 1001))
// output:
// Purchased(priority: 1), tid = 1001
// Purchased(priority: 0 = default), tid = 1001
// Purchased(priority: -1), tid = 1001
        
// System Notification subscription
        
bus.asObservable(notificationName: .UIKeyboardWillShow).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo!)")
}.addDisposableTo(disposeBag)
textField.becomeFirstResponder()
// output
// UIKeyboardWillShowNotification, userInfo: ...
        
// Custom Notification subscription/posting
        
bus.post(notificationName: .ViewControllerDidLoad, userInfo: ["message": "Hi~"], sticky: true)
bus.asObservable(notificationName: .ViewControllerDidLoad, sticky: true).subscribe { event in
    print("\(event.element!.name.rawValue), userInfo: \(event.element!.userInfo!)")
}.addDisposableTo(disposeBag)
// output:
// ViewControllerDidLoadNotification, userInfo: [AnyHashable("message"): "Hi~"]
```

