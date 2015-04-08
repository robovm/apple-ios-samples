# Customizing UINavigationBar #

NavBar demonstrates using UINavigationController and UIViewController classes together as building blocks to your application's user interface.  Use it as a reference when starting the development of your new application.  The various pages in this sample exhibit different ways of how to modify the navigation bar directly, using the appearance proxy, and by modifying the view controller's UINavigationItem.  Among the levels of customization are varying appearance styles, and applying custom left and right buttons known as UIBarButtonItems.

#### Custom Right View ####

This example demonstrates placing three kinds of UIBarButtonItems on the right side of the navigation bar: a button with a title, a button with an image, and a button with a UISegmentedControl.  An additional segmented control allows the user to toggle between the three.  The initial bar button is defined in the storyboard, by dragging a Bar Button Item out of the object library and into the navigation bar.  CustomRightViewController.m also shows how to create and add each button type using code.

    NOTE: At the time of writing, Xcode (6.1) does not allow you to add multiple bar button items to either side of a navigation bar in a storyboard.  See the comments in CustomRightViewController.m for a description of how to workaround this.

#### Custom Title View ####

This example demonstrates adding a UISegmentedControl as the custom title view (center) of the navigation bar.

#### Navigation Prompt ####

This example demonstrates customizing the 'prompt' property of a UINavigationItem to display a custom line of text above the navigation bar.

#### Extended Navigation Bar ####

This example demonstrates placing a custom view underneath the navigation bar in such a manner that view appears to be part of the navigation bar itself.  This technique may be used to create an interface similar to the iOS Calendar app.
    
#### Custom Appearance ####

This example demonstrates customizing the background of a navigation bar, applying a custom bar tint color or background image.
    
#### Custom Back Button ####

This example demonstrates using an image as the back button without any back button text and without the chevron that normally appears next to the back button.

#### Custom Navigation Bar ####

This example demonstrates using your own UINavigationBar subclass as the navigation bar of a UINavigationController.

## Using the sample ##

The sample launches to a list of examples, each focusing on a different aspect of customizing the navigation bar.

#### Bar Style ####
Click the "Style" button to the left of the main page to change the navigation bar's style or UIBarStyle.   This will take you to an action sheet where you can change the background's appearance (default, black-opaque, or black-translucent).

    NOTE: A navigation controller determines its preferredStatusBarStyle based upon the navigation bar style.  This is why the status bar always appears correct after changing the bar style, without any extra code required.


REQUIREMENTS
--------------------------------------------------------------------------------

### BUILD ###
Xcode 6 or later

### RUNTIME ###
iOS 7.0 or later


PACKAGING LIST
--------------------------------------------------------------------------------

**AppDelegate**: The application delegate class.
    
**NavigationController**: A UINavigationController subclass that always defers queries about its preferred status bar style and supported interface orientations to its child view controllers.
    
**MainViewController**: The application's main (initial) view controller.

**CustomRightViewController**: Demonstrates configuring various types of controls as the right bar item of the navigation bar.
    
**CustomTitleViewController**: Demonstrates configuring the navigation bar to use a UIView as the title.
    
**NavigationPromptViewController**: Demonstrates displaying text above the navigation bar.
    
**ExtendedNavBarView**: A UIView subclass that draws a gray hairline along its bottom border, similar to a navigation bar.  This view is used as the navigation bar extension view in the Extended Navigation Bar example.
    
**ExtendedNavBarViewController**: Demonstrates vertically extending the navigation bar.
    
**CustomAppearanceViewController**: Demonstrates applying a custom background to a navigation bar.
    
**CustomBackButtonNavController**: UINavigationController subclass used for targeting appearance proxy changes in the Custom Back Button example.
    
**CustomBackButtonDetailViewController**: The detail view controller in the Custom Back Button example.
    
**CustomBackButtonViewController**: Demonstrates using a custom back button image with no chevron and not text.


CHANGES FROM PREVIOUS VERSIONS:
--------------------------------------------------------------------------------

+ Version 6.0
    - Updated for iOS 8, the iPhone 6, and the iPhone 6 Plus.
    - Added a 'Custom Navigation Bar' example.

+ Version 1.12
    - Updated for iOS 7.
    - Expanded the number of examples.

+ Version 1.11 
    - Upgraded Xcode project for iOS 5.0,.
    - Removed all compiler warnings/errors.

+ Version 1.9 
    - Upgraded project to build with the iOS 4.0 SDK.

+ Version 1.8 
    - Upgraded for 3.0 SDK due to deprecated APIs.
    - In "cellForRowAtIndexPath" it now uses UITableViewCell's initWithStyle. 
    - Now uses viewDidUnload.

+ Version 1.7 
    - Updated for and tested with iPhone OS 2.0. 
    - First public release.

+ Version 1.6 
    - Changed bundle identifier.

+ Version 1.5 
    - Beta 6 Release.
    - Minor UI improvements.

+ Version 1.4 
    - Updated for Beta 5.
    - changes to UITableViewDelegate.
    - Upgraded to use xib files for each UIViewController.

+ Version 1.3 
    - Updated for Beta 4.
    - Changed to use Interface Builder xib file.

+ Version 1.2 
    - Updated for Beta 3: reusable UITableView cells.
    - Added new use of UIViewController "presentModalViewController".

+ Version 1.1 
    - Minor update to the latest SDK API changes.

+ Version 1.0 
    - First release.


================================================================================
Copyright (C) 2008-2015 Apple Inc. All rights reserved.
