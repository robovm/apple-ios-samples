# footprint: Indoor Location with Core Location

Display device location on a floorplan image.
Using Core Location, we will take the position in Latitude/Longitude and project it onto a flat floorplan. We will demonstrate how to do the conversion from the Geographic coordinates system (Latitude/Longitude) to the floorplan's image coordinate system (x,y)

Note: For this sample to function, you must have a floorplan for a venue that is Indoor Positioning enabled. To see the the apporpriate position on the floorplan, the device will need to be in that venue. If you are not in a venue, you must emulate a position in the venue using "Custom Location" in the simulator.

## Using Your Own Floorplan
If you have a venue floorplan you would like to use, make the following changes:

1) Replace the existing FLOORPLAN_IMAGE in the image Assets
2) Set the two anchor points in AAPLViewController.h: These are two points on the floorplan in Latitude/Longitude, and Image x,y

## Requirements
iOS 8 or later

Copyright (C) 2014 Apple Inc. All rights reserved.
