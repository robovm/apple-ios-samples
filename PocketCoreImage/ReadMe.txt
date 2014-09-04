### PocketCoreImage ###


DESCRIPTION:

This sample demonstrates applying Core Image filters to a still image.  The filter configuration is done automatically (using random numbers) and multiple filters may be applied at the same time.  While this sample uses a preset list of filters that the user may select from, code is provided in the next section which demonstrates asking the system for a list of filters.

ABOUT:

- Retrieving the filter list
The list of filters is created inside -awakeFromNib.  For simplicity, four filters have been manually specified however it is possible to query the system for a list of installed filters.  The following code shows how this would be accomplished:
{
    return [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryBuiltIn]];
}

Installed filters are also grouped by categories and it is possible to request only the filters in a certain category.  Specifying multiple categories in a request to -filterNamesInCategories returns the intersection of the set of filters in those categories.  There is no way to retrieve the union of the sets of filters in two categories other than to merge the result of two requests for individual categories.  The following code shows how to get filters in both the Color Effect and Color Adjustment categories.
{
    NSArray *installedFilters = [CIFilter filterNamesInCategories:[NSArray arrayWithObjects:kCICategoryBuiltIn, kCICategoryColorEffect, nil]];
    installedFilters = [installedFilters arrayByAddingObjectsFromArray:
                       [CIFilter filterNamesInCategories:[NSArray arrayWithObjects:kCICategoryBuiltIn, kCICategoryColorAdjustment, nil]]];
    return installedFilters;
}
    * A list of keys for the categories can be found at <http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/QuartzCoreFramework/Classes/CIFilter_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40003960-RH2-DontLinkElementID_1>
    
    * A complete list of Apple provided Core Image Filters may be found at. <http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/uid/TP40004346> (NOTE: Not all filters listed here are available on iOS).  
    
- Configuring the filter(s)
Most filters include various parameters that can be configured to alter the output image.  An instance of a filter can be queried about its information and parameters it offers by calling -attributes.  You may also instruct an instance of CIFilter to configure itself with author specified defaults by calling -setDefaults.

For this sample, we have defined a method +(void)configureFilter:(CIFilter*)filter which takes an instance of a CIFilter, inspects its available parameters and configures them with random values.  The techniques shown in this method could easily be used to implement a dynamic user interface that allows the user to configure the filter.

- Applying the filter(s) to an input image
Our controller manages an NSArray of CIFilter instances.  When the FilteredImageView needs to draw itself, it requests this list of filters and applies each filter successively its input image.


===========================================================================
BUILD REQUIREMENTS:

Xcode 4.2, iOS SDK 5

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5

===========================================================================
PACKAGING LIST:

FilteredImageView.m/h
UIView subclass.  Requests a list of filters from its data source and applies them
to its input image, drawing the resulting image to the screen.

MainViewController.m/h
Contains logic for the UI.  Manages the filtered image view and list of filters.

FilterDetailCategory.m
A category of the MainViewController class.  Implements methods for configuring a
filter's parameters with randomly generated values.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.