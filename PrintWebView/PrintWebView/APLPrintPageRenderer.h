
/*
     File: APLPrintPageRenderer.h
 Abstract: A UIPrintPageRenderer subclass for printing with a footer.
 
  Version: 2.0
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIKit.h>

/*
  Setting SIMPLE_LAYOUT to 1 uses a layout that involves less application code and
  produces a layout where the web view content has margins that are relative to
  the imageable area of the paper.
 
  Setting SIMPLE_LAYOUT to 0 uses a layout that involves more computation and setup
  and produces a layout where the webview content is inset 1/2 from the edge of the 
  paper (assuming it can be without being clipped). See the comments in 
  APLPrintPageRenderer.m immediately after #if !SIMPLE_LAYOUT.
*/
#define SIMPLE_LAYOUT 1

// The point size to use for the height of the text in the
// header and footer.
#define HEADER_FOOTER_TEXT_HEIGHT     10

// The left edge of text in the header will be offset from the left 
// edge of the imageable area of the paper by HEADER_LEFT_TEXT_INSET.
#define HEADER_LEFT_TEXT_INSET	      20

// The header and footer will be inset this much from the edge of the
// imageable area just to avoid butting up right against the edge that
// will be clipped.
#define HEADER_FOOTER_MARGIN_PADDING  5

// The right edge of text in the footer will be offset from the right 
// edge of the imageable area of the paper by FOOTER_RIGHT_TEXT_INSET.
#define FOOTER_RIGHT_TEXT_INSET	      20

#if !SIMPLE_LAYOUT

// The header and footer content will be no closer than this distance
// from the web page content on the printed page.
#define MIN_HEADER_FOOTER_DISTANCE_FROM_CONTENT	10

// Enforce a minimum 1/2 inch margin on all sides.
#define MIN_MARGIN 36

#endif

@interface APLPrintPageRenderer : UIPrintPageRenderer

@property (readwrite) NSString *jobTitle;

@end
