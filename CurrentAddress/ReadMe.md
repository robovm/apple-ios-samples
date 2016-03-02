# Current Address

## Abstract

Demonstrates basic use of MapKit with CLGeocoder, displaying a map view and setting its region to current location.

It makes use of the CLGeocoder class that provides services for converting your map coordinate (specified as a latitude/longitude pair) into information about that coordinate, such as the country, city, or street. A reverse geocoder object is a single-shot object that works with a network-based map service to look up placemark information for its specified coordinate value.  To use placemark information is leverages the MKPlacemark class to store this information.

## Discussion

The MapViewController class and MainStoryboard.storyboard encapsulate all the interactions with the map view. These files are a good place to start to see how to set the region and map type of an MKMapView object.

## Setup

In the project editor, open the General pane and change the following:
1) Change the bundle identifier under Identity.
2) Select the appropriate "Team" for your target.

## Running the Sample

If running this sample in the iOS Simulator, enable location simulation in Xcode from the Debug > Simulate Location menu.

## Build Requirements

iOS 8.0 SDK

## Runtime Requirements

iOS 8.0 or later


Copyright (C) 2009-2015 Apple Inc. All rights reserved.
