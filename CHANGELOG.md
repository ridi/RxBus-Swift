# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

* None.

## [1.2.0 (2019-12-09)]

### Added

- Add `removeAllStickys()` function.
- Add `count` property.
- Supports Carthage.

### Changed

- Bump Swift version to 5.0.
- Bump swiftlint version 0.38.0.
- Remove watchOS target.
- Implement thread-safe read & write.
- Improve `CustomStringConvertible`.

### Fixed

- Fix an issue where events are sent as many as notification subscriptions by different priority.
- Fix an issue where intermittent events nesting.

## [1.1.0 (2018-12-03)]

### Changed

- Bump Swift version to 4.2.
- Apply swiftlint 0.27.0.

## [1.0.4 (2017-12-05)]

### Fixed

- Fix crash when unsubscribe.

## [1.0.3 (2017-12-05)]

### Fixed

- Fix `NSObserver` dispose time.

## [1.0.2 (2017-12-05)]

### Added

- Implement `CustomStringConvertible`.

### Fixed

- Fix subscription counting.

## [1.0.1 (2017-11-29)]

- None.

## [1.0.0 (2017-09-29)]

- First release.

[Unreleased]: https://github.com/ridi/WKJavaScriptController/compare/1.2.0...HEAD
[1.2.0 (2019-12-09)]: https://github.com/ridi/RxBus-Swift/compare/1.1.0...1.2.0
[1.1.0 (2018-12-03)]: https://github.com/ridi/RxBus-Swift/compare/1.0.4...1.1.0
[1.0.4 (2017-12-05)]: https://github.com/ridi/RxBus-Swift/compare/1.0.3...1.0.4
[1.0.3 (2017-12-05)]: https://github.com/ridi/RxBus-Swift/compare/1.0.2...1.0.3
[1.0.2 (2017-12-05)]: https://github.com/ridi/RxBus-Swift/compare/1.0.1...1.0.2
[1.0.1 (2017-11-29)]: https://github.com/ridi/RxBus-Swift/compare/1.0.0...1.0.1
[1.0.0 (2017-09-29)]: https://github.com/ridi/RxBus-Swift/compare/779f17d...1.0.0
