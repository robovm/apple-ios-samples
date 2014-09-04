/*
    File: AttributedStringDoc.h
Abstract: Manages the construction of AttributedStrings from xml/plist documents. These documents are generated on Mac OS X using the AttributedStringDoc Gen sibling project to this demo. It takes an RTF document created using TextEdit, reads it into an AttributedString, and finally proceeds to serialize it into a format (xml/plist) that is readable by the AttributedStringDoc class. In fact, the AttributedStringDoc class is also used on the desktop to serialize the file.
 
 This class also keeps track of the characteristics of the document: background colors, frames for each page, page number display, and number of columns to display.
 
 Note that this file is used in samples for iOS and Mac OS X and has platform-dependent code.
 
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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

enum  {
	ASDFeaturesDefault = 0,
	
	ASDFeaturesSmallCaps = 1 << 0,
	ASDFeaturesLigatures = 1 << 1,
	ASDFeaturesPropNumbers = 1 << 2,
	ASDFeaturesStylisticVariants = 1 << 3,
	
	// we'll handle up to 16 predefined features
	ASDFeaturesFeatureMask = 0xFF
};
typedef NSUInteger ASDFeaturesBits;


extern NSString* const ASD_SMALL_CAPITALS;
extern NSString* const ASD_RARE_LIGATURES;
extern NSString* const ASD_PROP_NUMBERS;
extern NSString* const ASD_STYLISTIC_VARS;

//Document level keys
extern NSString* const ASD_VERSION;
extern NSString* const ASD_PAGE_LAYOUT;  //optional
extern NSString* const ASD_STRING_DICT;  //optional

//String Dict Keys
extern NSString* const ASD_STRING;
extern NSString* const ASD_RANGES;
extern NSString* const ASD_FONT;
extern NSString* const ASD_SHOW_PAGE_NUMBER;

//Page layout keys - if found outside of a page definition, they are global to the document
extern NSString* const ASD_PAGE_LAYOUT_COLUMNS;
extern NSString* const ASD_PAGE_LAYOUT_BACKGROUND_COLOR;
extern NSString* const ASD_PAGE_LAYOUT_VERTICAL;

//Page layout specific keys 
extern NSString* const ASD_PAGE_LAYOUT_FRAMES;
extern NSString* const ASD_PAGE_LAYOUT_FRAME_TYPE;
extern NSString* const ASD_PAGE_LAYOUT_FRAME_RECT;
extern NSString* const ASD_PAGE_LAYOUT_FRAME_VALUE;
extern NSString* const ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE;
extern NSString* const ASD_PAGE_LAYOUT_FRAME_HORIZONTAL;	//overrides page setting
extern NSString* const ASD_PAGE_LAYOUT_FRAME_VERTICAL;		//overrides page setting

enum {
	ASDFrameTypeEmpty = 0,		//Empty frame
	ASDFrameTypeTextFlow = 1,	//Text for document flows into this frame
    ASDFrameTypeText = 2,		//Frame contains text specific to it (does not draw from document's "global" text)
    ASDFrameTypePicture = 3,	//Frame contains an image file CG can draw
	
    ASDFrameTypeDefault = ASDFrameTypeEmpty
};
typedef NSUInteger ASDFrameType;

@interface AttributedStringDoc : NSObject {
	NSString           *fileName;         // document filename
	NSAttributedString *attributedString; // document text storage
	NSDictionary       *pageLayout;       // page layout information
	
	NSUInteger         columnCount;         
	BOOL               verticalOrientation; 
    BOOL               showPageNumbers;

@private	
	CGColorRef        _backgroundColor;
}

// Verify file version/content is valid
+ (BOOL)versionIsValid:(NSArray*)versionArr;
+ (BOOL)contentIsValid:(NSArray*)versionArr;

// Document has valid (not empty) content
- (BOOL)hasContent;

- (id)initWithFileNameFromBundle:(NSString *)theFileName;

// Apply overriding font/font features to document contents
- (void)setFontWithName:(NSString*)postName range:(NSRange)range features:(ASDFeaturesBits)featureBits;
- (void)setFontFeatures:(ASDFeaturesBits)featureBits range:(NSRange)range;

// Set/get page layout background color
- (void)setColor:(CGColorRef)color;
- (CGColorRef)copyColor;

// Document page/frame access methods
- (NSUInteger)columnsForPage:(NSInteger)pageNumber;
- (NSArray*)framesForPage:(NSInteger)pageNumber;
- (CGColorRef)copyColorForPage:(NSInteger)pageNumber;
- (NSString *)accessibilityLabelForFrame:(id)frameDesc;
- (CGRect)boundsForFrame:(id)frameDesc;
- (ASDFrameType)typeForFrame:(id)frameDesc;
- (NSNumber*)typeForFrameAsNumber:(id)frameDesc;
- (id)objectForFrame:(id)frameDesc;

    
@property (retain) NSString* fileName;
@property (retain, readonly) NSAttributedString* attributedString;
@property (retain, readonly) NSDictionary* pageLayout;

@property(nonatomic, readonly) BOOL verticalOrientation;
@property(nonatomic, readonly) BOOL showPageNumbers;
@property(nonatomic) NSUInteger columnCount;

@end

// Helper extern functions for applying overriding font/font features to a given 
// attributed string, used by setFontWithName/setFontFeatures
extern void ApplyFontNameToString(NSMutableAttributedString* string, NSString* postName, NSRange range, ASDFeaturesBits featureBits);
extern void ApplyFontFeaturesToString(NSMutableAttributedString* attrStr, NSRange range, ASDFeaturesBits featureBits);
