/*
     File: AssetBrowserController.h
 Abstract: UIViewController allowing asset selection.
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIViewController.h>
#import <UIKit/UITableView.h>

#import "AssetBrowserSource.h"

@protocol AssetBrowserControllerDelegate;

@class UITabBarController, UINavigationController;

@interface AssetBrowserController : UITableViewController
{
@private
	NSArray *assetSources;
	NSMutableArray *activeAssetSources;
	AssetBrowserSourceType browserSourceType;
	BOOL singleSourceTypeMode;
	BOOL haveBuiltSourceLibraries;
	
	id <AssetBrowserControllerDelegate> __weak delegate;
	
	BOOL thumbnailAndTitleGenerationIsRunning;
	BOOL thumbnailAndTitleGenerationEnabled;
	
	CGFloat lastTableViewYContentOffset;
	BOOL lastTableViewScrollDirection;
	
	CGFloat thumbnailScale;
	
	BOOL isModal;
	UIStatusBarStyle lastStatusBarStyle;
}

/* 
 AssetBrowserController is a UITableViewController subclass which can be used in a number of ways.
 In particular you can use it as a modal picker style view controller, or as a single view controller
 in a navigation heirarchy. When displaying an AssetBrowserController modally, make the AssetBrowserController
 the root of a UINavigationController then present that controller modally.
 
 An AssetBrowserController can show one or multiple sources. When using AssetBrowserController
 with UITabBarContoller you may wish to use one AssetBrowserController/source per tab.
 On iPad a picker style AssetBrowserController works nicely inside a UIPopover. Some convenience
 methods are provided below.
*/
- (id)initWithSourceType:(AssetBrowserSourceType)sourceType modalPresentation:(BOOL)modalPresentation;

- (void)clearSelection; // Used to clear the selection without dismissing the asset browser;

@property (nonatomic, weak) id<AssetBrowserControllerDelegate> delegate;

@end

@protocol AssetBrowserControllerDelegate <NSObject>
@optional

/* It is the delegate's responsibility to dismiss the view controller if it has been presented modally.
 If the view controller is part of a navigation heirarchy the client can push a new view controller
 in response to an asset being selected. */
- (void)assetBrowser:(AssetBrowserController *)assetBrowser didChooseItem:(AssetBrowserItem *)assetBrowserItem;
- (void)assetBrowserDidCancel:(AssetBrowserController *)assetBrowser;

@end

@interface UINavigationController (AssetBrowserConvenienceMethods)
// Has a navigation bar and a cancel button. Present the navigation controller modally.
+ (UINavigationController*)modalAssetBrowserControllerWithSourceType:(AssetBrowserSourceType)sourceType delegate:(id <AssetBrowserControllerDelegate>)delegate;
@end

@interface UITabBarController (AssetBrowserConvenienceMethods)
// Configured with one source per tab. Present the tab bar controller modally.
+ (UITabBarController*)tabbedModalAssetBrowserControllerWithSourceType:(AssetBrowserSourceType)sourceType delegate:(id <AssetBrowserControllerDelegate>)delegate;
@end
