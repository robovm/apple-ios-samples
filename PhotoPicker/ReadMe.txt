
PhotoPicker
===========

This sample demonstrates how to choose images from the photo library, take a picture using the device's camera, and how to customize the look of the camera's user interface.  This is done by using UIImagePickerController.  The chosen image or camera photo is displayed in a UIImageView.
To customize the camera's interface, this sample shows how to use an overlay view.  With this overlay view it gives you the ability to customize the UI as you take a picture.

Among the custom features of the camera is to take a single picture, timed picture, or repeated pictures like a camera with a fast shutter speed.  Timed and shutter speed camera shots are done using the NSTimer class.

Main classes
------------

APLViewController
Custom view controller that customizes and presents a UIImagePickerController object, and serves as the image picker's delegate. The view controller also displays the image or images taken by the image picker in an image view.

APLAppDelegate
The app delegate class used for managing the application's window and navigation controller.

===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.