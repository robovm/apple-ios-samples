Regions

================================================================================
ABSTRACT:

This sample demonstrates proper use of region monitoring, significant location changes, and handling location events in the background on iOS.
The sample uses an MKMapView that allows the user to add and remove regions to monitor, as well as a UITableView to display the region enter/exit/fail events that occur.
When the application goes into the background, location updates are stopped and significant location changes are started. Likewise, when the application enters the foreground, location updates are started again and significant location changes are stopped.
When location updates occur in the background, a badge is added to the homescreen icon displaying the number of region enter/exit/fail events logged.

================================================================================
BUILD REQUIREMENTS:

iOS 4.3 or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 4.0 or later. iPhone 4, iPad 2 Wifi + 3G or later.

================================================================================
PACKAGING LIST:

RegionsAppDelegate
The application delegate sets up the initial view and makes the window visible. It also handles events when the application goes into the background or enters the foreground.

RegionsViewController
This controller manages the CLLocationManager for location updates and switches the interface between showing the region map and the updates table list. This controller also manages adding and removing regions to be monitored by the application.

RegionAnnotation
This is a custom MKAnnotation with the addition of region and radius properties for ease of use when using region monitoring.

RegionAnnotationView
This is a custom MKAnnotationView that handles updating and removing the radius overlay to show where the region surrounding an annotation is.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Moved region re-adding logic into -viewDidAppear: due to timing issues.

Version 1.0
- First version.

================================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.