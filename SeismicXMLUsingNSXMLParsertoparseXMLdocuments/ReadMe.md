# SeismicXML

## Description

The SeismicXML sample application demonstrates how to use NSXMLParser to parse XML data.
When you launch the application it downloads and parses an RSS feed from the United States Geological Survey (USGS) that provides data on recent earthquakes around the world. It displays the location, date, and magnitude of each earthquake, along with a color-coded graphic that indicates the severity of the earthquake. The XML parsing occurs on a background thread and updates the earthquakes table view with batches of parsed objects.

It uses NSURLSession to asynchronously download the data. This means the main thread will not be blocked - the application will remain responsive to the user.  When the app is sent to the background, the connection is cancelled.

The USGS feed is at "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.quakeml" and includes all recent magnitude 2.5 and greater earthquakes world-wide, representing each earthquake with an <event> element.  The QuakeML spec is defined at "https://quake.ethz.ch/quakeml/"."
 
NSXMLParser is an "event-driven" parser. This means that it makes a single pass over the XML data and calls back to its delegate with "events". These events include the beginning and end of elements, parsed character data, errors, and more. In this sample, the application delegate, an instance of the "SeismicXMLAppDelegate" class, also implements the delegate methods for the parser object. In these methods, Earthquake objects are instantiated and their properties are set, according to the data provided by the parser. For some data, additional work is required - numbers extracted from strings, or date objects created from strings. 

## Main Classes

APLViewController
A UITableViewController subclass that manages the table view; initiates the download of the XML data and parses the Earthquake objects at view load time.

APLParseOperation
The NSOperation class used to perform the XML parsing of earthquake data.

APLEarthquake
Simple model class to hold information about an earthquake.

## Requirements

### Build

iOS 9.0 SDK or later

### Runtime

iOS 8.0 or later.

Copyright (C) 2008-2015 Apple Inc. All rights reserved.