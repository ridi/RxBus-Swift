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
```
