### LargeImageDownsizing ###

===========================================================================
DESCRIPTION:

This code sample demonstrates a way to support displaying very large images in limited memory environments by turning a large image on disk into a smaller image in memory. This is useful in situations where the original image is too large to fit into memory as required for it to be displayed.

Having useful implications in supporting user defined documents, it should be noted that the photo roll or document sharing drop are the locations that a large image would exist. For simplicity this sample reads a large image from the bundle. 

Supported formats are: PNG, TIFF, JPEG. Unsupported formats: GIF, BMP, interlaced images.

Note: constants are defined in LargeImageDownsizingViewController.m that are stable yet reasonably performant given memory availability for those individual iOS devices. Therefore, you may need to adjust these settings before running on your device. 

The constants demonstrate parameters to the algorithm and are intended as initial/sample values only. In your application, reasonable values could be chosen at runtime based on the hardware profile of the target device, and the amount of memory taken by the rest of your application. 
 
===========================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS OS 6.0 or later

===========================================================================
PACKAGING LIST:

View Controllers
----------------
 
LargeImageDownsizingViewController.h, .m
The main view controller of the application. It kicks off the downsizing routine and updates an image view 
showing the current progress as the resulting image is pieced together. When the downsize completes, the image 
view is swapped out for a scroll view that contains the resulting image to allow for zooming and panning to 
inspect the levels of detail of the resulting image.
 
Views
----------------
ImageScrollView.h, .m
Subclass of UIScrollView that contains the large image and provides built in support for zooming and scrolling.

TiledImageView.h, .m
Subclass of UIView with layerClass method overridden to return a CATiledLayer. This provides built in support for tile-based rendering.
 
Application Entry point
-------------------------
LargeImageDownsizingAppDelegate.h, .m
Installs the main view controller.
 
MainWindow.xib
Loaded automatically by the application. Creates the application's delegate, window, and superview.
 
===========================================================================
CHANGES FROM PREVIOUS VERSIONS:
 
Version 1.0
- First version.

Version 1.1
- Updated for iOS 7 SDK. 
 
===========================================================================
Copyright (C) 2011-2014 Apple Inc. All rights reserved.
