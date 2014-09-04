### Blurring and Tinting an Image ###

===========================================================================
DESCRIPTION:

UIImageEffects demonstrates how to create and apply blur and tint effects to an image using the vImage, Quartz, and UIKit frameworks. The vImage framework is suited for high-performance image processing. Using vImage, your app gets all the benefits of vector processing without the need for you to write vectorized code.


USING THE SAMPLE:

1. Launch the UIImageEffects project using Xcode 5.
2. Make sure the project's current target is set to UIImageEffects.
3. Build and run the UIImageEffects target.
4. Tap the device screen (or click the simulator screen) to cycle through the effects.

You’ll notice that the app is very responsive despite the calculation-intense blur effects.


===========================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later


===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later


===========================================================================
PACKAGING LIST:

UIImageImageEffects.{h,m}
    - This class contains methods to apply blur and tint effects to an image.  This is the code you’ll want to look out to find out how to use vImage to efficiently calculate a blur.

APLViewController.{h,m}
    - Loads the view and updates the image. 


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- First public release.
- Now uses vImageBuffer_InitWithCGImage/vImageCreateCGImageFromBuffer to move image data between CGImage and vImage.

Version 1.0
- First version.


===========================================================================
Copyright (C) 2013-2014 Apple Inc. All rights reserved.
