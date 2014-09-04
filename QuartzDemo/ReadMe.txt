
QuartzDemo
==========

QuartzDemo is an iOS application that demonstrates many of the Quartz2D APIs made available by the CoreGraphics framework. Quartz2D forms the foundation of all drawing on iPhone OS and provides facilities for drawing lines, polygons, curves, images, gradients, PDF and many other graphical facilities.

In this sample stroked paths are typically drawn in white. Lines and other graphical elements drawn in red are meant to show some aspect of how the element was constructed, such as the path used to construct the object, or a clipping rectangle used to limit drawing to a particular area and are not part of the actual demonstrated result. Filled paths and areas use colors other than red, with a red fill used to similar effect as with stroked paths.

Source File List
----------------
Classes/QuartzView.h/m:
A UIView subclass that is the super class of the other demonstration views in this sample.

Classes/QuartzBlendingViewController.h/m:
A QuartzViewController subclass that manages a QuartzBlendingView and a UI to allow for the selection of foreground color, background color and blending mode to demonstrate.

Classes/QuartzPolyViewController.h/m:
A QuartzViewController subclass that manages a QuartzPolygonView and a UI to allow for the selection of the stroke and fill mode to demonstrate.

Classes/QuartzGradientController.h/m:
A QuartzViewController subclass that manages a QuartzGradientView and a UI to allow for the selection of gradient type and if the gradient extends past its start or end point.

Classes/QuartzLineViewController.h/m:
A QuartzViewController subclass that manages a QuartzCapJoinWidthView and a UI to allow for the selection of the line cap, line join and line width to demonstrate.

Classes/QuartzDashViewController.h/m:
A QuartzViewController subclass that manages a QuartzDashView and a UI to allow for the selection of the line dash pattern and phase.

Quartz/QuartzLines.h/m:
Demonstrates Quartz line drawing facilities (QuartzLineView), including dash patterns (QuartzDashView), stroke width, line cap and line join (QuartzCapJoinWidthView).

Quartz/QuartzPolygons.h/m:
Demonstrates using Quartz to stroke & fill rectangles (QuartzRectView) and polygons (QuartzPolygonView).

Quartz/QuartzCurves.h/m:
Demonstrates using Quartz to draw ellipses & arcs (QuartzEllipseArcView) and bezier & quadratic curves (QuartzBezierView).

Quartz/QuartzImages.h/m:
Demonstrates using Quartz for drawing images (QuartzImageView), PDF files (QuartzPDFView), and text (QuartzTextView).

Quartz/QuartzRendering.h/.m:
Demonstrates using Quartz for drawing gradients (QuartzGradientView) and patterns (QuartzPatternView).

Quartz/QuartzBlending.h/.m:
Demonstrates Quartz Blend modes (QuartzBlendingView).

Quartz/QuartzClipping.h/m:
Demonstrates using Quartz for clipping (QuartzClippingView) and masking (QuartzMaskingView).

_______________________________________________________
Copyright (C) 2008-2013 Apple Inc. All rights reserved.
