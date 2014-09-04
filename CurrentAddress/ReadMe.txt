Current Address

===========================================================================
ABSTRACT

Demonstrates basic use of MapKit with CLGeocoder, displaying a map view and setting its region to current location.

It makes use of the CLGeocoder class that provides services for converting your map coordinate (specified as a latitude/longitude pair) into information about that coordinate, such as the country, city, or street. A reverse geocoder object is a single-shot object that works with a network-based map service to look up placemark information for its specified coordinate value.  To use placemark information is leverages the MKPlacemark class to store this information.

===========================================================================
DISCUSSION

The MapViewController class and MapViewController.xib encapsulate all the interactions with the map view. These files are a good place to start to see how to set the region and map type of an MKMapView object. 

===========================================================================
BUILD REQUIREMENTS

iOS 7.0 SDK

===========================================================================
SYSTEM REQUIREMENTS

iOS 6.1 or later

===========================================================================
Copyright (C) 2009-2013 Apple Inc. All rights reserved.
