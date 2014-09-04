PhotoScroller

===========================================================================
ABSTRACT

"PhotoScroller" demonstrates the use of embedded UIScrollViews and CATiledLayer to create a rich user experience for displaying and paginating photos that can be individually panned and zoomed.
CATiledLayer is used to increase the performance of paging, panning, and zooming with high-resolution images or large sets of photos.

===========================================================================
DISCUSSION

The PhotoViewController sets up the paging UIScrollView and uses an ImageScrollView for each page.
The ImageScrollView is a subclassed UIScrollView that is designed to allow panning and zooming of an image. 
The ImageScrollView also centers the image within the UIScrollView for an enhanced user experience.
The TilingView is a UIView that consists of a CATiledLayer appropriate for the current zoom scale of the ImageScrollView.
This ensures that performance is at its maximum, especially when using high-resolution images.

===========================================================================
SYSTEM REQUIREMENTS

iOS 6.0

===========================================================================
PACKAGING LIST

AppDelegate
Configures and displays the application window and initial view controller.

PhotoViewController
Configures and displays the paging scroll view and handles tiling and page configuration.

ImageScrollView
Centers image within the scroll view and configures image sizing and display.

TilingView
Uses a CATiledLayer to handle tile drawing.

ImageData.plist
Contains full-resolution image data.

===========================================================================
Copyright (C) 2010-2012 Apple Inc. All rights reserved.
