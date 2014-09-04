/*
     File: CoreTextScrollView.m
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

#import "CoreTextScrollView.h"
#import "TextAccessibilityElement.h"

// Various hard-coded constants for this sample

#define COLUMN_COUNT_MIN 1
#define COLUMN_COUNT_MAX 3

#define IPAD_HORIZONTAL_MARGIN 40
#define IPAD_VERTICAL_MARGIN 30

#define IPHONE_HORIZONTAL_MARGIN 10
#define IPHONE_VERTICAL_MARGIN 10

#pragma mark -
#pragma mark CoreTextViewFrameInfo definition and implementation

// CoreTextViewFrameInfo caches a CTFrame and related info
@interface CoreTextViewFrameInfo : NSObject {
@private
	ASDFrameType     frameType;
	CGPathRef        path;
	// stringOffsetForSetter keeps track of the offset into the attributed string 
	// where the framesetter got created. We need this offset as setters are likely 
	// shared between frames
    NSUInteger       stringOffsetForSetter; 
	CTFramesetterRef setter;
	CTFrameRef       frame;
	NSRange          stringRange;
	id               value; // holder for AttributedStringDoc ref
}

// NSObject:description for debugging
- (NSString *)description;

- (CoreTextViewFrameInfo*)initWithFrameType:(ASDFrameType)type path:(CGPathRef)path;

// Cache string offset where framesetter was created
- (NSUInteger)setFramesetterForStringOffset:(NSUInteger)stringOffset previousFreeFlowFrame:(CoreTextViewFrameInfo*)prevFreeFlowFrame;

// Accessors
- (CGPathRef)path;
- (CTFramesetterRef)setter;
- (CTFrameRef)frame;
- (void)setPath:(CGPathRef)pathValue;
- (void)setSetter:(CTFramesetterRef)setterValue;
- (void)setFrame:(CTFrameRef)frameValue;

// Refresh the cached CTFrame for current info (will re-layout)
- (void)refreshTextFrame;

@property (nonatomic)			ASDFrameType frameType;
@property (nonatomic)			NSRange stringRange;
@property (nonatomic, retain) 	id value;
@property (nonatomic)           NSUInteger stringOffsetForSetter;   
@end                                                                

@implementation CoreTextViewFrameInfo

@synthesize frameType;
@synthesize value;
@synthesize stringRange;
@synthesize stringOffsetForSetter;

- (CGPathRef)path {
	return path;
}
- (CTFramesetterRef)setter {
	return setter;
}
- (CTFrameRef)frame {
	return frame;
}

- (void)setPath:(CGPathRef)pathValue {
	if (pathValue != path) {
		if (path) CGPathRelease(path);
		path = pathValue;
		if (path) CGPathRetain(path);
	}
}

- (void)setSetter:(CTFramesetterRef)setterValue {
	if (setterValue != setter) {
		if (setter) CFRelease(setter);
		setter = setterValue;
		if (setter) CFRetain(setter);
	}
}

- (void)setFrame:(CTFrameRef)frameValue {
	if (frameValue != frame) {
		if (frame) CFRelease(frame);
		frame = frameValue;
		if (frame)  CFRetain(frame);
	}
}

- (CoreTextViewFrameInfo*)initWithFrameType:(ASDFrameType)type path:(CGPathRef)thePath {
    if (self = [super init]) {
        frameType = type;
        path = CGPathRetain(thePath);
        setter = NULL;
        frame = NULL;
        value = nil;
        stringRange.location = 0;
        stringRange.length = 0;
        stringOffsetForSetter = 0;
    }
    return self;    
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<CoreTextViewFrameInfo %p> type: %u  CGPath: %p  CTFramesetter %p: value: %@", 
		self, frameType, path, setter, [value description]];
}

- (NSUInteger)setFramesetterForStringOffset:(NSUInteger)stringOffset previousFreeFlowFrame:(CoreTextViewFrameInfo*)prevFreeFlowFrame {
	static CGFloat iWidth = 0.;
	static CGFloat helveticaLineHeight = 0.;
	AttributedStringDoc* document = value;
	
    // Estimate how much text we can fit into the frame. We do so by getting the glyph metrics for the letter 'x' in Helvetica
    // and see how many of these glyphs we can fit into the frame. Obviously this is not exact (and a bit more precise would be 
    // to use the font being used in the attributed string), but this is a conservative first approximation
	CGRect frameRect = CGPathGetBoundingBox(path);
	if (iWidth == 0) {
		// First time here, so use Helvetica 'x' to approximate as described above
		const UniChar iChar = 'x';
		CGGlyph iGlyph;
		CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 12.0, NULL);
		if( CTFontGetGlyphsForCharacters(font, &iChar, &iGlyph, 1) ) {
			CGRect iBoundRect;
			CTFontGetBoundingRectsForGlyphs(font, kCTFontHorizontalOrientation, &iGlyph, &iBoundRect, 1);
			iWidth = iBoundRect.size.width;
		}
		else
			iWidth = 3.0;	// should have found the glyph width - be conservative and assume something small
			
		helveticaLineHeight = CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font);
        
        CFRelease(font);
	}
	
	NSUInteger maxLength = [document.attributedString length] - stringOffset;
	NSUInteger len = (frameRect.size.width / iWidth) * (frameRect.size.height / helveticaLineHeight);
	if (len > maxLength) {
		len = maxLength;
	}
	NSRange range = NSMakeRange(stringOffset, len);
	CTFramesetterRef framesetter = nil;
	CTFrameRef workFrame = nil;
	CFRange visibleRange = {0, 0};
    
	NSDictionary* frameAttributes = nil;
	if (document.verticalOrientation) {
		frameAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCTFrameProgressionRightToLeft] forKey:(id)kCTFrameProgressionAttributeName];
	}
    
    // Figure out if the previous setter can be used to render the current frame
    if (prevFreeFlowFrame) {
        CTFrameRef prevFrame = [prevFreeFlowFrame frame];
        CFRange prevVisRange = CTFrameGetVisibleStringRange(prevFrame);
        CFRange prevStringRange = CTFrameGetStringRange(prevFrame);
        CFRange newFrameRange = { prevVisRange.location + prevVisRange.length, 0 };
        newFrameRange.length = (prevStringRange.location + prevStringRange.length) - newFrameRange.location;
        if (newFrameRange.length > 0) {
			// Generate CTFrame using previous setter to get visible range
            framesetter = [prevFreeFlowFrame setter];
            workFrame = AUTO_RELEASED_CTREF(CTFramesetterCreateFrame(framesetter, newFrameRange, path, (CFDictionaryRef)frameAttributes));
            visibleRange = CTFrameGetVisibleStringRange(workFrame);
            if (visibleRange.length < newFrameRange.length || newFrameRange.length >= maxLength) {
                stringOffsetForSetter = prevFreeFlowFrame.stringOffsetForSetter;
            }
            else {
				// Will need to use new framesetter below
                framesetter = nil;
                workFrame = nil;
            }

        }
    }
     	
    if (framesetter == nil) {
        do {
			// Create new setter and frame to get visible range
            framesetter = AUTO_RELEASED_CTREF(CTFramesetterCreateWithAttributedString((CFAttributedStringRef) [document.attributedString attributedSubstringFromRange:range]));
            workFrame = AUTO_RELEASED_CTREF(CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, (CFDictionaryRef)frameAttributes));	
            visibleRange = CTFrameGetVisibleStringRange(workFrame);            
            
            if (visibleRange.length < range.length || range.length >= maxLength) {
                stringOffsetForSetter = range.location;
               break;
            }
                        
            range.length *= 2; // pad
            if (range.length > maxLength) {
                range.length = maxLength;
            }
            
        } while (TRUE);
    }
	
	[self setSetter:framesetter];
	[self setFrame:workFrame];
		
	stringRange.location = stringOffset;
	stringRange.length = visibleRange.length;
	
	return (visibleRange.length + stringOffset);
}


- (void)refreshTextFrame {
	if (!(frameType == ASDFrameTypeTextFlow || frameType == ASDFrameTypeText))
		return;
	
	NSAttributedString* attrString = value;
	BOOL isVertical = NO;
	
	if (frameType == ASDFrameTypeTextFlow) {
		AttributedStringDoc* document = value;
		attrString = [[(AttributedStringDoc*)value attributedString] attributedSubstringFromRange:stringRange];
		isVertical = document.verticalOrientation;
	}
	// Create setter with current attributed string
	[self setSetter:AUTO_RELEASED_CTREF(CTFramesetterCreateWithAttributedString((CFAttributedStringRef) attrString))];

	NSDictionary* frameAttributes = nil;
	if (isVertical) {
		frameAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCTFrameProgressionRightToLeft] forKey:(id)kCTFrameProgressionAttributeName];
	}

	// Create and cache CTFrame for current path
	[self setFrame:AUTO_RELEASED_CTREF(CTFramesetterCreateFrame([self setter], CFRangeMake(0, 0), path, (CFDictionaryRef)frameAttributes))];
}

- (void)dealloc {
	if (path) {
		CGPathRelease(path);
	}
	if (setter) {
		CFRelease(setter);
	}
	if (frame) {
		CFRelease(frame);
	}
	[value release];
	
    [super dealloc];
}


@end

#pragma mark -
#pragma mark CoreTextViewPageInfo definition and implementation

// CoreTextViewPageInfo caches info about a document page
@interface CoreTextViewPageInfo : NSObject {
@private
	NSInteger pageNumber;
	NSArray* framesToDraw;
	NSUInteger rangeStart;
	NSUInteger rangeEnd;
    CoreTextViewFrameInfo* lastFreeFlowFrame;
	CALayer* pageLayer;
	BOOL needsRedrawOnLoad;
	BOOL needsReLayout;
}

// NSObject:description for debugging
- (NSString *)description;

- (CoreTextViewPageInfo*)initWithFramesToDraw:(NSArray*)frames pageNumber:(NSInteger)page rangeStart:(NSUInteger)rangeStart rangeEnd:(NSUInteger)rangeEnd layer:(CALayer*)layer;
- (CoreTextViewPageInfo*)initWithLayer:(CALayer*)layer pageNumber:(NSInteger)page;

@property (nonatomic) 	NSInteger pageNumber;
@property (nonatomic, retain) 	NSArray* framesToDraw;
@property (nonatomic, retain) 	CALayer* pageLayer;
@property (nonatomic) 	NSUInteger rangeStart;
@property (nonatomic) 	NSUInteger rangeEnd;
@property (nonatomic) 	BOOL needsRedrawOnLoad;
@property (nonatomic) 	BOOL needsReLayout;
@property (nonatomic, retain)   CoreTextViewFrameInfo* lastFreeFlowFrame;

@end

@implementation CoreTextViewPageInfo

@synthesize framesToDraw;
@synthesize rangeStart;
@synthesize rangeEnd;
@synthesize pageLayer;
@synthesize needsRedrawOnLoad;
@synthesize needsReLayout;
@synthesize pageNumber;
@synthesize lastFreeFlowFrame;

- (CoreTextViewPageInfo*)initWithFramesToDraw:(NSArray*)frames pageNumber:(NSInteger)page rangeStart:(NSUInteger)start rangeEnd:(NSUInteger)end layer:(CALayer*)layer {
    if (self = [super init]) {
        pageNumber = page;
        framesToDraw = [frames retain];
        rangeStart = start;
        rangeEnd = end;
        pageLayer = [layer retain];
        needsRedrawOnLoad = NO;
        needsReLayout = NO;
        lastFreeFlowFrame = nil;
    }
    return self;
}

- (CoreTextViewPageInfo*)initWithLayer:(CALayer*)layer pageNumber:(NSInteger)page {
    if (self = [super init]) {
        pageNumber = page;
        framesToDraw = nil;
        rangeStart = 0;
        rangeEnd = 0;
        pageLayer = [layer retain];
        needsRedrawOnLoad = NO;
        needsReLayout = NO;
        lastFreeFlowFrame = nil;
    }
    return self;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<CoreTextViewPageInfo %p> start: %u  end %u  layer: %p frames: %@", 
		self, rangeStart, rangeEnd, pageLayer, [framesToDraw description]];
}

- (void)dealloc {
    [lastFreeFlowFrame release];
	[framesToDraw release];
	
	[pageLayer release];
	
    [super dealloc];
}
@end

#pragma mark -
#pragma mark Local enum to index cached CoreTextViews

enum  {
	prevCoreTextView = 0,
	currCoreTextView = 1,
	nextCoreTextView = 2,
	
	coreTextViewCount = 3
};

#pragma mark -
#pragma mark CoreTextView definition 

// CoreTextView is our UIView subclass that handles content drawing
// Note that implementation continues below CoreTextScrollView as the
// classes refer to each other.
@interface CoreTextView : UIView {
	CoreTextScrollView* scrollView;
	CoreTextViewPageInfo* pageInfo;
	NSUInteger selectedFrame;
    CoreTextViewDraw* caLayerDrawDelegate;
	BOOL layoutOnlyOnDraw;
@private	
	NSMutableArray *_accessibleElements;
}

- (id)initWithScrollView:(CoreTextScrollView*)theScrollView;

// Drawing methods
- (NSArray*)framesToDrawForPage;
- (void)drawIntoLayer:(CALayer *)theLayer inContext:(CGContextRef)context;

// Marks frame closest to given position as selected
- (void)selectFrameAtPosition:(CGPoint)position;

// Accessibility-related methods
- (CGRect)accessibilityBoundingBoxForRange:(NSRange)range forFrame:(CoreTextViewFrameInfo *)frameInfo withContext:(CGContextRef)context;
- (NSMutableArray *)accessibleElements;
- (void)accessibilityUpdateElements;

// NSObject:description for logging
- (NSString*)description;
//- (void)dealloc;

@property (nonatomic) NSUInteger selectedFrame;
@property (nonatomic, retain) CoreTextScrollView* scrollView;
@property (nonatomic, retain) CoreTextViewPageInfo* pageInfo;
@property (nonatomic, readonly) CoreTextViewDraw* caLayerDrawDelegate;
@property (nonatomic) BOOL layoutOnlyOnDraw;
@end

#pragma mark -
#pragma mark AsyncLayerOperation definition

// AsyncLayerOperation is our NSOperation subclass for rendering
// CoreTextViews on a secondary thread.  
// Note that implementation continues below CoreTextScrollView as the
// classes refer to each other.
@interface AsyncLayerOperation : NSOperation
{
@private
	CoreTextScrollView* _scrollView;
	NSInteger _nextPageToLoad;
}

-(id)initWithCoreTextScrollView:(CoreTextScrollView*)scrollView forNextPageToLoad:(NSInteger)nextPageToLoad;
+(id)operationWithCoreTextScrollView:(CoreTextScrollView*)scrollView forNextPageToLoad:(NSInteger)nextPageToLoad;
@end

#pragma mark -
#pragma mark CoreTextScrollView implementation

// Private class extension interface
@interface CoreTextScrollView ()
- (CoreTextView*)loadPage:(NSInteger)pageToLoad;
- (void)loadAsyncPageAfter:(NSInteger)currentPage;
- (void)addPageToScrollView;
- (void)switchPageMovingUp:(BOOL)up;
- (void)relayoutDocFromPage:(NSInteger)pageStart;
@end

@implementation CoreTextScrollView

#pragma mark Initialization and member assignments

@synthesize document;
@synthesize pagesInfo;
@synthesize selectionRanges;
@synthesize viewOptions;
@synthesize pageCount;
@synthesize pageDisplayed;

- (void)setDocument:(id)newDocument {	
    if (document != newDocument) {
        [document release];
        document = [newDocument retain];        
    }
}

- (NSString *)description
{
	return [document fileName];
}


- (void)reset:(AttributedStringDoc*)theDoc withDelegate:(id)scrollViewDelegate {
	// Don't reset until any pending operations on previous doc are done
    [operationQueue waitUntilAllOperationsAreFinished];
	
	self.delegate = scrollViewDelegate;
    
    if (pagesInfo) {
		[pagesInfo removeAllObjects];
    } else {
		pagesInfo = [[NSMutableDictionary alloc] init];
    }
	
    // Cache the new AttributedStringDoc
    [self setDocument:theDoc];
    
	pageDisplayed = 0;
	pageCount = 0;
    [selectionRanges release];
    selectionRanges = nil;
	
	// Remove any existing cached CoreTextViews
	for (int idx=0; idx<coreTextViewCount; idx++) {
		if (pageViews[idx]) {
			[pageViews[idx] removeFromSuperview];
			[pageViews[idx] release];
			pageViews[idx] = [[CoreTextView alloc] initWithScrollView:self];
		}
	}
	
	// Load first page of doc and asynch load next page (if any)
    if (theDoc != nil) {
		[self loadPage:0];
		[self loadPage:1];
		[self loadAsyncPageAfter:1];
	}

	// Flag for redisplay
	[self setNeedsDisplay];
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        [self reset:nil withDelegate:nil];
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self != nil)
	{
		document = nil;
		
		pageDisplayed = 0;
		pageCount = 0;
		
		selectionRanges = nil;
		viewOptions = 0;
		
		pagesInfo = [[NSMutableDictionary alloc] init];
		
		// Alloc cached current and prev/next CoreTextViews
		pageViews[prevCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		pageViews[currCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		pageViews[nextCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		
		self.pagingEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.scrollsToTop = NO;		

		// init our asynch operation queue for secondary thread rendering
		operationQueue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
    CALayer *layer = [self layer];    

    [self reset:nil withDelegate:nil];
    
    // clear the view's background color so that our background
    // fits within the rounded border
    CGColorRef backgroundColor = [self.backgroundColor CGColor];
    self.backgroundColor = [UIColor clearColor];
    layer.backgroundColor = backgroundColor;
       
    [self setNeedsDisplay];
}


- (void)dealloc {    
	
	[pageViews[prevCoreTextView] release];
	[pageViews[currCoreTextView] release]; 
	[pageViews[nextCoreTextView] release];
	
	[pagesInfo release]; // no need to release the sublayers as they will be released with the main layer
	[document release];
    [operationQueue release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Selection Ranges

- (void)addSelectionRange:(NSRange)range
{
    NSArray* rangeArray = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:range.location], [NSNumber numberWithUnsignedInt:range.length], nil];
    if (selectionRanges == nil) {
        selectionRanges = [[NSMutableArray alloc] init];
    }
    
    [selectionRanges addObject:rangeArray];
	
	// Page needs to update display to show selections, if any
	[self pageNeedsDisplay:[self pageForStringOffset:range.location]];
}

- (void)clearSelectionRanges
{
	if (selectionRanges) {
		for (NSArray* rangeArr in selectionRanges) {
			// Pages with selection info will need redisplay to remove selection rects
			[self pageNeedsDisplay:[self pageForStringOffset:[[rangeArr objectAtIndex:0] unsignedIntValue]]];
		}

		[selectionRanges release];
		selectionRanges = nil;
	}
}


#pragma mark -
#pragma mark Layer/Page management


- (NSRange)stringRangeForCurrentPage {
	// Get the text range from the appropriate CoreTextViewPageInfo
	CoreTextViewPageInfo* info = [pagesInfo objectForKey:[NSNumber numberWithInt:pageDisplayed]];
	NSRange result = { info.rangeStart, info.rangeEnd - info.rangeStart};
	return result;
}


- (NSInteger)pageForStringOffset:(NSUInteger)offset {	
	// Find the appropriate CoreTextViewPageInfo for the text offset
	for (NSNumber* pageNumber in pagesInfo) {
        CoreTextViewPageInfo* page = [pagesInfo objectForKey:pageNumber];
		if (offset >= page.rangeStart && offset < page.rangeEnd) {
			return [pageNumber unsignedIntValue];
		}
	}
	
	// Page for offset not found, return something indicating error condition
	return NSUIntegerMax; 
}


- (void)pageNeedsDisplay:(NSInteger)pageNumber {
	// Flag that page needs redisplay via its CoreTextViewPageInfo
	if ([pagesInfo count] > pageNumber) {
		((CoreTextViewPageInfo*)[pagesInfo objectForKey:[NSNumber numberWithInt:pageNumber]]).needsRedrawOnLoad = YES;
	}
}


- (void)addPageToScrollView {
	pageCount += 1;
	
	// Note that self.contentSize likely triggers a call into the delegate method scrollViewDidScroll
	self.contentSize = CGSizeMake(self.frame.size.width * pageCount, self.frame.size.height);
}


- (void)loadAsyncPageAfter:(NSInteger)currentPage {   
	// Add page to be loaded to our operationQueue, which will process it on the queue thread
    [operationQueue addOperation:[AsyncLayerOperation operationWithCoreTextScrollView:self forNextPageToLoad:currentPage]];
}


- (CoreTextView*)loadPage:(NSInteger)pageToLoad {
	
	// Sanity check page index
	
    if (pageToLoad<0) {
        return NULL;
    }
    
	if (pageToLoad > 0) {
		if (pageToLoad > pageCount) {
			return NULL;
		}
		
		NSUInteger rangeMax = ((CoreTextViewPageInfo*)[pagesInfo objectForKey:[NSNumber numberWithInt:pageToLoad-1]]).rangeEnd;
		if (rangeMax) {
            if ( rangeMax >= (document.attributedString).length && ([document framesForPage:pageToLoad] == nil)) 
                return NULL;
        }
        else {
            if ([document framesForPage:pageToLoad] == nil) {
                return NULL;
            }
        }

	}
	
	BOOL isNotScratch = YES;
	CoreTextView* ctView = nil;
	// Find cached CoreTextView for page index, if applicable
	if (pageToLoad == pageDisplayed) {
		ctView = pageViews[currCoreTextView];
	}
	else if (pageToLoad < pageDisplayed && (pageToLoad+1) == pageDisplayed) {
		ctView = pageViews[prevCoreTextView];
	}
	else if (pageToLoad > pageDisplayed && (pageToLoad-1) == pageDisplayed) {
		ctView = pageViews[nextCoreTextView];
	}
	else {
		// Need to create new CoreTextView
		ctView = [[[CoreTextView alloc] initWithScrollView:self] autorelease];
		isNotScratch = NO;
	}

	if (ctView.pageInfo.needsReLayout) {
		ctView.pageInfo.needsRedrawOnLoad = YES;
	}
	
	if (ctView.pageInfo && ctView.pageInfo.needsRedrawOnLoad == NO) {
		return ctView;
	}

	// If we've already loaded & drawn the page, return the CoreTextView
	NSNumber* pageToLoadNum = [NSNumber numberWithInt:pageToLoad];
	CoreTextViewPageInfo* pageInfoEntry = (CoreTextViewPageInfo*)[pagesInfo objectForKey:pageToLoadNum];
	if (pageInfoEntry) {
		ctView.pageInfo = pageInfoEntry;
        if (pageInfoEntry.needsRedrawOnLoad == NO && pageInfoEntry.needsReLayout == NO) {
            return ctView;
        }
	}

    // Create and setup CALayer for our CoreTextView
	
	CALayer* theLayer = NULL;
	theLayer = [CALayer layer];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
	theLayer.contentsScale = [[UIScreen mainScreen] scale];
#endif
	
	CGRect bounds = [ctView bounds];
	theLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
	
	theLayer.bounds = bounds;
	theLayer.backgroundColor = [[UIColor  clearColor] CGColor];
	
	[theLayer setDelegate: ctView.caLayerDrawDelegate];
	
    CALayer* viewLayer = [ctView layer];
    NSArray* subLayers = [viewLayer sublayers];
	// Remove any previous CALayer
    for (CALayer* aSubLayer in subLayers) {
        [aSubLayer removeFromSuperlayer];
    }
	[[ctView layer] addSublayer:theLayer];
	
	theLayer.name = [NSString stringWithFormat:@"%d", pageToLoad, nil];
	
	if (ctView.pageInfo.needsReLayout || pageInfoEntry == nil) {
		// Need to re-layout text for new CoreTextViewPageInfo
		BOOL newEntry = pageInfoEntry == nil;
		pageInfoEntry = [[[CoreTextViewPageInfo alloc] initWithLayer:theLayer pageNumber:pageToLoad] autorelease];
		[pagesInfo setObject:pageInfoEntry forKey:pageToLoadNum];
		if (newEntry) {
			pageInfoEntry.needsReLayout = YES;
		}
	}
	
	ctView.pageInfo = pageInfoEntry;

	if (isNotScratch) {
		// Re-using a CoreTextView, so refresh
        [ctView setNeedsDisplay];
		[theLayer setNeedsDisplay];
		[theLayer display];	// displays the layer and fills out the rest of the info for the pageInfoEntry
		
        [ctView removeFromSuperview];

		CGRect frame = [self frame];
        frame.origin.x = frame.size.width * pageToLoad;
        frame.origin.y = 0;
        ctView.frame = frame;
        [self addSubview:ctView];

		if (pageToLoad == pageCount) {
			[self addPageToScrollView]; // only add a page to the scrollView when it is a brand new page and it is fully drawn
		}
	}
	
	return ctView;
}

- (void)setPage:(NSInteger)pageToDisplay {
	if (pageToDisplay == pageDisplayed) {
		return;
	}
	else if (pageToDisplay == pageDisplayed+1) {
		// Display next page view, which we should already have cached
		[pageViews[prevCoreTextView] removeFromSuperview];
		pageViews[prevCoreTextView].pageInfo.pageLayer = nil;
		[pageViews[prevCoreTextView] release];
		pageViews[prevCoreTextView] = nil;
		
		// Next page view is now current, previous current is now previous
		pageViews[prevCoreTextView] = pageViews[currCoreTextView];
		pageViews[currCoreTextView] = pageViews[nextCoreTextView];
		pageViews[nextCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		
		pageDisplayed = pageToDisplay;
		if ([self loadPage:pageToDisplay+1] == NULL) {
			// Could not load next page (possibly not present)
			[pageViews[nextCoreTextView] removeFromSuperview];
			pageViews[nextCoreTextView].pageInfo.pageLayer = nil;
			[pageViews[nextCoreTextView] release];
			pageViews[nextCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		}
	}
	else if (pageToDisplay == pageDisplayed-1) {
		// Display previous page view, which we should already have cached
		[pageViews[nextCoreTextView] removeFromSuperview];
		pageViews[nextCoreTextView].pageInfo.pageLayer = nil;
		[pageViews[nextCoreTextView] release];
		pageViews[nextCoreTextView] = nil;
		
		// Previous page view is now current, previous current is now next
		pageViews[nextCoreTextView] = pageViews[currCoreTextView];
		pageViews[currCoreTextView] = pageViews[prevCoreTextView];
		pageViews[prevCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		
		pageDisplayed = pageToDisplay;
		if (pageToDisplay>0) {
			[self loadPage:pageToDisplay-1];
		}
		else {
			// No previous page because we are at the start of the document
			[pageViews[prevCoreTextView] removeFromSuperview];
			pageViews[prevCoreTextView].pageInfo.pageLayer = nil;
			[pageViews[prevCoreTextView] release];
			pageViews[prevCoreTextView] = [[CoreTextView alloc] initWithScrollView:self];
		}
	}
	else {
		// Loading general page that we don't have cached
		for (NSUInteger idx=0; idx<coreTextViewCount; idx++) {
			[pageViews[idx] removeFromSuperview];
			pageViews[idx].pageInfo.pageLayer = nil;
			[pageViews[idx] release];
			pageViews[idx] = [[CoreTextView alloc] initWithScrollView:self];
		}
		
		pageDisplayed = pageToDisplay;
		if (pageToDisplay>0) {
			[self loadPage:pageToDisplay-1];
		}
		[self loadPage:pageToDisplay];
		[self loadPage:pageToDisplay+1];
	}
    
	for (NSUInteger idx=0; idx<coreTextViewCount; idx++) {
		CoreTextView* ctView = pageViews[idx];
        if(!ctView || ctView.pageInfo == nil)
            continue;
        
        NSInteger pageToLoad = ctView.pageInfo.pageNumber;

        // If there is a selected frame in a page that is not being displayed, unselect it and force a redraw
        if (pageDisplayed != pageToLoad && ctView.selectedFrame != NSUIntegerMax) {
            ctView.selectedFrame = NSUIntegerMax;
            if (ctView.pageInfo.pageLayer != nil) {
                ctView.pageInfo.pageLayer = nil;
            }
        }

		if (ctView.pageInfo.pageLayer == nil) {
			NSInteger pageToLoad = ctView.pageInfo.pageNumber;            
			
			// Create the CALayer for the CoreTextView
			
			CALayer* theLayer = NULL;
			theLayer = [CALayer layer];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
			theLayer.contentsScale = [[UIScreen mainScreen] scale];
#endif
			
			CGRect bounds = [ctView bounds];
			theLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
			
			theLayer.bounds = bounds;
			theLayer.backgroundColor = [[UIColor  clearColor] CGColor];
			
			[theLayer setDelegate: ctView.caLayerDrawDelegate];
			
            CALayer* viewLayer = [ctView layer];
            NSArray* subLayers = [viewLayer sublayers];
			// Remove any previous layer
            for (CALayer* aSubLayer in subLayers) {
                [aSubLayer removeFromSuperlayer];
            }
			[viewLayer addSublayer:theLayer];
			
			theLayer.name = [NSString stringWithFormat:@"%d", pageToLoad, nil];
			
			NSNumber* pageToLoadNum = [NSNumber numberWithInt:pageToLoad];
			CoreTextViewPageInfo* pageInfoEntry = (CoreTextViewPageInfo*)[pagesInfo objectForKey:pageToLoadNum];
			if (pageInfoEntry == NULL) {
				// Need new CoreTextViewPageInfo
				pageInfoEntry = [[[CoreTextViewPageInfo alloc] initWithLayer:theLayer pageNumber:pageToLoad] autorelease];
				[pagesInfo setObject:pageInfoEntry forKey:pageToLoadNum];
			}
			else {
				pageInfoEntry.pageLayer = theLayer;
			}
			pageInfoEntry.needsRedrawOnLoad = YES;
			
			ctView.pageInfo = pageInfoEntry;
			
			[theLayer setNeedsDisplay];
			[theLayer display];	// Displays the layer
			
			CGRect frame = [self frame];
			frame.origin.x = frame.size.width * pageToLoad;
			frame.origin.y = 0;
			ctView.frame = frame;
			[self addSubview:ctView];
		}
	}

	// Post accessibility notification letting accessibility know that major screen change has occured
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, NULL);
}


- (void)refreshPage {
	// Mark current page as needing redisplay
    CoreTextViewPageInfo* pageInfo = [pagesInfo objectForKey:[NSNumber numberWithInt:pageDisplayed]];
    pageInfo.needsRedrawOnLoad = YES;
    [self loadPage:pageDisplayed];
    [self setNeedsDisplay];
}


- (void)refreshDoc {
	// Mark all pages in doc as needing redisplay
    for (NSNumber* pageNumber in pagesInfo) {
        CoreTextViewPageInfo* pageInfo = [pagesInfo objectForKey:pageNumber];
        pageInfo.needsRedrawOnLoad = YES;
    }
    
	// Re-load current and adjacent cached pages
    [self loadPage:pageDisplayed-1];
    [self loadPage:pageDisplayed];
    [self loadPage:pageDisplayed+1];
    
    [self setNeedsDisplay];
}

-(void)switchPageMovingUp:(BOOL)up {
	// Change to prev/next page
    NSInteger newPage = pageDisplayed + (up ? 1 : -1);
    NSInteger curPageDisplayed = pageDisplayed;
    
    if (newPage >= 0 && newPage < pageCount) {
        [self setPage:newPage];
    }
    
    if (curPageDisplayed != pageDisplayed) {       
        // update the scroll view to the appropriate page
        CGRect frame = self.frame;
        frame.origin.x = frame.size.width * pageDisplayed;
        frame.origin.y = 0;
        [self scrollRectToVisible:frame animated:YES];    
    }
}

- (void)pageUp {
    [self switchPageMovingUp:YES];
}

- (void)pageDown {
    [self switchPageMovingUp:NO];
}

- (void)relayoutDoc {
	// Do not do relayout untill all secondary thread operations are finished
	[operationQueue waitUntilAllOperationsAreFinished];

	// Re-layout of cached doc text requires recreating all cached CoreTextViews 
	for (NSUInteger idx=0; idx<coreTextViewCount; idx++) {
		CoreTextView* ctView = pageViews[idx];
        if(ctView) {     
            if (ctView.pageInfo != nil) {
                ctView.pageInfo.pageLayer = nil;
            }
            [ctView removeFromSuperview];
            [ctView release];
        }
        pageViews[idx] = [[CoreTextView alloc] initWithScrollView:self];
    }
        
	// Flag for relayout of all pages
	[self relayoutDocFromPage:0];
}

- (BOOL)pageSharesAPreviousPageFrameSetter:(NSInteger)pageNumber {
	
	// Determine if page shared a framesetter from a previous page
	
	if (pageNumber < 1) 
		return NO;	
	
	CoreTextViewPageInfo* page =[pagesInfo objectForKey:[NSNumber numberWithInt:pageNumber]];
	
	NSArray* framesToDraw = page.framesToDraw;
	// If page has no frames to draw, it will not be using a framesetter at all
	if (framesToDraw == nil) 
		return NO;
	
	// see if the setter for first free flow text frame of this page matches the setter from a previous page last free flow frame 
	for (NSUInteger idx=0; idx<[framesToDraw count]; idx++) {
		CoreTextViewFrameInfo* frameInfo = [framesToDraw objectAtIndex:idx];
		if (frameInfo.frameType == ASDFrameTypeTextFlow) {
			NSInteger curPrevPage = pageNumber - 1;
			do {
				CoreTextViewPageInfo* prevPage =[pagesInfo objectForKey:[NSNumber numberWithInt:curPrevPage]];
                if (prevPage == nil) 
                    return NO;
                
				if (prevPage.lastFreeFlowFrame) 
					return ([prevPage.lastFreeFlowFrame setter] == [frameInfo setter]);
			} while (--curPrevPage > 0);
			
			break; // we've already examined the first free flow text frame for this page - no point in going on 
		}
	}
	
	return NO;
}

- (void)relayoutDocFromPage:(NSInteger)pageStart {	
	
	// It may be the case that the page that we wish to start laying out from shares the framesetter
	// with a previous page. If that is the case, then it is best to start laying out from the first
	// page that contains that framesetter. For example, if we change the font in page 9 and it shares
	// the framesetter with page 8, if we don't start laying out from page 8, page 9 will not get the
	// new font as it is using the cached framesetter from page 8 to draw
	while ([self pageSharesAPreviousPageFrameSetter:pageStart]) 
		pageStart -= 1;
    
    // If the current page displayed exceeds pageStart, then we need to reload all those pages first
    // synchrounously. Any remainging pages can be loaded asyncronously
    CoreTextViewPageInfo* page =[pagesInfo objectForKey:[NSNumber numberWithInt:pageDisplayed]];
    NSUInteger offsetToStopAt = page.rangeStart;
    NSInteger pageToStopAt = NSIntegerMax;
    if (offsetToStopAt == 0 && ([document framesForPage:pageDisplayed] != nil))
        pageToStopAt = pageDisplayed;
    
    // Remove any pages we need to relayout from memory
	NSMutableArray* pagesToRemove = [[[NSMutableArray alloc] init] autorelease];
	for (NSNumber* pageNumObj in pagesInfo) {
		page =[pagesInfo objectForKey:pageNumObj];
		if (page.pageNumber >= pageStart) {
			CALayer *aLayer = page.pageLayer;
			if (aLayer) {
                page.pageLayer = nil;
			}
            page.needsReLayout = YES;
			[pagesToRemove addObject:pageNumObj];
		}
	}
	for (NSNumber* pageNumObj in pagesToRemove) {
		[pagesInfo removeObjectForKey:pageNumObj];
        pageCount -= 1;
	}
	
    if (pageStart < pageDisplayed) {
        // process any pages we need to load synchronously
        NSInteger curPage = pageStart;
        
        while (true) {
            pageDisplayed = curPage+1;    // forces loadPage to draw the page into prevCoreTextView
            [self loadPage:curPage];
            page =[pagesInfo objectForKey:[NSNumber numberWithInt:curPage]];
            if (curPage++ == pageToStopAt || page.rangeEnd > offsetToStopAt) {
                break;
            }
        }
 		
		pageDisplayed = curPage+1;    // forces loadPage to draw the page into prevCoreTextView
		[self loadPage:curPage];

		pageDisplayed = NSIntegerMax;  // force reload of surrounding pages around curPage into appropriate views
        [self setPage:curPage-1];
        
    }
    else {
        // easy case - we are just relaying out from the current page displayed
        [self loadPage:pageDisplayed-1];
        [self loadPage:pageDisplayed];
        [self loadPage:pageDisplayed+1];        
    }

    [self loadAsyncPageAfter:pageCount - 1];
    
    // update the scroll view to the appropriate page
    CGRect frame = self.frame;
    frame.origin.x = frame.size.width * pageDisplayed;
    frame.origin.y = 0;
    [self scrollRectToVisible:frame animated:NO];    

    [self setNeedsDisplay];    
 }



#pragma mark -
#pragma mark Font Family & Font Feature/Option changes



- (void)fontFamilyChange:(NSString*)fontFamilyName {
	// Don't change font settings until all secondary thread operations are done
	[operationQueue waitUntilAllOperationsAreFinished];

	UIFont* fontSelected = [UIFont fontWithName:fontFamilyName size:12.0];
	if ([fontSelected.familyName isEqual:fontFamilyName]) {
		if (pageViews[currCoreTextView].selectedFrame == NSUIntegerMax) {
			// No selected frame, apply font change to entire doc text
			NSRange range = NSMakeRange(0, [document.attributedString length]);
			[document setFontWithName:fontSelected.fontName range:range features:(viewOptions & CoreTextViewOptionsFeatureMask)];
			[self relayoutDocFromPage:pageDisplayed];
		}
		else {
			// Change font only for selected frame
			// (note that this only applies for "text" type frames)
			CoreTextViewPageInfo* page = pageViews[currCoreTextView].pageInfo;
			CoreTextViewFrameInfo* frame = [page.framesToDraw objectAtIndex:pageViews[currCoreTextView].selectedFrame];
			if (frame.frameType == ASDFrameTypeTextFlow) {
				[document setFontWithName:fontSelected.fontName range:frame.stringRange features:(viewOptions & CoreTextViewOptionsFeatureMask)];
				[self relayoutDocFromPage:pageDisplayed];
			}
			else if (frame.frameType == ASDFrameTypeText) {
				ApplyFontNameToString(frame.value, fontSelected.fontName, frame.stringRange, (viewOptions & CoreTextViewOptionsFeatureMask));
				[frame refreshTextFrame];
				[self refreshPage];
			}
		}

	}
}

- (void)optionsChange:(NSString*)optionName {
	// Don't change font feature settings until all secondary thread operations are done
	[operationQueue waitUntilAllOperationsAreFinished];

	// Set up our font feature bitfield for given optionName
	
	ASDFeaturesBits optionBitSelected = 0;
	
	if (([optionName rangeOfString:ASD_SMALL_CAPITALS]).length > 0 ) {
		optionBitSelected = ASDFeaturesSmallCaps;
	}
	else if (([optionName rangeOfString:ASD_RARE_LIGATURES]).length > 0 ) {
		optionBitSelected = ASDFeaturesLigatures;
	}
	else if (([optionName rangeOfString:ASD_PROP_NUMBERS]).length > 0 ) {
		optionBitSelected = ASDFeaturesPropNumbers;
	}
	else if (([optionName rangeOfString:ASD_STYLISTIC_VARS]).length > 0 ) {
		optionBitSelected = ASDFeaturesStylisticVariants;
	}

	if (optionBitSelected && ((optionBitSelected & ASDFeaturesFeatureMask) != 0)) {
		// Font features are most of the time exclusive so for simplicity we allow one feature at a time
		viewOptions &= ~ASDFeaturesFeatureMask;
        viewOptions |= optionBitSelected;
	}
    else {
		// Passing @"" as the option is used to turn off all options
		if ([optionName length] == 0) {
			viewOptions = 0;
		} else {
			viewOptions ^= optionBitSelected;
		}
    }
    
	if (pageViews[currCoreTextView].selectedFrame == NSUIntegerMax) {
		// No selected frame, apply font features to all doc text
		NSRange range = NSMakeRange(0, [document.attributedString length]);
		[document setFontFeatures:(viewOptions & CoreTextViewOptionsFeatureMask) range:range];
		[self relayoutDocFromPage:pageDisplayed];
	}
	else {
		// Apply font features to selected frame
		// (note that this only applies for "text" type frames)
		CoreTextViewPageInfo* page = [pagesInfo objectForKey:[NSNumber numberWithInt:pageDisplayed]];
		CoreTextViewFrameInfo* frame = [page.framesToDraw objectAtIndex:pageViews[currCoreTextView].selectedFrame];
		if (frame.frameType == ASDFrameTypeTextFlow) {
			[document setFontFeatures:(viewOptions & CoreTextViewOptionsFeatureMask) range:frame.stringRange];
			[self relayoutDocFromPage:pageDisplayed];
		}
		else if (frame.frameType == ASDFrameTypeText) {
			ApplyFontFeaturesToString(frame.value, frame.stringRange, (viewOptions & CoreTextViewOptionsFeatureMask));
            [frame refreshTextFrame];
			[self refreshPage];
		}
	}
}



@end


#pragma mark -
#pragma mark CoreTextViewDraw definition and implementation

// CoreTextViewDraw is our UIView subclass that handles drawing
@interface CoreTextViewDraw : UIView {
    CoreTextView* target;
}

- (CoreTextViewDraw*)initWithView:(CoreTextView*)view;
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)context;

@end

@implementation CoreTextViewDraw

- (CoreTextViewDraw*)initWithView:(CoreTextView*)view {
    self = [super init];
	if ( self != nil )
	{
		target = view; // do not retain the view object as the CoreTextViewDraw object is owned by the view itself
	}
    return self;    
}

- (void)dealloc {	
    [super dealloc];
}


- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)context
{
	// our layer does the drawing
    [target drawIntoLayer:theLayer inContext:context];
}

@end

#pragma mark -
#pragma mark CoreTextView implementation

@implementation CoreTextView

@synthesize selectedFrame;
@synthesize pageInfo;
@synthesize scrollView;
@synthesize caLayerDrawDelegate;
@synthesize layoutOnlyOnDraw;

- (NSString*)description {
	return [NSString stringWithFormat:@"<CoreTextView %p> selectedFrame: %u  pageInfo: %@  Delegate %p: layoutOnDraw: %@", 
            self, selectedFrame, pageInfo, caLayerDrawDelegate, layoutOnlyOnDraw ? @"YES" : @"NO"];
}


// Helper method to reset view cached contents
- (void)reset {
	[pageInfo release];
	pageInfo = nil;
    
    if (caLayerDrawDelegate == nil) {
        caLayerDrawDelegate = [[CoreTextViewDraw alloc] initWithView:self];
    }

	// clean out the accessible elements
    [_accessibleElements removeAllObjects];
	
	// No selected frame in our view
	selectedFrame = NSUIntegerMax;
}


- (id)initWithScrollView:(CoreTextScrollView*)theScrollView {
	
	self = [super initWithFrame:theScrollView.frame];
	if ( self != nil )
	{
		scrollView = [theScrollView retain];
		caLayerDrawDelegate = [[CoreTextViewDraw alloc] initWithView:self];
		// No selected frame in our view
		selectedFrame = NSUIntegerMax;
		pageInfo = nil;
		layoutOnlyOnDraw = NO;
	}
	
	return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self != nil)
	{
		scrollView = nil;
		pageInfo = nil;
		caLayerDrawDelegate = nil;
		selectedFrame = NSUIntegerMax;
		layoutOnlyOnDraw = YES;
	}
	return self;
}


- (void)awakeFromNib
{
    CALayer *layer = [self layer];    
	
	scrollView = nil;
   [self reset];
    
    // clear the view's background color so that our background
    // fits within the rounded border
    CGColorRef backgroundColor = [self.backgroundColor CGColor];
    self.backgroundColor = [UIColor clearColor];
    layer.backgroundColor = backgroundColor;
	
    [self setNeedsDisplay];
}


- (void)dealloc { 
	[scrollView release];
	[pageInfo release];
    [caLayerDrawDelegate release];
	
    [super dealloc];
}


#pragma mark -
#pragma mark Touch handling


// Handles the start of a touch
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// For this sample, a double-tap selects a frame in the current view, if applicable
	NSUInteger numTaps = [[touches anyObject] tapCount];
	if(numTaps >= 2) {
		[self selectFrameAtPosition:[[touches anyObject] locationInView:self]];
	} 
	
	[super touchesBegan:touches withEvent:event];
}


// Marks frame closest to given position as selected
- (void)selectFrameAtPosition:(CGPoint)position {
	NSUInteger index = 0;
	
	CGRect layoutBounds = [self bounds];
	// Adjust position for CT style flipped in Y
	position.y = (layoutBounds.size.height - position.y);
	
	// Walk through frames for current view, find closest frame
	for (CoreTextViewFrameInfo* frameInfo in [self framesToDrawForPage]) {
		CGRect bounds = CGPathGetBoundingBox([frameInfo path]);
		if (CGRectContainsPoint(bounds, position)) {
			
			if (index != selectedFrame) {
				selectedFrame = index;
				[scrollView refreshPage];
			}
			else if (selectedFrame != NSUIntegerMax) {
				selectedFrame = NSUIntegerMax;
				[scrollView refreshPage];
			}
			break;
		}
		index += 1;
	}
}


#pragma mark -
#pragma mark Accessibility


- (CGRect)accessibilityBoundingBoxForRange:(NSRange)range forFrame:(CoreTextViewFrameInfo *)frameInfo withContext:(CGContextRef)context
{
	// first, we need the actual frame and the lines that are in the frame
	CTFrameRef frame = [frameInfo frame];
	NSArray* lines = (NSArray*)CTFrameGetLines(frame);
	CFRange stringRange = CFRangeMake(range.location, range.length);
	CGRect returnValue = CGRectNull;
	CFIndex lineIdx;
		
	// iterate over each line in the frame
	for ( lineIdx = 0; lineIdx < [lines count]; lineIdx++ )
	{
		CTLineRef line = (CTLineRef)[lines objectAtIndex:lineIdx];
		
		// get the full line range, and the offset for our string range
		CFRange lineRange = CTLineGetStringRange(line);
		
		// compensate for the string offseter, and compute where our range will end
		lineRange.location += frameInfo.stringOffsetForSetter;
		CFIndex lineEnd = (lineRange.location + lineRange.length);
		
		// if the range of the request string is within this line ...
		if ( stringRange.location >= lineRange.location && stringRange.location < lineEnd )
		{		
			// compute which portion of this line we want to show
			CFRange lineHighlightRange = CFRangeMake(stringRange.location - frameInfo.stringOffsetForSetter, stringRange.length);
			
			// don't go over the end of this line
			if ( stringRange.location + stringRange.length >= lineEnd )
			{
				lineHighlightRange.length = lineEnd - stringRange.location;
			}

			CGPoint lineOrigin;
			CTFrameGetLineOrigins( frame, CFRangeMake(lineIdx, 1), &lineOrigin);
					
			CGFloat offsetInLine = CTLineGetOffsetForStringIndex(line, lineHighlightRange.location, NULL);
			
			NSRange selRange = NSMakeRange(lineHighlightRange.location+frameInfo.stringOffsetForSetter, lineHighlightRange.length);
			NSAttributedString* selectionStr = [[scrollView document].attributedString attributedSubstringFromRange:selRange];
			
			CGFloat ascent, descent, leading;
			CGRect frameRect = CGPathGetBoundingBox( CTFrameGetPath(frame) );
			
			// Create a line with just our substring so that we can get the bounds
            CGRect selStringBounds;
			CTLineRef selStringLineRef = AUTO_RELEASED_CTREF(CTLineCreateWithAttributedString((CFAttributedStringRef)selectionStr));
            selStringBounds.size.width = CTLineGetTypographicBounds(selStringLineRef, NULL, NULL, NULL);
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            
            selStringBounds.origin.x = (frameRect.origin.x + offsetInLine + lineOrigin.x);
            selStringBounds.origin.y = (lineOrigin.y + frameRect.origin.y) - (descent + leading);
            selStringBounds.size.height = ascent + descent + leading;
            
			// add a bit of padding
            selStringBounds = CGRectInset(selStringBounds, -2.0, -2.0);
			
			// union this rect with our return value
			returnValue = CGRectUnion(returnValue, selStringBounds);
			
			// get out of here if there is nothing else to do
			if ( (stringRange.location + stringRange.length >= lineEnd) && 
				 ((lineIdx+1) < [lines count]) )
			{
				stringRange.location += lineHighlightRange.length;
				stringRange.length -= lineHighlightRange.length;
			}
			else
			{
				break;
			}
		}
	}
		
	returnValue.origin.y = [self bounds].size.height - (returnValue.origin.y + returnValue.size.height);
	
	return returnValue;
}


- (NSMutableArray *)accessibleElements
{
	if ( _accessibleElements != nil )
	{		
		// if the count is 0 then the elements were cleared for some reason
		// so we want to rebuild the array
		if ( [_accessibleElements count] == 0 )
		{
			[self accessibilityUpdateElements];
		}
		return _accessibleElements;
	}
	
	_accessibleElements = [[NSMutableArray alloc] init];
	
	// if we just created the array then we need to populate it
	[self accessibilityUpdateElements];
	
	return _accessibleElements;
}


- (void)accessibilityUpdateElements
{
	UIGraphicsBeginImageContext([self bounds].size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	[_accessibleElements removeAllObjects];
	
	for ( CoreTextViewFrameInfo* frameInfo in [self framesToDrawForPage] )
	{		
		// wrap a pool around this so we dont stick too much on the primary autorelease pool
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		CGRect bounds = CGPathGetBoundingBox([frameInfo path]);
		bounds.origin.y = [self bounds].size.height - (bounds.origin.y + bounds.size.height);
		
		NSString *label = nil;
		
		// First, see if there is a pre-defined label
		label = [frameInfo accessibilityLabel];
		
		if ( [label length] > 0 )
		{
			TextAccessibilityElement *accessibleElement = [[TextAccessibilityElement alloc] initWithAccessibilityContainer:self];
			[accessibleElement setAccessibilityLabel:label];			
			[accessibleElement setContextBounds:bounds];
			
			if ( [frameInfo frameType] == ASDFrameTypeTextFlow )
			{
				[accessibleElement setAccessibilityTraits:UIAccessibilityTraitImage];
			}
			[_accessibleElements addObject:accessibleElement];			
			[accessibleElement release];
			
			// we don't need to do anything else for this element, continue on
			continue;
		}
		
		id frameValue = [frameInfo value];
		
		// Get a string for the frame value
		if ( [frameValue isKindOfClass:[AttributedStringDoc class]] )
		{
			NSRange range = [frameInfo stringRange];
			label = [[[[scrollView document] attributedString] attributedSubstringFromRange:range] string];
		}
		else if ( [frameValue isKindOfClass:[NSString class]] )
		{
			label = frameValue;
		}
		else if ( [frameValue isKindOfClass:[NSAttributedString class]] )
		{
			label = [frameValue string];
		}
		
		// For text-based frames
		if ( [frameInfo frameType] == ASDFrameTypeTextFlow ||
		 	[frameInfo frameType] == ASDFrameTypeText )
		{
			// Now we want to provide paragraph-by-paragraph navigation for a VoiceOver user
			// so we are going to break up label by paragraph and make each paragraph it's own
			// accessibility element
			NSRange range = NSMakeRange(0, 0);
			NSUInteger rangeOffset = [frameInfo stringRange].location;
			
			while ( NSMaxRange(range) < [label length] )
			{
				NSUInteger start, end, contentsEnd;
				
				[label getParagraphStart:&start end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(NSMaxRange(range),0)];
				
				// Grab the string for this paragraph and trim off any extra spaces
				range = NSMakeRange(start, contentsEnd-start);						
				NSString *paragraphLabel = [label substringWithRange:range];
								
				if ( [[paragraphLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0 )
				{					
					// finally, create the accessibility element for this paragraph
					TextAccessibilityElement *accessibleElement = [[TextAccessibilityElement alloc] initWithAccessibilityContainer:self];
					
					[accessibleElement setAccessibilityLabel:paragraphLabel];
					
					CGRect rect = [self accessibilityBoundingBoxForRange:NSMakeRange(range.location + rangeOffset, range.length) forFrame:frameInfo withContext:context]; 
					
					// note that we are setting the "contextBounds" at this point. We can not
					// set the accessibilityFrame yet because we may not have a window at this point
					[accessibleElement setContextBounds:rect];
					
					[_accessibleElements addObject:accessibleElement];
					[accessibleElement release];
				}
				
				range = NSMakeRange(start, end-start);
			}
		}
		else if ( [frameInfo frameType] == ASDFrameTypePicture )
		{
			// If the picture did not already have an accessibility label, lets just use the filename
			TextAccessibilityElement *accessibleElement = [[TextAccessibilityElement alloc] initWithAccessibilityContainer:self];
			[accessibleElement setAccessibilityLabel:label];
			[accessibleElement setAccessibilityTraits:UIAccessibilityTraitImage];
			[_accessibleElements addObject:accessibleElement];
			[accessibleElement release];
		}
		
		[pool release];
	}
	
	UIGraphicsEndImageContext();
}

- (BOOL)isAccessibilityElement
{
	// CoreTextView contains accessibility elements but is not itself an accessibility element
	return NO;
}

- (NSInteger)accessibilityElementCount
{
	return [[self accessibleElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	if ( index >= 0 && index < [self accessibilityElementCount] )
	{
		return [[self accessibleElements] objectAtIndex:index];
	}
	else
	{
		return nil;
	}
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [[self accessibleElements] indexOfObject:element];
}


#pragma mark -
#pragma mark View Drawing


// Get array of the CTFrames to draw for this view
- (NSArray*)framesToDrawForPage
{
	NSMutableArray* framesToDraw = nil;
	AttributedStringDoc* theDocument = scrollView.document;
	NSMutableDictionary* thePagesInfo = scrollView.pagesInfo;
	NSInteger pageNumber = pageInfo.pageNumber;
	
	// Get the array cached from CoreTextViewPageInfo, if any
	if (thePagesInfo && [thePagesInfo count] > pageNumber) {
		framesToDraw = (NSMutableArray*)((CoreTextViewPageInfo*)[thePagesInfo objectForKey:[NSNumber numberWithInt:pageNumber]]).framesToDraw;
		if (framesToDraw) {
			return framesToDraw;
		}
	}
	
	framesToDraw = [NSMutableArray arrayWithCapacity:0];
	CGRect layoutBounds;
    
    if (([[UIScreen mainScreen] bounds]).size.width < 500) {
        // running on an iPhone
        layoutBounds = CGRectMake(IPHONE_HORIZONTAL_MARGIN, IPHONE_VERTICAL_MARGIN, 
                                  ([self bounds]).size.width - (IPHONE_HORIZONTAL_MARGIN*2),
                                  ([self bounds]).size.height - (IPHONE_VERTICAL_MARGIN*2));
    }
    else {
        // running on an iPad
        layoutBounds = CGRectMake(IPAD_HORIZONTAL_MARGIN, IPAD_VERTICAL_MARGIN, 
                                  ([self bounds]).size.width - (IPAD_HORIZONTAL_MARGIN*2),
                                  ([self bounds]).size.height - (IPAD_VERTICAL_MARGIN*2));
    }
	
	// offset drawing area slightly if we intend to draw page numbers
	if (theDocument.showPageNumbers) {
		layoutBounds.origin.y += 20;
	}
	
	CFIndex startIndex = 0;
	CFIndex curIndex = 0;
    CoreTextViewFrameInfo* prevFreeFlowFrame = nil;
	
	if (pageNumber > 0) {
        CoreTextViewPageInfo* prevPageInfo = [thePagesInfo objectForKey:[NSNumber numberWithInt:pageNumber-1]];
		curIndex = startIndex = prevPageInfo.rangeEnd;
        prevFreeFlowFrame = [prevPageInfo lastFreeFlowFrame];
    }
	
	NSArray* pageFrames = [theDocument framesForPage:pageNumber];
	if (pageFrames) {
		NSEnumerator* framesEnumerator = [pageFrames objectEnumerator];
		id frameInfo;
		while ((frameInfo = [framesEnumerator nextObject]) != NULL) {			
			
			// Update frame bounds
			CGMutablePathRef path = CGPathCreateMutable();
			CGRect frameBounds = [theDocument boundsForFrame:frameInfo];
			CoreTextViewFrameInfo* frameForDisplay = [[[CoreTextViewFrameInfo alloc] initWithFrameType:[theDocument typeForFrame:frameInfo] path:path] autorelease];
			
			[frameForDisplay setAccessibilityLabel:[theDocument accessibilityLabelForFrame:frameInfo]];
			frameBounds.origin.y = ((layoutBounds.size.height - frameBounds.origin.y) - frameBounds.size.height);
			CGPathAddRect(path, NULL, frameBounds);
			CGPathRelease(path);
			
			// Get attributed string data for frame, if applicable, and create framesetter
			id value = [theDocument objectForFrame:frameInfo];
			if (value) {
				frameForDisplay.value = value;
                
                if ([theDocument typeForFrame:frameInfo] == ASDFrameTypeText) {
                    CTFramesetterRef frameSetter = AUTO_RELEASED_CTREF(CTFramesetterCreateWithAttributedString((CFAttributedStringRef)value));
                    
                    [frameForDisplay setSetter:frameSetter];
                }
				else {
					// Not a text-based frame
					[frameForDisplay setSetter:NULL];
					[frameForDisplay setFrame:NULL];
				}
				
			}
			else if ([theDocument typeForFrame:frameInfo] == ASDFrameTypeTextFlow) {
				frameForDisplay.value = theDocument;
				curIndex = [frameForDisplay setFramesetterForStringOffset:curIndex previousFreeFlowFrame:prevFreeFlowFrame];
                prevFreeFlowFrame = frameForDisplay;
			} 
			
			[framesToDraw addObject:frameForDisplay];			
		}
	}
	else {
		
		// No previous frames, so generate our frame "layout"
		
		int column;
		NSUInteger columnCount = [theDocument columnsForPage:pageNumber];
		CGRect* columnRects = (CGRect*)calloc(columnCount, sizeof(*columnRects));
		
		// Start by setting the first column to cover the entire view.
		columnRects[0] = layoutBounds;
		
		// Divide the columns equally across the screen's width.
		CGFloat columnWidth = CGRectGetWidth(layoutBounds) / columnCount;
		for (column = 0; column < columnCount - 1; column++) {
			CGRectDivide(columnRects[column], &columnRects[column], &columnRects[column + 1], columnWidth, CGRectMinXEdge);
		}
		
		// Inset all columns by a few pixels of margin.
		for (column = 0; column < columnCount; column++) {
			columnRects[column] = CGRectInset(columnRects[column], 10.0, 10.0);
		}
		
		for (column = 0; column < columnCount; column++) {            
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathAddRect(path, NULL, columnRects[column]);
			CoreTextViewFrameInfo* frameForDisplay = [[[CoreTextViewFrameInfo alloc] initWithFrameType:ASDFrameTypeTextFlow path:path] autorelease];
			CGPathRelease(path);
			
			frameForDisplay.value = theDocument;
			curIndex = [frameForDisplay setFramesetterForStringOffset:curIndex previousFreeFlowFrame:prevFreeFlowFrame];
            prevFreeFlowFrame = frameForDisplay;
			            
			[framesToDraw addObject:frameForDisplay];			
		}
		
		free(columnRects);
        
	}
	
	CoreTextViewPageInfo* pageInfoEntry = [thePagesInfo objectForKey:[NSNumber numberWithInt:pageNumber]];;
	pageInfoEntry.framesToDraw = framesToDraw;
	pageInfoEntry.rangeStart = startIndex;
	pageInfoEntry.rangeEnd = curIndex;
    pageInfoEntry.lastFreeFlowFrame = prevFreeFlowFrame;
	
    
	return framesToDraw;
}


// Draws highlight for a specific line in a frame (line origin passed in)
- (void) hilightRangeForLine:(CTLineRef)line withLineOrigin:(CGPoint)lineOrigin inFrame:(CTFrameRef)frame forSetterStringOffset:(NSUInteger)setterStringOffset forStringRange:(CFRange)stringRange inContext:(CGContextRef)context {
	CGFloat offsetInLine = CTLineGetOffsetForStringIndex(line, stringRange.location, NULL);

	// Get the string range (including offset)
	NSRange selRange = {stringRange.location+setterStringOffset, stringRange.length };
	NSAttributedString* selectionStr = [scrollView.document.attributedString attributedSubstringFromRange:selRange];
    
	CGFloat ascent, descent, leading;
	CGRect frameRect = CGPathGetBoundingBox( CTFrameGetPath(frame) );
    
	CGRect selStringBounds;
	CTLineRef selStringLineRef = AUTO_RELEASED_CTREF(CTLineCreateWithAttributedString((CFAttributedStringRef)selectionStr));
	selStringBounds.size.width = CTLineGetTypographicBounds(selStringLineRef, NULL, NULL, NULL);
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

    // Determine line bounds given frame and line origin and typographic bounds
	selStringBounds.origin.x = (frameRect.origin.x + offsetInLine + lineOrigin.x);
	selStringBounds.origin.y = (lineOrigin.y + frameRect.origin.y) - (descent + leading);
    selStringBounds.size.height = ascent + descent + leading;    
	
	CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
	
	//Set the width of the pen mark
	CGContextSetLineWidth(context, 1.0);
	CGContextStrokeRect(context, selStringBounds);
}


// NOTE: hilightSelectedRangesForFrame does not work for Left To Right text or when a word/range splits between two frames
- (void) hilightSelectedRangesForFrame:(CoreTextViewFrameInfo*)frameInfo inContext:(CGContextRef)context {
    NSArray* selectedRanges = scrollView.selectionRanges;
    
    CTFrameRef frame = [frameInfo frame];
    CFRange frameRange = { frameInfo.stringRange.location, frameInfo.stringRange.length };    
    
	// Get and draw highlight for each line in selectedRanges
    for (NSArray* rangeArray in selectedRanges) {
        NSUInteger start = [(NSNumber*)[rangeArray objectAtIndex:0] unsignedIntValue];
        if (start >= frameRange.location && start < (frameRange.location + frameRange.length)) {
			CFRange stringRange = CFRangeMake(start, [(NSNumber*)[rangeArray objectAtIndex:1] unsignedIntValue]);
            NSArray* lines = (NSArray*)CTFrameGetLines(frame);
            CFIndex lineIdx;
            for (lineIdx=0; lineIdx<[lines count]; lineIdx++) {
                CTLineRef line = (CTLineRef)[lines objectAtIndex:lineIdx];
				CFRange lineRange = CTLineGetStringRange(line);
                lineRange.location += frameInfo.stringOffsetForSetter;
				CFIndex lineEnd = (lineRange.location + lineRange.length);
				if (stringRange.location >= lineRange.location && stringRange.location < lineEnd) {
					// found line in selectedRanges
					CFRange lineHighlightRange = CFRangeMake(stringRange.location - frameInfo.stringOffsetForSetter, stringRange.length);
					if (stringRange.location + stringRange.length >= lineEnd) {
						lineHighlightRange.length = lineEnd - stringRange.location;
					}
					
					CGPoint lineOrigin;
					CTFrameGetLineOrigins( frame, CFRangeMake(lineIdx, 1), &lineOrigin);
					[self hilightRangeForLine:line withLineOrigin:lineOrigin inFrame:frame forSetterStringOffset:frameInfo.stringOffsetForSetter forStringRange:(CFRange)lineHighlightRange inContext:context]; 
					
					if ((stringRange.location + stringRange.length >= lineEnd) && ((lineIdx+1) < [lines count])) {
						stringRange.location += lineHighlightRange.length;
						stringRange.length -= lineHighlightRange.length;
					}
					else {
						break;
					}
                    
				}
            }
        }
    }
}


- (void)drawIntoLayer:(CALayer *)theLayer inContext:(CGContextRef)context;
{
	NSInteger pageBeingDrawn = pageInfo.pageNumber; 	

	CGColorRef backgroundColor = nil;
	NSArray* pageFrames = [scrollView.document framesForPage:pageBeingDrawn];
	if (pageFrames) {
        backgroundColor = [scrollView.document copyColorForPage:pageBeingDrawn]; 
    }
	else {
		// Default to white background
		backgroundColor = [[UIColor whiteColor] CGColor];
		CFRetain(backgroundColor);
	}
	theLayer.backgroundColor = backgroundColor;
	CGColorRelease(backgroundColor);
	
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	
	// Set the usual "flipped" Core Text draw matrix
	CGContextTranslateCTM(context, 0, ([self bounds]).size.height );
	CGContextScaleCTM(context, 1.0, -1.0);
    
	static int layoutCount = 0;
	NSArray* framesToDraw = pageInfo.framesToDraw;
	if (framesToDraw == nil) {
		framesToDraw = [self framesToDrawForPage];
        layoutCount++;
	}
	NSEnumerator* framesEnumerator = [framesToDraw objectEnumerator];
	CoreTextViewFrameInfo* frameInfo;
	
	// Draw each frame
	NSUInteger frameIndex = 0;
	while ((frameInfo = [framesEnumerator nextObject]) != NULL) {
		CGPathRef path = [frameInfo path];
		ASDFrameType type = frameInfo.frameType;
		
		if ((type == ASDFrameTypeText) || (type == ASDFrameTypeTextFlow)) {
			CTFrameRef frame = [frameInfo frame];
			if (frame == NULL) {
				frame = AUTO_RELEASED_CTREF(CTFramesetterCreateFrame([frameInfo setter], CFRangeMake(0, 0), path, NULL));
				[frameInfo setFrame:frame];
			}
			if (!layoutOnlyOnDraw) {
				CTFrameDraw(frame, context);
            
				// After drawing frame, draw selected frame highlight rects
                [self hilightSelectedRangesForFrame:frameInfo inContext:context];
            }
		}
		else if (type == ASDFrameTypePicture && !layoutOnlyOnDraw) {
			// This document 'frame' is an image, so draw it using CGImage
            CGRect rect = CGPathGetBoundingBox(path);
            NSString* filePath = frameInfo.value;
			CGDataProviderRef pngDP = CGDataProviderCreateWithFilename([filePath fileSystemRepresentation]);
            if (pngDP) {
                CGImageRef img = CGImageCreateWithPNGDataProvider(pngDP, NULL, true, kCGRenderingIntentPerceptual);	// true for interpolate, false for not-interpolate
                if (img) {
                    CGContextDrawImage(context, rect, img);
                    CGImageRelease(img);
                }
                CGDataProviderRelease(pngDP);
            }
  		}
		
		// Draw user-selected frame rect, if any
		if (frameIndex == selectedFrame) {
			CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
			
			// Set the width of the pen mark
			CGContextSetLineWidth(context, 2.0);
			CGContextStrokeRect(context, CGPathGetBoundingBox(path));
		}
		
		frameIndex += 1;
	}

#if DEBUG_LAYOUT_DRAW_COUNTS
    if (TRUE) 
#else
    if (scrollView.document.showPageNumbers && !layoutOnlyOnDraw)
#endif
	{
		// Draw the page number (and debug draw counts)
        CTFontRef sysUIFont = AUTO_RELEASED_CTREF(CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 12.0, NULL));
        if (sysUIFont) {
            
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:(id)sysUIFont, (NSString*)kCTFontAttributeName, nil];
            NSAttributedString* myPageNumberString = nil;
            NSNumberFormatter * formatter = [[[NSNumberFormatter alloc] init] autorelease];
#if DEBUG_LAYOUT_DRAW_COUNTS
			static int drawCount = 0;
			drawCount++;
            NSString* pageNumber = [NSString stringWithFormat:@"%@ [L%@/D%@]", [formatter stringFromNumber: [NSNumber numberWithInt: pageBeingDrawn+1]], [formatter stringFromNumber: [NSNumber numberWithInt: layoutCount]], [formatter stringFromNumber: [NSNumber numberWithInt: drawCount]], nil];
#else
            NSString* pageNumber = [NSString stringWithFormat:@"%@", [formatter stringFromNumber: [NSNumber numberWithInt: pageBeingDrawn+1]]];
#endif
			if ( [pageNumber length] > 0 ) {
				myPageNumberString = [[[NSAttributedString alloc] initWithString:[pageNumber length] > 0 ? pageNumber : @"" attributes:attributes] autorelease];

                CTLineRef ctLine = AUTO_RELEASED_CTREF(CTLineCreateWithAttributedString((CFAttributedStringRef)myPageNumberString));
                if ( ctLine != nil )
                {
                    CGContextSetTextPosition(context, theLayer.bounds.size.width/2 - CTLineGetTypographicBounds(ctLine, NULL, NULL, NULL)/2, 20);        
                    CTLineDraw(ctLine, context);
                }
			}
        }
    }
	
	pageInfo.needsRedrawOnLoad = !layoutOnlyOnDraw;
	pageInfo.needsReLayout = NO;
}


@end


#pragma mark -
#pragma mark AsyncLayerOperation implementation


@implementation AsyncLayerOperation


-(id)init
{
	// Can only create instance with layer
	[self release];
	[NSException raise:NSInternalInconsistencyException format:@"%@: must be initialized with a layer (use -initWithLayer:)", NSStringFromClass([self class])];
	return nil;
}


-(id)initWithCoreTextScrollView:(CoreTextScrollView*)scrollView forNextPageToLoad:(NSInteger)nextPageToLoad {
	if(scrollView != nil)
	{
		self = [super init];
		if(self != nil)
		{
			_scrollView = [scrollView retain];
			_nextPageToLoad = nextPageToLoad;
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArgumentException format:@"%@: scroll view must not be nil", NSStringFromClass([self class])];
	}
	return self;
}


+(id)operationWithCoreTextScrollView:(CoreTextScrollView*)scrollView forNextPageToLoad:(NSInteger)nextPageToLoad {
	return [[[self alloc] initWithCoreTextScrollView:scrollView forNextPageToLoad:nextPageToLoad] autorelease];
}


-(void)dealloc {
	[_scrollView release];
	[super dealloc];
}


// Our NSOperation main function
-(void)main {
	if (_nextPageToLoad < 0) {
        NSLog(@"Do we not have any content to display?");
        return;
    }
    
    NSInteger currentPage = _nextPageToLoad;
    NSUInteger startPosition = ((CoreTextViewPageInfo*)[_scrollView.pagesInfo objectForKey:[NSNumber numberWithInt:currentPage++]]).rangeEnd;
    
	AttributedStringDoc* doc = _scrollView.document;
    if ( ( (startPosition < (doc.attributedString).length) || ([doc framesForPage:currentPage] != nil)) ) {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CoreTextView* ctView = [_scrollView loadPage:currentPage];
		if (ctView) {
			CALayer* theLayer = ctView.pageInfo.pageLayer;
			[CATransaction begin];
			ctView.layoutOnlyOnDraw = YES;
			[theLayer display];
			ctView.layoutOnlyOnDraw = NO;
			[CATransaction commit];
			[ctView.pageInfo.pageLayer setDelegate:nil];    // set layer delegate to nil otherwise when ctView gets released on the autorelease pool, it will try to
                                                            // message the delegate to deallocate but the delegate is already gone
			ctView.pageInfo.pageLayer = nil;                // do not cache the layer - this will also force a redraw when page is displayed
			
			[_scrollView addPageToScrollView]; // the page can now be added to the scrollView as it has been drawn
			[_scrollView loadAsyncPageAfter:currentPage];
		}
		[pool release];
    }
 
}

@end
