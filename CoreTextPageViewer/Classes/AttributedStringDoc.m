/*
     File: AttributedStringDoc.m
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

#import "AttributedStringDoc.h"

#import <libkern/OSAtomic.h>

#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import <CoreText/CoreText.h>
#else
#import <AppKit/AppKit.h>
#endif


NSString* const ASD_SMALL_CAPITALS = @"Small Capitals";
NSString* const ASD_RARE_LIGATURES = @"Rare Ligatures";
NSString* const ASD_PROP_NUMBERS = @"Proportional Numbers";
NSString* const ASD_STYLISTIC_VARS = @"Stylistic Variants";


// AttributedStringDoc class extension helper methods						 
@interface AttributedStringDoc ()
- (NSMutableAttributedString*)attributedStringForASXMLDict:(NSDictionary*)dict stringWideAttributes:(NSDictionary*)additonalAttributes;
- (void)loadWithFileName;
- (NSString*)filePathForFileName:(NSString*)theFileName;
@end


//Document level keys
NSString* const ASD_VERSION = @"ASD_VERSION";
NSString* const ASD_PAGE_LAYOUT = @"ASD_PAGE_LAYOUT";  //optional
NSString* const ASD_STRING_DICT = @"ASD_STRING_DICT";  //optional
NSString* const ASD_SHOW_PAGE_NUMBER = @"ASD_SHOW_PAGE_NUMBER"; //optional - default is not to show page numbers


//String Dict Keys
NSString* const ASD_STRING = @"ASD_STRING";
NSString* const ASD_RANGES = @"ASD_RANGES";
NSString* const ASD_FONT = @"ASD_FONT";

//Page layout keys
NSString* const ASD_PAGE_LAYOUT_COLUMNS = @"ASD_PAGE_LAYOUT_COLUMNS";
NSString* const ASD_PAGE_LAYOUT_BACKGROUND_COLOR = @"ASD_PAGE_LAYOUT_BACKGROUND_COLOR";
NSString* const ASD_PAGE_LAYOUT_VERTICAL = @"ASD_PAGE_LAYOUT_VERTICAL";	

// NOTE: vertical glyphs as of iOS 4 SDK are only supported on the Desktop - when they are enabled
// this sample code will display glyphs properly rotated in vertical lines

NSString* const ASD_PAGE_LAYOUT_FRAMES = @"ASD_PAGE_LAYOUT_FRAMES";
NSString* const ASD_PAGE_LAYOUT_FRAME_TYPE = @"ASD_PAGE_LAYOUT_FRAME_TYPE";
NSString* const ASD_PAGE_LAYOUT_FRAME_RECT = @"ASD_PAGE_LAYOUT_FRAME_RECT";
NSString* const ASD_PAGE_LAYOUT_FRAME_VALUE = @"ASD_PAGE_LAYOUT_FRAME_VALUE";
NSString* const ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE = @"ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE";

NSString* const ASD_PAGE_LAYOUT_FRAME_HORIZONTAL = @"ASD_PAGE_LAYOUT_FRAME_HORIZONTAL";	//overrides page setting
NSString* const ASD_PAGE_LAYOUT_FRAME_VERTICAL = @"ASD_PAGE_LAYOUT_FRAME_VERTICAL";		//overrides page setting


const NSUInteger ASD_VersionNumber = 1;	//version indicates the structure (shema) of the file. Different versions are generally incompatible
const NSUInteger ASD_ContentNumber = 1;  //content indicates meaning of the data in the structure. at times the meaning of the data is irrelevant while processing (say dumping the contents of the file) but generally a changed value indicates an incompatibility

const NSUInteger ASD_ParagraphStylesSupported = 9;


#pragma mark -
#pragma mark Functions to change fonts or font features in an NSAttributedString

// Static helper function to add/validate a font feature to a given feature array
static BOOL AddFeature(NSMutableArray* featureArray, NSArray* featureSelectorArr, id featureTypeIdentifierKey, NSString* matchSelectorName, NSString* matchSelectorNameAlt, BOOL value)
{
	for (NSDictionary* selectorDict in featureSelectorArr) {
		// most of the time the features we are testing for are going to be off, so test that case first 
		if (!value && [selectorDict objectForKey:(NSString*)kCTFontFeatureSelectorDefaultKey] != nil) {	
				// if the setting was off (value is NO) and this is the default value for this feature, then use it
				[featureArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:featureTypeIdentifierKey, (NSString*)kCTFontFeatureTypeIdentifierKey,
						[selectorDict objectForKey:(id)kCTFontFeatureSelectorIdentifierKey], (NSString*)kCTFontFeatureSelectorIdentifierKey, nil]];
				return NO;
		}
		else if (value) {
			NSString* featureSelectorName = [selectorDict objectForKey:(NSString*)kCTFontFeatureSelectorNameKey];
			if ([featureSelectorName isEqual:matchSelectorName] || (matchSelectorNameAlt != nil && [featureSelectorName isEqual:matchSelectorNameAlt])) {
				// Feature is on and supported, so add it
				[featureArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:featureTypeIdentifierKey, (NSString*)kCTFontFeatureTypeIdentifierKey,
						[selectorDict objectForKey:(id)kCTFontFeatureSelectorIdentifierKey], (NSString*)kCTFontFeatureSelectorIdentifierKey, nil]];
				return YES;
			}
		}
	}
	
	return NO;
}

// Helper function to apply font features (for given font) to given attributed string 
void ApplyFontNameToString(NSMutableAttributedString* attrStr, NSString* postName, NSRange range, ASDFeaturesBits featureBits)
{
	NSRange limitRange;
	NSRange effectiveRange;
	CTFontRef fontRef;
	
	if (range.length == 0) {
		range.length = [attrStr length];
	}

	limitRange = range;
	
	NSMutableArray* featureArray = nil;

	// Create our initial font feature array, copying default features for font
	featureArray = [[[NSMutableArray alloc] init] autorelease];
	fontRef = CTFontCreateWithName((CFStringRef)postName, 12., NULL);
	NSArray* features = [(NSArray*)CTFontCopyFeatures(fontRef) autorelease];

	// Update featureArray for given featureBits, depending on support for feature
	// in font, and our general list of supported features for this sample
	BOOL aFeatureWasTurnedOn = NO;
	for (NSDictionary* feature in features) {

		NSString* featureName = [feature objectForKey:(NSString*)kCTFontFeatureTypeNameKey];
		BOOL featureIsExclusive = [feature objectForKey:(NSString*)kCTFontFeatureTypeExclusiveKey] != nil;
		BOOL featureTurnedOn = NO;
		
		// Current feature is mutually exclusive (against other features), so skip remaining feature bits
		if (featureIsExclusive && aFeatureWasTurnedOn)
				featureBits = 0;

		// For set of features we support for this sample, add (as enabled/disabled as necessary,
		// dependent on font support) to featureArray
		if ([featureName isEqual:ASD_SMALL_CAPITALS]) {
			featureTurnedOn = AddFeature(featureArray, [feature objectForKey:(NSString*)kCTFontFeatureTypeSelectorsKey], 
				(id)[feature objectForKey:(id)kCTFontFeatureTypeIdentifierKey], ASD_SMALL_CAPITALS, nil, (featureBits & ASDFeaturesSmallCaps) != 0);
		}
		else if ([featureName isEqual:@"Ligatures"]) {
			featureTurnedOn = AddFeature(featureArray, [feature objectForKey:(NSString*)kCTFontFeatureTypeSelectorsKey], 
				(id)[feature objectForKey:(id)kCTFontFeatureTypeIdentifierKey], ASD_RARE_LIGATURES, @"Special Ligatures", (featureBits & ASDFeaturesLigatures) != 0);
		}
		else if ([featureName isEqual:@"Number Spacing"]) {
			featureTurnedOn = AddFeature(featureArray, [feature objectForKey:(NSString*)kCTFontFeatureTypeSelectorsKey], 
				(id)[feature objectForKey:(id)kCTFontFeatureTypeIdentifierKey], ASD_PROP_NUMBERS, nil, (featureBits & ASDFeaturesPropNumbers) != 0);
		}
		else if ([featureName isEqual:@"Letter Case"]) {
			featureTurnedOn = AddFeature(featureArray, [feature objectForKey:(NSString*)kCTFontFeatureTypeSelectorsKey], 
				(id)[feature objectForKey:(id)kCTFontFeatureTypeIdentifierKey], @"Small Caps", ASD_SMALL_CAPITALS, (featureBits & ASDFeaturesSmallCaps) != 0);
		}
		else if ([featureName isEqual:ASD_STYLISTIC_VARS]) {	//only present in Zapfino
			featureTurnedOn = AddFeature(featureArray, [feature objectForKey:(NSString*)kCTFontFeatureTypeSelectorsKey], 
				(id)[feature objectForKey:(id)kCTFontFeatureTypeIdentifierKey], @"Third variant glyph set", nil, (featureBits & ASDFeaturesStylisticVariants) != 0);
		}
		
		if (featureTurnedOn) {
			aFeatureWasTurnedOn = YES;
			if (featureIsExclusive)
				featureBits = 0;
		}

	}
	CFRelease(fontRef);
	
	if ([featureArray count] == 0) 
		featureArray = nil;

	// Create our font descriptor
	CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithAttributes(
			(CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:postName, (NSString*)kCTFontNameAttribute,  featureArray, (NSString*)kCTFontFeatureSettingsAttribute, nil] );
			
	// Apply font descriptor over given text range
	while (limitRange.length > 0) {
		fontRef = (CTFontRef)[attrStr attribute:(NSString*)kCTFontAttributeName
			atIndex:limitRange.location longestEffectiveRange:&effectiveRange
			inRange:limitRange];
		
		CGFloat pointSize = CTFontGetSize(fontRef);
		CTFontRef newFont = CTFontCreateWithFontDescriptor(fontDescriptor, pointSize, NULL);
		
		[attrStr addAttributes:[NSDictionary dictionaryWithObject:(id)newFont forKey:(NSString*)kCTFontAttributeName] range:effectiveRange];
		CFRelease(newFont);

		limitRange = NSMakeRange(NSMaxRange(effectiveRange),
			NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	
	CFRelease(fontDescriptor);
}

// Helper function to apply given font features to given attributed string 
void ApplyFontFeaturesToString(NSMutableAttributedString* attrStr, NSRange range, ASDFeaturesBits featureBits) {
	NSRange limitRange;
	NSRange effectiveRange;
	CTFontRef fontRef;
	
	if (range.length == 0) {
		range.length = [attrStr length];
	}

	limitRange = range;
	
	while (limitRange.length > 0) {
		fontRef = (CTFontRef)[attrStr attribute:(NSString*)kCTFontAttributeName
			atIndex:limitRange.location longestEffectiveRange:&effectiveRange
			inRange:limitRange];
		
		NSString* postName = [(NSString*)CTFontCopyPostScriptName(fontRef) autorelease];
		
		// For font for this range, apply feature bits
		ApplyFontNameToString(attrStr, postName, effectiveRange, featureBits);
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange),
			NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	
}


#pragma mark -
#pragma mark Color Utilities

// Return a static cached device RGB colorspace
static inline CGColorSpaceRef RGBColorSpace(void) {
    static CGColorSpaceRef cachedRGBColorSpace = NULL;
    if (cachedRGBColorSpace == NULL) {
        CGColorSpaceRef tmp = CGColorSpaceCreateDeviceRGB();
        if (tmp != NULL && !OSAtomicCompareAndSwapPtrBarrier(NULL, tmp, (void * volatile *)&cachedRGBColorSpace)) 
            CGColorSpaceRelease(tmp);
    }
    return cachedRGBColorSpace;
}

// Return a static cached device gray colorspace
static inline CGColorSpaceRef GrayColorSpace(void) {
    static CGColorSpaceRef cachedGrayColorSpace = NULL;
    if (cachedGrayColorSpace == NULL) {
        CGColorSpaceRef tmp = CGColorSpaceCreateDeviceGray();
        if (tmp != NULL && !OSAtomicCompareAndSwapPtrBarrier(NULL, tmp, (void * volatile *)&cachedGrayColorSpace))
            CGColorSpaceRelease(tmp);
    }
    return cachedGrayColorSpace;
}

// Return a static cached clearcolor 
static inline CGColorRef ClearColor(void) {
    static CGColorRef cachedClearColor = NULL;
    
    if (cachedClearColor == NULL) {
        CGFloat components[2] = {0.0, 0.0};
        CGColorRef tmp = CGColorCreate(GrayColorSpace(), components); //return clear color
        if (tmp != NULL && !OSAtomicCompareAndSwapPtrBarrier(NULL, tmp, (void * volatile *)&cachedClearColor)) 
            CGColorRelease(tmp);
    }
    
    return cachedClearColor;
}

// Create CGColorRef from RGB(A) array, or clearcolor if no RGB provided
static CGColorRef CreateColorFromRGBComponentsArray(NSArray* calibratedRGB) {
	if (calibratedRGB) {
		CGFloat components[4] = { 
			[(NSNumber*)[calibratedRGB objectAtIndex:0] floatValue], 
			[(NSNumber*)[calibratedRGB objectAtIndex:1] floatValue], 
			[(NSNumber*)[calibratedRGB objectAtIndex:2] floatValue], 
			[(NSNumber*)[calibratedRGB objectAtIndex:3] floatValue] 
		};
		return  CGColorCreate(RGBColorSpace(), components);
	}
	
	CGFloat components[2] = {0.0, 0.0};
    return CGColorCreate(GrayColorSpace(), components); //return clear color

}

#pragma mark -
#pragma mark AttributedStringDoc implementation

@implementation AttributedStringDoc

//@synthesize fileName;
@synthesize attributedString;
@synthesize pageLayout;
@synthesize verticalOrientation;
@synthesize showPageNumbers;
@synthesize columnCount;


- (BOOL)hasContent {
	// Document has content if it has valid text contents that have layout
    return (attributedString != NULL || pageLayout != NULL);
}

- (void)setFontWithName:(NSString*)postName range:(NSRange)range features:(ASDFeaturesBits)featureBits
{
	// class wrapper for ApplyFontNameToString
	ApplyFontNameToString( (NSMutableAttributedString*)attributedString, postName, range, featureBits);
}

- (void)setFontFeatures:(ASDFeaturesBits)featureBits range:(NSRange)range
{
	// class wrapper for ApplyFontFeaturesToString
	ApplyFontFeaturesToString( (NSMutableAttributedString*)attributedString, range, featureBits);
}

- (id)initWithFileNameFromBundle:(NSString *)theFileName {
	if (self = [super init]) {
        [self setFileName:theFileName];
    }
	return self;
}

- (void)dealloc {
    [attributedString release];
	[pageLayout release];
    [super dealloc];
}

- (NSString *)description
{
	return fileName;
}

- (NSString *)fileName
{
    return [[fileName retain] autorelease];
}

- (void)setFileName:(NSString *)newFileName {
    if (![fileName isEqualToString:newFileName]) {
        [fileName release];
        fileName = [newFileName retain];

        // Note that setting filename incurs reload of file contents
		[self loadWithFileName];
   }
}

// Class method to verify a passed-in document version
+ (BOOL)versionIsValid:(NSArray*)versionArr {
    return ([(NSNumber*)[versionArr objectAtIndex:0] unsignedIntValue] == ASD_VersionNumber);
}

// Class method to verify a passed-in document content version
+ (BOOL)contentIsValid:(NSArray*)versionArr {
    return ([(NSNumber*)[versionArr objectAtIndex:1] unsignedIntValue] == ASD_ContentNumber);
}

// Set document background color
- (void)setColor:(CGColorRef)color {
	if (_backgroundColor != color) {
        if (_backgroundColor != NULL) {
            CGColorRelease(_backgroundColor);
        }
        _backgroundColor = CGColorRetain(color);
	}
}

- (CGColorRef)copyColor {
	return CGColorRetain(_backgroundColor);
}

// Get the number of text columns in document data
- (NSUInteger)columnsForPage:(NSInteger)pageNumber {
	if (pageLayout) {
		NSDictionary* pageDesc = [pageLayout objectForKey:[NSString stringWithFormat:@"%u", pageNumber]];
		if (pageDesc) {
			NSNumber* columns = [pageDesc objectForKey:ASD_PAGE_LAYOUT_COLUMNS];
			if (columns) {
				return [columns unsignedIntValue];
			}
		}
	}
	return columnCount;
}

// Get number of frames for given page
- (NSArray*)framesForPage:(NSInteger)pageNumber {
	if (pageLayout) {
		NSDictionary* pageDesc = [pageLayout objectForKey:[NSString stringWithFormat:@"%u", pageNumber]];
		if (pageDesc) {
			return [pageDesc objectForKey:ASD_PAGE_LAYOUT_FRAMES];
		}
	}
	return NULL;
}

// Get background color for given page
- (CGColorRef)copyColorForPage:(NSInteger)pageNumber {
	if (pageLayout) {
		NSDictionary* pageDesc = [pageLayout objectForKey:[NSString stringWithFormat:@"%u", pageNumber]];
		if (pageDesc) {
			NSArray* calibratedRGB = [pageDesc objectForKey:ASD_PAGE_LAYOUT_BACKGROUND_COLOR];
			if (calibratedRGB) {
 				return CreateColorFromRGBComponentsArray(calibratedRGB);
			}
		}
	}
    
    return CGColorRetain(ClearColor());
}

// Get accessibility label for given frame
- (NSString *)accessibilityLabelForFrame:(id)frameDesc {
	NSDictionary* frameDict = frameDesc;
	NSString *returnValue = [frameDict objectForKey:ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE];
	return returnValue;
}

// Get bounds for given frame
- (CGRect)boundsForFrame:(id)frameDesc {
	NSDictionary* frameDict = frameDesc;
	NSArray* frameRectValues = [frameDict objectForKey:ASD_PAGE_LAYOUT_FRAME_RECT];
	
	return CGRectMake([(NSNumber*)[frameRectValues objectAtIndex:0] unsignedIntValue], [(NSNumber*)[frameRectValues objectAtIndex:1] unsignedIntValue], [(NSNumber*)[frameRectValues objectAtIndex:2] unsignedIntValue], [(NSNumber*)[frameRectValues objectAtIndex:3] unsignedIntValue]);
}

// Get frame type (text, image, etc) for given frame
- (ASDFrameType)typeForFrame:(id)frameDesc {
	NSDictionary* frameDict = frameDesc;
	
	return [(NSNumber*)[frameDict objectForKey:ASD_PAGE_LAYOUT_FRAME_TYPE] unsignedIntValue];
}

// Get frame type (text, image, etc) for given frame (as NSNumber)
- (NSNumber*)typeForFrameAsNumber:(id)frameDesc {
	NSDictionary* frameDict = frameDesc;
	
	return [frameDict objectForKey:ASD_PAGE_LAYOUT_FRAME_TYPE];
}

// Get content object for given frame
- (id)objectForFrame:(id)frameDesc {
	NSDictionary* frameDict = frameDesc;
	
    id result = [frameDict objectForKey:ASD_PAGE_LAYOUT_FRAME_VALUE];
    
    if ([self typeForFrame:frameDesc] == ASDFrameTypeText) 
        result = [self attributedStringForASXMLDict:result stringWideAttributes:nil];
    else if ([self typeForFrame:frameDesc] == ASDFrameTypePicture) 
        result = [self filePathForFileName:result];
    
    return result;

}

- (NSString*)filePathForFileName:(NSString*)theFileName {
	return [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], theFileName]; 
}

// Generate the attributed string for a document ASXMLDict dictionary
- (NSMutableAttributedString*)attributedStringForASXMLDict:(NSDictionary*)attrStrDict stringWideAttributes:(NSDictionary*)additonalAttributes {	
	
    if (attrStrDict == NULL)
        return NULL;

	NSAttributedString* strBase = [[[NSAttributedString alloc] initWithString:[attrStrDict objectForKey:ASD_STRING]] autorelease];    
	NSMutableAttributedString* str = [[[NSMutableAttributedString alloc] init] autorelease];
	[str setAttributedString:strBase];
		
	// Walk the ASXMLDict elements, creating text/paragraph attributes as needed
	NSArray* ranges = [attrStrDict objectForKey:ASD_RANGES];
	NSEnumerator* rangesEnumerator = [ranges objectEnumerator];
	NSArray* rangeElements;
	while ((rangeElements = [rangesEnumerator nextObject]) != NULL) {
		NSRange range = { [(NSNumber*)[rangeElements objectAtIndex:0] integerValue], [(NSNumber*)[rangeElements objectAtIndex:1] integerValue] };
		
		NSEnumerator* keyEnumerator = [(NSDictionary*)[rangeElements objectAtIndex:2] keyEnumerator];
		id key;
		while ((key = [keyEnumerator nextObject]) != NULL) {
			id obj = [(NSDictionary*)[rangeElements objectAtIndex:2] objectForKey:key];
			if ([ASD_FONT isEqual:key]) {
				// Font info
				CTFontRef fontRef = CTFontCreateWithName((CFStringRef)[(NSArray*)obj objectAtIndex:0], [(NSNumber*)[(NSArray*)obj objectAtIndex:1] floatValue], NULL);
				[str addAttribute:(NSString*)kCTFontAttributeName value:(id)fontRef range:range];
				CFRelease(fontRef);
			}
			else if ([(NSString*)kCTForegroundColorAttributeName isEqual:key]) {
				// Foreground color info
				CGColorRef color = CreateColorFromRGBComponentsArray((NSArray*)obj);
				[str addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)color range:range];
				CGColorRelease(color);
			}
			else if ([(NSString*)kCTUnderlineStyleAttributeName isEqual:key]) {
				// Underline text style
				[str addAttribute:(NSString*)kCTUnderlineStyleAttributeName value:obj range:range];
			}
			else if ([(NSString*)kCTParagraphStyleAttributeName isEqual:key]) {

				// Paragraph styles
				
				NSArray* paragStyles = (NSArray*)obj;
				NSAssert([paragStyles count] >= ASD_ParagraphStylesSupported, @"Wrong number of paragraph styles");
				
				CTParagraphStyleSetting settings[ASD_ParagraphStylesSupported];
				CTTextAlignment alignment;
				CGFloat floatValues[ASD_ParagraphStylesSupported];
				
				settings[0].spec = kCTParagraphStyleSpecifierAlignment;
				settings[0].valueSize = sizeof(CTTextAlignment);
				alignment = [(NSNumber*)[paragStyles objectAtIndex:0] integerValue];
				settings[0].value = &alignment;

				settings[1].spec = kCTParagraphStyleSpecifierLineSpacing;
				settings[2].spec = kCTParagraphStyleSpecifierParagraphSpacing;
				settings[3].spec = kCTParagraphStyleSpecifierMaximumLineHeight;
				settings[4].spec = kCTParagraphStyleSpecifierMinimumLineHeight;
				settings[5].spec = kCTParagraphStyleSpecifierHeadIndent;
				settings[6].spec = kCTParagraphStyleSpecifierTailIndent;
				settings[7].spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
				settings[8].spec = kCTParagraphStyleSpecifierDefaultTabInterval;
				
				
				NSUInteger styleIndex;
				for (styleIndex=1; styleIndex<ASD_ParagraphStylesSupported; styleIndex++) {
					settings[styleIndex].valueSize = sizeof(CGFloat);
					floatValues[styleIndex] = [(NSNumber*)[paragStyles objectAtIndex:styleIndex] floatValue];
					settings[styleIndex].value = &floatValues[styleIndex];
				}

				CTParagraphStyleRef style = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &settings, ASD_ParagraphStylesSupported);
				[str addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(id)style range:range];
				CFRelease(style);
			}
			else {
				NSLog(@"Unrecognized key:%@ obj:%@", key, obj);
			}
		}
	}
	
	if (str && additonalAttributes) {
		NSRange range = {0, [str length]};
		NSEnumerator* keyEnumerator = [additonalAttributes keyEnumerator];
		id nameKey;
		while ((nameKey = [keyEnumerator nextObject]) != NULL) 
			[str addAttribute:nameKey value:[additonalAttributes objectForKey:nameKey] range:range];
	}
	return str;
}

- (void)loadWithFileName {	
	pageLayout = NULL;
	attributedString = NULL;
	columnCount = 1;
	[self setColor:ClearColor()];
	
	NSString* filePath = [self filePathForFileName:fileName];
	if (filePath == NULL) {
		NSLog(@"%@ could not be opened/found", fileName);
		return;
	}

	// Get document dictionary
	NSDictionary* docDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	if (docDict == NULL) {
		NSLog(@"%@ contents cannot be processed", filePath);
		return;
	}
	
	// Check that document version info is supported
	NSArray* versionArr = [docDict objectForKey:ASD_VERSION];
	if (![AttributedStringDoc versionIsValid:versionArr] || ![AttributedStringDoc contentIsValid:versionArr]) {
		NSLog(@"%@ could not be opened due to version/content(%@) incompatibility", filePath, versionArr);
		return;
	}
    
	// Vertical orientation (not yet supported in iOS)
	NSNumber* docNumValue = [docDict objectForKey:ASD_PAGE_LAYOUT_VERTICAL];
	verticalOrientation = (docNumValue && [docNumValue integerValue] != 0);
	
	// Show page numbers on/off
	docNumValue = [docDict objectForKey:ASD_SHOW_PAGE_NUMBER];
	showPageNumbers = (docNumValue && [docNumValue integerValue] != 0);

	// Number of text columns
	docNumValue = [docDict objectForKey:ASD_PAGE_LAYOUT_COLUMNS];
	columnCount = docNumValue ? [docNumValue integerValue] : 1;

	// Background color info
    CGColorRef bkgColor = CreateColorFromRGBComponentsArray([docDict objectForKey:ASD_PAGE_LAYOUT_BACKGROUND_COLOR]);
    [self setColor:bkgColor];
    CGColorRelease(bkgColor);
    CGColorRelease(_backgroundColor); //background color was retained by setColor
    
	// Page layout info
	pageLayout = [[docDict objectForKey:ASD_PAGE_LAYOUT] retain];
	
	NSDictionary* otherAttr = nil;
	if (verticalOrientation) {
		// kCTVerticalFormsAttributeName is not available in iOS 
	}

	// Actual string data
	attributedString = [[self attributedStringForASXMLDict:[docDict objectForKey:ASD_STRING_DICT] stringWideAttributes:otherAttr] retain];    
}


@end
