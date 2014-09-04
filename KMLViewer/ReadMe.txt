### KMLViewer ###

===========================================================================
DESCRIPTION:

The KMLViewer sample application demonstrates how to use Map Kit's Annotations and Overlays to display KML (Keyhole Markup Language) files on top of an MKMapView.

KML is an open standard, so you can learn more about it at the Open Geospatial Consortium website:
http://www.opengeospatial.org/standards/kml

The Google documentation for KML is at this website:
http://code.google.com/apis/kml/

===========================================================================
BUILD REQUIREMENTS:

iOS SDK 5.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS OS 4.0

===========================================================================
PACKAGING LIST:

KMLParser
- A simple NSXMLParser based parser for KML files.  Creates both model objects for annotations and overlays as well as styled views for model and overlay views.

KMLViewerViewController
- Demonstrates usage of the KMLParser class in conjunction with an MKMapView.

KML_Sample.kml
- The sample KML file.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.3
- Editorial changes.

Version 1.2
- Fixed memory leak in KMLParser, editorial changes.

Version 1.1
- Localized xib files, editorial changes.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010-2012 Apple Inc. All rights reserved.
