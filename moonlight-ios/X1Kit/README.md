![Logo](../assets/icon_76pt.png?raw=true)

[![Language: Swift 5](https://img.shields.io/badge/language-swift%205-f48041.svg?style=flat)](https://developer.apple.com/swift)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/fizzyade/X1Kit/blob/master/LICENSE)

# X1Kit

X1Kit is a Swift framework that allows applications to make direct use of the Citrix X1 mouse.

## Purpose

The X1  provides a Bluetooth Low Energy (BLE) protocol to report position and buttn states, it is capable of operating as a standard BLE mouse or additionally a mode which allows iOS applications to directly access the mouse without any operating system support, this library allows applications to take advantage of this feature.

## Requirements

* A Citrix X1 mouse, the mouse should be paired with iOS.

## Usage

Import X1Kit at the top of the Swift file.

```swift
import X1Kit
```

To use CoreBluetooth you will need to add the following keys (with a value explaining the use of bluetooth) to your application Info.plist, failure to add the appropriate key will result in your application crashing.

iOS 13 or later:

```swift
NSBluetoothAlwaysUsageDescription
```

iOS 12 or earlier:

```swift
NSBluetoothPeripheralUsageDescription
```

The application should instantiate an  instance of the X1Mouse class and set the objects delegate to an object that implements the X1KitMouseDelegate protocol.

```swift
let theMouse = X1Mouse()

theMouse.delegate = self
```

The following protocol is defined by X1Kit and should be implemented.

```swift
protocol X1KitMouseDelegate: class {
    func connectedStateDidChange(identifier: UUID, isConnected: Bool)
    func mouseDidMove(identifier: UUID, deltaX: Int16, deltaY: Int16)
    func mouseDown(identifier: UUID, button: X1MouseButton)
    func mouseUp(identifier: UUID, button: X1MouseButton)
    func wheelDidScroll(identifier: UUID, deltaZ: Int8)
}
```

## License

This project is open source and is released under the [MIT License](LICENSE.md)

Distributed as-is; no warranty is given.
