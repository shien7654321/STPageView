# STPageView

[![Language](https://img.shields.io/badge/language-Swift-limegreen.svg?style=flat)](http://cocoapods.org/pods/STPageView)
[![Platform](https://img.shields.io/cocoapods/p/STPageView.svg?style=flat)](http://cocoapods.org/pods/STPageView)
[![Version](https://img.shields.io/cocoapods/v/STPageView.svg?style=flat)](http://cocoapods.org/pods/STPageView)
[![License](https://img.shields.io/cocoapods/l/STPageView.svg?style=flat)](http://cocoapods.org/pods/STPageView)

## A paging view.
STPageView is a paging view. You can use it to layout multiple view controllers, switching through gestures. And it supports both horizontal and vertical directions.

![STPageViewPreview01](https://github.com/shien7654321/STPageView/raw/master/Preview/STPageViewPreview01.gif)

![STPageViewPreview02](https://github.com/shien7654321/STPageView/raw/master/Preview/STPageViewPreview02.gif)


## Requirements

- iOS 8.0 or later (For iOS 8.0 before, maybe it can work, but I have not tested.)
- ARC
- Swift 5.0

## Installation

STPageView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'STPageView'
```

## Usage

### Import headers in your source files

In the source files where you need to use the library, import the header file:

```swift
import STPageView
```

### Initialize STPageView

Use the following function to initialize the STAlertController, then add it to your view and set up the Auto Layout:

```swift
let pageView = STPageView(controllers: [controllerA, controllerB])
```

### Implement STPageViewDelegate

Implement STPageViewDelegate, you can using some STPageView delegate functions:

```swift
func pageView(_ pageView: STPageView, didSelect controller: UIViewController) {
    print("PageView didSelect \(controller), index \(pageView.controllers.index(of: controller)!)")
}
```

## Author

Suta, shien7654321@163.com


## License

[MIT]: http://www.opensource.org/licenses/mit-license.php
[MIT license][MIT].