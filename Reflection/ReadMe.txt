Reflection
==========
This sample shows how to implement a "reflection" special effect on a given UIImageView most commonly seen in iTunes and iPod player apps.
It allows the rendering effect with "dynamic" input values for 1) reflection height and 2) translucency level.  These values can be plugged into the factory methods provided by this sample to achieve a desired affect.

This sample implements a UIImageView and programmatically builds a "reflection" image view below it using CoreGraphics.  Essentially it builds the reflection using a combination of CGContextRef, CGImageRef and CALayer to do the desired rendering.

The main entry method in creating the reflected image is -

- (UIImage *)reflectedImage:(UIImageView *)fromImage withHeight:(NSUInteger)height;

So you would assign the image to a UIImageView and set its alpha value like so -

reflectionView.image = [self reflectedImage:imageView withHeight:reflectionHeight];
reflectionView.alpha = 0.50;


Build Requirements
iOS 7.0 SDK


Runtime Requirements
iOS 7.0 or later


Using the Sample
Build and run the sample using Xcode. To run in the simulator, set the Active SDK to Simulator. To run on a device, set the Active SDK to the appropriate Device setting.

When launched, use the two sliders at the bottom to adjust the size and translucency or alpha values of the reflection.  These two values range from 0.0 to 1.0.  The slider values are displayed to the right.  You can use these values by plugging them into the methods that generate the desired reflection effect.


Packaging List
main.m - Main source file for this sample.
AppDelegate.h/.m - The application's delegate to setup its window and content.
MyViewController.h/.m - The main UIViewController containing a the UIImageView and its reflection.
SliderCell.h/.m - UITableViewCell to host a slider, its label and value.


Changes from Previous Versions
1.8 - Updated to use Storyboards instead of XIBs.
1.7 - Minor change to fix a warning related to the Architectures build setting.
1.6 - Upgraded for iOS 5.0, now using Automatic Reference Counting (ARC)
1.5 - Changed deployment target back to iPhone OS 3.2 and added CFBundleIconFiles in Info.plist.
1.4 - Upgraded project to build with the iOS 4 SDK.
1.3 - Minor efficiency improvements, editoral fixes.
1.2 - Fixed a memory leak in CreateGradientImage.
1.1 - Updated to use iPhone 3.0 table cell styles. Fixed an error when reflection height was 0;
1.0 - first release


Copyright (C) 2008-2014 Apple Inc. All rights reserved.