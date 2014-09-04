SeismicXML
==========

The SeismicXML sample application demonstrates how to use NSXMLParser to parse XML data.
When you launch the application it downloads and parses an RSS feed from the United States Geological Survey (USGS) that provides data on recent earthquakes around the world. It displays the location, date, and magnitude of each earthquake, along with a color-coded graphic that indicates the severity of the earthquake. The XML parsing occurs on a background thread and updates the earthquakes table view with batches of parsed objects.

It uses NSURLConnection to asynchronously download the data. This means the main thread will not be blocked - the application will remain responsive to the user.  When the app is sent to the background, the connection is cancelled.

The USGS feed is at http://earthquake.usgs.gov/eqcenter/catalogs/7day-M2.5.xml and includes all recent magnitude 2.5 and greater earthquakes world-wide, representing each earthquake with an <entry> element, in the following form:
 
<entry>
    <id>urn:earthquake-usgs-gov:us:2008rkbc</id>
    <title>M 5.8, Banda Sea</title>
    <updated>2008-04-29T19:10:01Z</updated>
    <link rel="alternate" type="text/html" href="/eqcenter/recenteqsww/Quakes/us2008rkbc.php"/>
    <link rel="related" type="application/cap+xml" href="/eqcenter/catalogs/cap/us2008rkbc"/>
    <summary type="html">
        <img src="http://earthquake.usgs.gov/images/globes/-5_130.jpg" alt="6.102&#176;S 127.502&#176;E" align="left" hspace="20" /><p>Tuesday, April 29, 2008 19:10:01 UTC<br>Wednesday, April 30, 2008 04:10:01 AM at epicenter</p><p><strong>Depth</strong>: 395.20 km (245.57 mi)</p>
    </summary>
    <georss:point>-6.1020 127.5017</georss:point>
    <georss:elev>-395200</georss:elev>
    <category label="Age" term="Past hour"/>
</entry>

NSXMLParser is an "event-driven" parser. This means that it makes a single pass over the XML data and calls back to its delegate with "events". These events include the beginning and end of elements, parsed character data, errors, and more. In this sample, the application delegate, an instance of the "SeismicXMLAppDelegate" class, also implements the delegate methods for the parser object. In these methods, Earthquake objects are instantiated and their properties are set, according to the data provided by the parser. For some data, additional work is required - numbers extracted from strings, or date objects created from strings. 


===========================================================================
Main Classes

APLViewController
A UITableViewController subclass that manages the table view; initiates the download of the XML data and parses the Earthquake objects at view load time.

APLParseOperation
The NSOperation class used to perform the XML parsing of earthquake data.

APLEarthquake
Simple model class to hold information about an earthquake.

===========================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.