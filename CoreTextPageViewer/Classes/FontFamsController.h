
/*
     File: FontFamsController.h
 Abstract: A table view controller to manage and display a list of font families to use.
 The view controller manages one array that contains the set of fontFams the app can show
 and the associated font features, in fontFamsForDisplay.
 The table view displays the contents of the fontFamsForDisplay array.
 The view controller has a delegate that it notifies if row in the table view is selected.
 
  Version: 1.1
 
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

#import <UIKit/UIKit.h>


@class FontFamsController;

// Delegate protocol for communicating popover results back to root
@protocol FontFamsDelegate <NSObject>
// Sent when the user selects a row in the font list.
- (void)fontFamsController:(FontFamsController *)controller didSelectString:(NSString *)fontFamilyName;
// Sent when the user selects a row in the font features list.
- (void)fontFamsController:(FontFamsController *)controller didSelectFeaturesString:(NSString *)fontFeatureName;
@end


@interface FontFamsController : UITableViewController <UIActionSheetDelegate> {
    id <FontFamsDelegate> delegate;            // our delegate    
    NSArray              *fontFamsForDisplay;  // list of font families shown in UI
	NSString             *selectedFontFam;     // currently selected font family (if any)
	NSUInteger            selectedFontFeature; // current selected font feature (if any)
}

@property (nonatomic, assign) id <FontFamsDelegate> delegate;
@property (nonatomic, retain) NSArray *fontFamsForDisplay;
@property (nonatomic, retain) NSString *selectedFontFam;
@property (nonatomic, assign) NSUInteger selectedFontFeature;

// Helper method to unselect all fonts in the UI -- used when the user switches samples
- (void)deselectAllFonts;

@end
