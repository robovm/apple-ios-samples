# LazyTableImages

This sample demonstrates a multi-stage approach to loading and displaying a UITableView. It displays the top paid iOS apps on Apple's App Store.

It begins by loading the relevant text from the RSS feed so the table can load as quickly as possible, then downloads the app icons for each row asynchronously so the user interface is more responsive.

## Packaging Pist

LazyTableAppDelegate.{h/m}
The app delegate class that downloads in the background the "Top Paid iOS Apps" RSS feed using NSURLSession.

AppRecord.{h/m}
Wrapper object for each data entry, corresponding to a row in the table.

RootViewController.{h/m}
UITableViewController subclass that builds the table view in multiple stages, using feed data obtained from the LazyTableAppDelegate.

ParseOperation.{h/m}
Helper NSOperation object used to parse the XML RSS feed loaded by LazyTableAppDelegate.

IconDownloader.{h/m}
Helper object for managing the downloading of a particular app's icon. It uses NSURLSession/NSURLSessionDataTask to download the app's icon in the background if it does not yet exist and works in conjunction with the RootViewController to manage which apps need their icon.

## Build Requirements
+ Xcode 7 or later
+ iOS 9.0 SDK or later

## Runtime Requirements
+ iOS 7.0 or later

Copyright (C) 2010-2015 Apple Inc. All rights reserved.