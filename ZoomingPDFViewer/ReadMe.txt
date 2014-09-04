### ZoomingPDFViewer ###

===========================================================================
DESCRIPTION:

Multi-paged PDF viewing with UIPageViewController demonstrates two-page spline viewing in landscape orientation, which looks like a book within iBooks. The sample also uses UIScrollView and CATiledLayer to support zooming within a single-page view used in portrait orientations. This app is universal and only supports the two-page spline view in landscape orientation on iPad.

FAQ: 

* Why does this sample swap out the scrollview's embedded CATiledLayer-backed subview on every didEndZoom event?

Swapping out the scrollview's tiledlayer-backed subview on every didEndZooming event allows this implementation to support essentially an "infinite" zoom scale. This is great for vector-based PDF's like blue prints or maps. The trade off is that infinite zooming is by default support in both directions, and infinite zooming out is not usually desired.

* How do I clamp zooming in and out to maximum and minimum zoom scales?

To clamp zooming in and out to a defined minimum and maximum scale, remove the code that swaps in and out the tiledlayer-backed subview on the scrollview's didEndZooming event. Doing so will reenable the minimumZoomScale and maximumZoomScale properties of the UIScrollView. The swapping in and out of the scrollview's subview was done purposesfully to bypass minimum and maximum zoom scales as a way to support "infinite" zooming in (which is great for detailed vector based PDFs).

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 3.1
- Readme revisal to explain the "infinite" zooming implementation. Two display based bug fixes.

Version 3.0
- Now leverages UIPageViewController to support multi-page viewing.

Version 2.0
- Updated to use ARC and storyboards.
- Corrected the value of the tiled layer's levelsOfDetailBias to work correctly with high resolution devices.
 
Version 1.0
- First version.
 
===========================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
