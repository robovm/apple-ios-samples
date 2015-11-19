
Reachability
============
The Reachability sample application demonstrates how to use the System Configuration framework to monitor the network state of an iOS device. In particular, it demonstrates how to know when IP can be routed and when traffic will be routed through a Wireless Wide Area Network (WWAN) interface such as EDGE or 3G.

Note: Reachability cannot tell your application if you can connect to a particular host, only that an interface is available that might allow a connection, and whether that interface is the WWAN. To understand when and how to use Reachability, read "Networking Overview" (<http://developer.apple.com/library/ios/#documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/>).




Using the Sample
================

Build and run the sample using Xcode. When running the iPhone Simulator, you can exercise the application by disconnecting the Ethernet cable, turning off AirPort, or by joining an ad-hoc local Wi-Fi network.

By default, the application uses www.apple.com for its remote host. You can change the host it uses in APLViewController.m by modifying the value of the remoteHostName variable in -viewDidLoad.

IMPORTANT: Reachability must use DNS to resolve the host name before it can determine the Reachability of that host, and this may take time on certain network connections.  Because of this, the API will return NotReachable until name resolution has completed.  This delay may be visible in the interface on some networks.

The Reachability sample demonstrates the asynchronous use of the SCNetworkReachability API. You can use the API synchronously, but do not issue a synchronous check by hostName on the main thread. If the device cannot reach a DNS server or is on a slow network, a synchronous call to the SCNetworkReachabilityGetFlags function can block for up to 30 seconds trying to resolve the hostName. If this happens on the main thread, the application watchdog will kill the application after 20 seconds of inactivity.

SCNetworkReachability API's do not currently provide a means to detect support for GameKit peer-to-peer networking over Bluetooth.



Main Files
==========

Reachability.{h,m}
 -Basic demonstration of how to use the SystemConfiguration Reachablity APIs.

APLViewController.{h,m}
- Simple view controller that displays information about network reachability.


=============================================
Copyright (C) Apple Inc. All rights reserved.

