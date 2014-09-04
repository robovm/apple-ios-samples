XMLPerformance

===========================================================================
ABSTRACT

This sample explores two approaches to parsing XML, focusing on performance with respect to speed, memory footprint, and user experience. The XML data used is the current "Top 300" songs from the iTunes store. The data itself is not particularly important to the sample - it was chosen because of its simplicity, availability, and because the size (approximately 850KB) is sufficient to demonstrate the performance issues central to the sample.

===========================================================================
DETAILED DESCRIPTION

The iPhone SDK provides two APIs for parsing XML. At the Objective C level, NSXMLParser implements an event-driven approach with a delegate object implementing methods for handling each of the "events" the parser encounters during its single pass over the XML data. Events most commonly of interest are the beginning and ending of elements and character data within elements. The other API in the SDK, the C library "libxml2", has a similar approach known as SAX ("Simple API for XML"). Because it is C, callback functions are used instead of delegate methods, and the parameters are C strings instead of NSString objects. 

This sample allows the user to choose between these two approaches for parsing a simple RSS feed. The feed, iTunes' "Top 300" songs, is parsed into an array of "Song" objects displayed in a table. Details about a song can be viewed by selecting the song. The sample also tracks statistics related to the parse: the amount of time required to download the data, and the amount of time spent parsing the data. These statistics are stored in a SQLite database in the application's Documents directory, and the average (mean) of all runs with each parser can be viewed in a table. 

The process for linking and using libraries is slightly more complex than the same process for frameworks. The primary consideration is making it possible for the compiler to find the header file(s) associated with the library. With a framework, the executable code and header files are packaged together in a way that Xcode understands and placed in locations that Xcode has knowledge of via the SDK. Library header files, on the other hand, are typically found in a different location than the executable itself. Though they are still part of the SDK, it is necessary to specify the location in the project build settings. We use the "Header Search Paths" setting for this purpose. The SDKROOT variable should prefix the path as the location where the SDK is installed or the SDK versions available may differ. For this project, the setting is:

HEADER_SEARCH_PATHS = $SDKROOT/usr/include/libxml2

===========================================================================
PERFORMANCE

The focus of this sample is performance. There are three areas of concern: speed, memory, and user experience. For applications dealing with small amounts of XML data, none of these may be significant. In this case, developers should use the API with which they are most comfortable. For most developers, this will be the NSXMLParser API in the Foundation framework. 

For large datasets, developers should test their application with an iPhone or iPod touch and evaluate the application's performance with respect to speed, memory, and user experience. It's important that this be done with a device and not with the iPhone Simulator because the Simulator does not accurately reflect the memory and processor constraints. The techniques implemented in this sample can help the developer improve performance and memory usage, if it's determined that such a need exists.

Memory:

NSXMLParser be used with either a NSURL or a NSData. In both cases, all of the XML data is loaded into memory. On iOS, this can be a very significant consideration. The actual parsing will require additional memory, particularly with intermediate objects created and autoreleased.

With libxml, you can parse XML data in chunks. This alleviates the need to have all of the data in memory at one time, possibly resulting in a considerably smaller memory footprint. This could be applied to data downloaded using NSURLConnection. The NSURLConnection delegate method connection:didReceiveData: may be called multiple times during a download, and rather than accumulate the data, it can be immediately passed to the libxml parser. When the parser is finished, the data can be discarded. In addition, libxml callbacks use C strings rather than Objective C objects. In general, the overhead for objects is not significant, but in large numbers, in tight loops, this adds up. In particular, when the character data in an XML element is parsed, that data is delivered as one or more parse "events". For NSXMLParser, these events result as the delegate method parser:foundCharacters:, with an autoreleased NSString as the container for the character data. In libxml, the events call in the registered callback function, passing a pointer to a C string buffer. This offers another opportunity to optimize on memory management. Rather than creating an object with each call of the function, the character data can be accumulated in a separate buffer, until all data for the current XML element has been handled. Only at that point does a NSString object need to be created.

Speed:

Speed is obviously important to users, as waiting for long operations to complete is not a good experience. In addition, speed is an indirect reflection of processor load, which is in turn tied to power consumption. Hence, an more rapidly executing code path not only provides a better user experience with the application itself, it consumes less power, leading to longer battery life and a better experience for the overall device. 

User Experience:

At times CPU and/or IO intensive operations cannot be avoided. A positive user experience can still be provided in these cases by offloading work to separate threads, using NSThread, NSOperation, or lower level threading APIs such as POSIX threads(pthreads). This sample involves both lengthy IO (downloading the XML data) and CPU intensive work (parsing the XML). To keep the interface responsive, this work is done in a secondary thread. Periodically, the secondary thread updates the primary thread with the results of the work it has done. In turn, the user interface displays the new data to the user. If this approach were not used, the user would experience 3 or more seconds in which the application would appear to hang while the data was being downloaded and parsed.

Metrics:

This sample includes some screenshots and a sample trace document from Instruments. The first screenshot, "StatisticsScreenshot.png", is captured from the application, showing the statistics that might be seen after running each parser several times. The second, "ObjectAllocScreenshot.png", shows the Instruments window with one run from each parser. The top run is a run with the LibXMLParser. Note the significantly smaller peak memory usage. In addition, the trace document itself, included as a zipped archive, can be opened and examined. 

===========================================================================
SYSTEM REQUIREMENTS

Xcode 4.6, iOS 6.0 SDK

===========================================================================
PACKAGING LIST

AppDelegate
Adds the main UITabBarController's view to the application's window.

ParserChoiceViewController
Provides an interface for choosing and running one of the two available parsers. 

SongsViewController
Creates and runs an instance of the parser type chosen by the user, and displays the parsed songs in a table. Selecting a row in the table navigates to a detail view for that song. 

DetailViewController
Displays details of a single parsed song.

Song
Contains the parsed information about a song.

iTunesRSSParser
Base class for the two parsers, this class handles interactions with a delegate object (the SongsViewController in this sample) and provides basic functionality common to both parsers.

LibXMLParser
Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.

CocoaXMLParser
Subclass of iTunesRSSParser that uses the Foundation framework's NSXMLParser for parsing the XML data.

StatsViewController
Displays statistics about each parser, including its average time to download the XML data, parse it, and the total average time from beginning the download to completing the parse.

Statistics
Collection of C functions for database storage of parser performance metrics. These functions manage all interactions with the SQLite database, including both writes to the database and queries for aggregate statistics about the measurements. 

main.m
Launches the application.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

1.4 - Fixed auto release pool crasher bug, updated to adopt current best practices for Objective-C, now using Automatic Reference Counting (ARC), slightly improved UI.
1.3 - Minor updates for iOS 4.0.
1.2 - Fixed a memory leak in LibXMLParser implementation of the NSURLConnection delegate method -connectionDidFinishLoading:. Improved autorelease pool management in Cocoa parser.
1.1 - Updated user interface for iPhone SDK 3.0 and fixed bug in Xcode build setting for header search paths.
1.0 - Initial version published.

===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
