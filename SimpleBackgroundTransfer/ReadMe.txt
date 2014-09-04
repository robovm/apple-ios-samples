
SimpleBackgroundTransfer
========================

SimpleBackgroundFetch is a simple app that illustrates how to use background transfers.


Running the Sample
------------------

The sample downloads an image defined in APLViewController.m by:
    NSString *DownloadURLString
To run this sample correctly, you must specify an appropriate URL.

If you do not have access to a convenient web server, you can start one on your OS X system. In Terminal, type the following:
    sudo launchctl load -w /System/Library/LaunchDaemons/org.apache.httpd.plist

You can then put whatever files you want to test with in
    /Library/WebServer/Documents/

and access them in Simulator via:
    http://localhost/


To see the background operation in progress you should ensure that the transfer takes a non-trivial length of time, either by downloading a sufficiently large image, or by specifying a remote URL with network latencies.



Note that this app does not require a Background Mode capability.


==================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
