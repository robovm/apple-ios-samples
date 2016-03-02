/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A data object for storing context information relevant to how the app was launched.
*/

@import ListerKit;

@interface AAPLAppLaunchContext : NSObject

@property (nonatomic, strong, readonly) NSURL *listURL;
@property (nonatomic, readonly) AAPLListColor listColor;

/*!
    Initializes an \c AAPLAppLaunchContext instance with the color and URL provided.

    \param listURL
    The URL of the file to launch to.
    \param listColor
    The \c AAPLListColor of the file to launch to.
 */
- (instancetype)initWithListURL:(NSURL *)listURL listColor:(AAPLListColor)listColor;

/*!
    Initializes an \c AAPLAppLaunchContext instance with the color and URL designated by the user activity.

    \param userActivity
    The userActivity providing the file URL and list color to launch to.
    \param listsController 
    The listsController to be used to derive the URL available in the userActivty, if necessary.
*/
- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity listsController:(AAPLListsController *)listsController;

/*!
    Initializes an \c AAPLAppLaunchContext instance with the color and URL designated by the lister:// URL.

    \param listerURL
    The URL adhering to the lister:// scheme providing the file URL and list color to launch to.
*/
- (instancetype)initWithListerURL:(NSURL *)listerURL;

@end
