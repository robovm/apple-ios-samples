# EKLocationReminders
EKLocationReminders demonstrates how to add, fetch, and remove location-based reminders using EKReminder, EKAlarm, EKAlarmProximity, and EKStructuredLocation. 
It shows how to set up geofences for reminders and fires alarms when entering or exiting within a given radius of an area. It consists of the Map and List views. 
Provide access to Reminders and Location Services when prompted upon launching the app. Doing so ensures that you would be reminded when arriving or leaving your 
reminders' location. Navigate to List to view all your reminders.


## Requirements

### Build

iOS SDK 9.1 or later

### Runtime

iOS 8.0 or later



## Usage
This sample requires access to Reminders and Location Services. 
The accessGrantedForLocationServices method of the MapViewController class uses data from the Locations.plist file to create annotations for Map. 
Locations.plist includes an array of dictionaries that each represents the title, latitude, longitude, and address information of an annotation. 
Additionally, accessGrantedForLocationServices adds the current user location to Map. Update this file with data formatted as described above if 
you wish to test reminders around other locations. Note that you can obtain latitude and longitude information of an annotation or region in your app 
by following these steps:
1) Implement 
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated


2) Zoom or pan to the area you want in Map, then set a breakpoint there to obtain information about the region.

3) Display the latitude, longitude, and delta information by executing po mapview.region in the debugger.


Copyright (C) 2015 Apple Inc. All rights reserved.