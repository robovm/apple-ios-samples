### TemperatureSensor ###
 
===========================================================================
DESCRIPTION:
 
A simple iOS iPhone application that demonstrates how to use the CoreBluetooth Framework to connect to a Bluetooth LE peripheral and read, write and be notified of changes to the characteristics of the peripheral.

The application is designed to work with a custom Bluetooth LE device which allows for the setting of a high and low temperature alarm settings. When the temperature exceeds the minimum or maximum temperature setting, a notification is issued for which the application presents an alarm.

This sample covers the use of non-published Bluetooth LE Services, which require full 128-bit UUIDs for identification.
 
Important:
This project requires a Bluetooth LE Capable Device (Currently only the iPhone 4S) and will not work on the simulator.
 
===========================================================================
BUILD REQUIREMENTS:
 
- Xcode 4.3 or greater
- iOS 5.1 SDK or greater
 
===========================================================================
RUNTIME REQUIREMENTS:
 
iOS 5.1 or later which has full 128-bit UUID support
Bluetooth LE Capable Device
Bluetooth LE Sensor/s
 
===========================================================================
CHANGES FROM PREVIOUS VERSIONS:
 
Version 1.0
- First version.
 
===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.