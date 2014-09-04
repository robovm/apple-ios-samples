### HazardMap ###

===========================================================================
DESCRIPTION:

The HazardMap sample demonstrates how to create a custom Map Kit overlay and corresponding view to display USGS earthquake hazard data on top of an MKMapView.

For more information on earthquake hazard data, see http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/.
This site includes 2008 NSHM Gridded Data files.

===========================================================================
BUILDING A HAZARD MAP:

This sample already comes with a gridded hazard map showing quake severity zones in North America, "UShazard.20081229.pga.5pc50.bin", and it is included in this Xcode project. You can create your own hazard maps by going to the USGS website, "http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/", and downloading another map.

"compactgrid"
This sample includes a command-line tool called "compactgrid". This is a standalone command line program to be run on OS X's Terminal utility that performs preprocessing to compact a USGS tab separated earthquake hazard grid file into a smaller binary format that is faster to load on devices.

To build the tool:
Select "compactgrid" as the active target in Xcode and select "Build" from the Build menu.
It requires the OS X SDK, not iOS SDK. If you experience build errors, that probably is due to having the wrong Active SDK selected for that target. In this case, hold the option-key and select either your "Overview" or "Active SDK" popup menus. Then proceed to select "OS X 10.6" and build again.

To run the tool:
1) navigate to the "Debug" or "Release" folders inside the "build" folder to find "compactgrid".
2) run the tool using Terminal as follows:

	compactgrid sourcehazardfile mygridfile.bin

note: "sourcehazardfile" is the map file you just downloaded from the USGS site, "mygridfile.bin" is the output file.
This tool will write a file called "mygridfile.bin" in the current directory.
You can name that file any way you like but be sure to include .bin extension.

To configure the new map into Xcode:
1) add the new .bin map file to your Xcode project in the "Resources" group.
2) open HazardMapViewController.m and change the "viewDidLoad" method to use that new file name.


===========================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0, Automatic Reference Counting (ARC)

===========================================================================
PACKAGING LIST:

HazardMap
- Custom MKOverlay model class representing USGS Earthquake hazard data.

HazardMapOverlayRenderer
- Custom MKOverlayRenderer class corresponding to the HazardMap model class. Demonstrates how to draw unprojected gridded data.

HazardMapViewController
- Implements MKMapView delegate and shows how to display the custom HazardMap overlay on an MKMapView.

UShazard.20081229.pga.5pc50.bin
- USGS Earthquake Hazard data fetched from http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/2008.US.pga.5pc50.txt.gz. This file has been compressed from the text version available directly from the USGS using compactgrid.c program included with the HazardMap sample project in order to reduce app launch time.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.2 - Upgraded for iOS 7.0 SDK: now uses MKOverlayRenderer, Storyboards, Automatic Reference Counting (ARC)
1.1 - Localized xib files, editorial changes.
1.0 - First version.

===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
