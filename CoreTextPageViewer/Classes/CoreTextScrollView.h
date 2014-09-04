/*
     File: CoreTextScrollView.h
 Abstract: Manages the display of pages for a given document to display. This is the view that you will use in Interface Builder or create directly to display and interact with an AttributedStringDoc in an application. 
 It is also fair to say that this view acts as a controller for CoreTextViews. You can change the page to display, manage text selection, and change font parameters for the document.

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
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "AttributedStringDoc.h"

#define AUTO_RELEASED_CTREF(CTValue)  ((void*)[(id)(CTValue) autorelease])

extern NSString* const ASYNC_TOGGLE_STRING;

// Enum for CoreTextView feature option bit flags
enum  {
	CoreTextViewOptionsDefault = 0,

	// bits 0 - 15 are used for features hand have the same meaning as ASDFeaturesBits
	CoreTextViewOptionsFeatureMask = 0xFF
		
};
typedef NSUInteger CoreTextViewOptionsBits;

@class CoreTextViewDraw;
@class CoreTextView;

@interface CoreTextScrollView : UIScrollView {
@private
	AttributedStringDoc  *document; // document text contents
	
	CoreTextView         *pageViews[4]; // previous, current, next, scratch 
	NSMutableDictionary  *pagesInfo;

	NSInteger             pageDisplayed;
	NSInteger             pageCount;
    
    NSMutableArray       *selectionRanges;
    	
	CoreTextViewOptionsBits viewOptions;
	
	NSOperationQueue     *operationQueue; // for rendering pages on second thread
}

// Change to next/previous page
- (void)pageUp;
- (void)pageDown;

// Re-layout text for whole document
- (void)relayoutDoc;   

// Redraw currently displayed page on load (does not re-layout text)
- (void)refreshPage;

// Redraw all pages on load (does not re-layout text), used for highlighting
- (void)refreshDoc;     

// Mark page as needing refresh on next load
- (void)pageNeedsDisplay:(NSInteger)pageNumber;

// Set currently displayed page
- (void)setPage:(NSInteger)pageToDisplay;

// Get page for given document text string offset
- (NSInteger)pageForStringOffset:(NSUInteger)offset;

// Get document text string range for current page
- (NSRange)stringRangeForCurrentPage;

// NSObject:description override (returns document name)
- (NSString *)description;

// Reset scroll view with new document and delegate
- (void)reset:(AttributedStringDoc*)theDoc withDelegate:(id)scrollViewDelegate;

// Selection handling (for user frame selections)
- (void)addSelectionRange:(NSRange)range;
- (void)clearSelectionRanges;

// Change document with overriding font/font features
- (void)fontFamilyChange:(NSString*)fontFamilyName;
- (void)optionsChange:(NSString*)optionName;

@property (nonatomic, retain, readonly) AttributedStringDoc* document;
@property (nonatomic, retain, readonly) NSMutableDictionary* pagesInfo;
@property (nonatomic, retain, readonly) NSMutableArray* selectionRanges;

@property (nonatomic) CoreTextViewOptionsBits viewOptions;
@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) NSInteger pageDisplayed;

@end



