
/*
     File: FontFamsController.m
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


#import "FontFamsController.h"
#import "AttributedStringDoc.h"

#import "CoreText/CoreText.h"

#pragma mark -
#pragma mark FontNameAndFeatures 

// Simple data-holder class that contains a font name as presented by the
// UI and a bitset of valid font features for the given font
@interface FontNameAndFeatures : NSObject
{
	NSString       *fontName;
	ASDFeaturesBits featureBits; 
}
@property (nonatomic, retain) NSString *fontName;
@property (nonatomic) ASDFeaturesBits featureBits;

- (id)initWithFontName:(NSString *)fontName;
- (NSComparisonResult)localizedCaseInsensitiveCompare:(FontNameAndFeatures *)aFontNameAndFeatures;
@end

@implementation FontNameAndFeatures

@synthesize fontName, featureBits;

// Convenience init for specified font
- (id)initWithFontName:(NSString *)theFontName
{
    if((self = [super init])) {
		self.fontName = theFontName;
		// Look up the font and its feature set
		featureBits = 0;
		CTFontRef fontRef = CTFontCreateWithName((CFStringRef)fontName, 12., NULL);
		CFArrayRef fontFeatureArray = CTFontCopyFeatures(fontRef);
		if (fontFeatureArray) {
			int fontFeatureArrayCount = CFArrayGetCount(fontFeatureArray);
			for (int fontFeatureArrayIndex = 0; fontFeatureArrayIndex < fontFeatureArrayCount; fontFeatureArrayIndex++) {
				NSDictionary *fontFeatureDictionary = (NSDictionary *)CFArrayGetValueAtIndex( fontFeatureArray, 
																							 fontFeatureArrayIndex );
				NSString* featureName = [fontFeatureDictionary objectForKey:(NSString*)kCTFontFeatureTypeNameKey];
				// NOTE: For UI purposes, we don't distinguish "exclusive" vs "non-exclusive" features (determined via
				// looking for kCTFontFeatureTypeExclusiveKey in the feature dictionary) -- in other words, we will
				// end up treating all features as exclusive in the UI by only allowing the user to select a single feature
				// per font.
				if ([featureName isEqual:ASD_SMALL_CAPITALS]) {
					featureBits |= ASDFeaturesSmallCaps;
				} 
				else if ([featureName isEqual:@"Ligatures"]) {
					featureBits |= ASDFeaturesLigatures;
				}
				else if ([featureName isEqual:@"Number Spacing"]) {
					featureBits |= ASDFeaturesPropNumbers;
				}
				else if ([featureName isEqual:@"Letter Case"]) {
					// We treat "letter case" as equivalent to small caps for this sample
					featureBits |= ASDFeaturesSmallCaps;
				}
				else if ([featureName isEqual:ASD_STYLISTIC_VARS]) {	
					// Only expected to be present in Zapfino for this sample
					featureBits |= ASDFeaturesStylisticVariants;
				}
			}
			CFRelease(fontFeatureArray);
		}
		CFRelease(fontRef);		
    }
    return self;
}

// Comparison method used for sorting fonts in UI list
- (NSComparisonResult)localizedCaseInsensitiveCompare:(FontNameAndFeatures *)aFontNameAndFeatures {
	return ([self.fontName localizedCaseInsensitiveCompare:aFontNameAndFeatures.fontName]);
}

@end

#pragma mark -
#pragma mark FontFamsController 

@implementation FontFamsController

@synthesize delegate, fontFamsForDisplay, selectedFontFam, selectedFontFeature;

// Helper method to grab featureBits for currently selected font
- (ASDFeaturesBits)featureBitsForCurrentSelectedFont {
	ASDFeaturesBits featureBits = 0;
	for (FontNameAndFeatures *fontNameAndFeatures in fontFamsForDisplay) {
		if ([selectedFontFam isEqual:fontNameAndFeatures.fontName]) {
			featureBits = fontNameAndFeatures.featureBits;
		}
	}
	return featureBits;
}

// Helper method to unselect all fonts in the UI -- used when the user switches samples
- (void)deselectAllFonts {
	// Mark all fonts and features in our tableview as unselected.
	// This happens when the user selects a different text sample, which
	// initially will use the fonts and styles contained in the text sample.
	selectedFontFam = @"";
	selectedFontFeature = 0;
	// Update tableview cells to reflect our selection state
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Fonts and Features";
    self.contentSizeForViewInPopover = CGSizeMake(300.0, 560.0);

    // filter out the available font families to the specified set below - note 
	// some platforms may not have all the requested fonts installed 
    NSSet* fontCandidatesSet = [NSSet setWithObjects:
                        @"BodoniSvtyTwoITCTT-Book", //use PostScript names in CTFontCreateWithName() for best performance
                        @"BitstreamVeraSansMono-Roman",
                        @"Didot",
                        @"Futura-Medium",
                        @"Helvetica",
                        @"HoeflerText-Regular",
                        @"Zapfino",
                        nil ];
    NSMutableSet* familiesSet = [NSMutableSet setWithArray:[UIFont familyNames]];
    [familiesSet intersectSet:fontCandidatesSet];
	NSMutableArray *fontFamsForDisplayMutable = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *enumerator = [familiesSet objectEnumerator];
	FontNameAndFeatures *fontNameAndFeatures;
	NSString *candidateName;
	while ((candidateName = [enumerator nextObject])) {
		// Note that more sanity checking is needed for cases where font is not present on system
		fontNameAndFeatures = [[FontNameAndFeatures alloc] initWithFontName:candidateName];
		[fontFamsForDisplayMutable addObject:fontNameAndFeatures];
		[fontNameAndFeatures release];
	}  
	
	fontFamsForDisplay = [[NSArray arrayWithArray:[fontFamsForDisplayMutable sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]] retain];    
    
	// Note that at viewDidLoad, none of the fonts are treated as "selected", because the default
	// behavior is to use whatever font (or fonts) are contained within the current sample document data.
	selectedFontFam = @"";
	selectedFontFeature = 0;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Font and Font features, although the latter for some fonts may have no feature enabled
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [fontFamsForDisplay count];
	} else if (section == 1) {
		return 4; // always display 4 features, but we will disable/enable depending on the currently selected font
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return @"Fonts";
	} else if (section == 1) {
		return @"Font Features";
	}
	return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.enabled = YES;
    
	if (indexPath.section == 0) {	
		// For Fonts section, set the cell text to the font name
		FontNameAndFeatures *fontNameAndFeatures = [fontFamsForDisplay objectAtIndex:indexPath.row];
		NSString *fontName = fontNameAndFeatures.fontName;
		if ([selectedFontFam isEqual:fontNameAndFeatures.fontName]) {
			// Mark that this is the currently active font
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		cell.textLabel.text = fontName;
		cell.textLabel.font = [UIFont fontWithName:fontName size:17.0];
	} else if (indexPath.section == 1) {
		// For Font Features section, set the cell text to font feature, and select,
		// disable/enable as necessary
		cell.textLabel.font = [UIFont systemFontOfSize:17.0];
		ASDFeaturesBits featureBits = [self featureBitsForCurrentSelectedFont];
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = ASD_SMALL_CAPITALS;
				if (! (featureBits & ASDFeaturesSmallCaps)) {
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.textLabel.enabled = NO;
				}
				if (selectedFontFeature == ASDFeaturesSmallCaps) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				}
				break;
			case 1:
				cell.textLabel.text = ASD_RARE_LIGATURES;
				if (! (featureBits & ASDFeaturesLigatures)) {
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.textLabel.enabled = NO;
				}
				if (selectedFontFeature == ASDFeaturesLigatures) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				}
				break;
			case 2:
				cell.textLabel.text = ASD_PROP_NUMBERS;
				if (! (featureBits & ASDFeaturesPropNumbers)) {
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.textLabel.enabled = NO;
				}
				if (selectedFontFeature == ASDFeaturesPropNumbers) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				}
				break;
			case 3:
				cell.textLabel.text = ASD_STYLISTIC_VARS;
				if (! (featureBits & ASDFeaturesStylisticVariants)) {
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.textLabel.enabled = NO;
				}
				if (selectedFontFeature == ASDFeaturesStylisticVariants) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				}
				break;
			default:
				cell.textLabel.text = @"";
				break;
		}
	}
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Notify the delegate if a row is selected.
	if (indexPath.section == 0) {
		FontNameAndFeatures *fontNameAndFeatures = [fontFamsForDisplay objectAtIndex:indexPath.row];
		// Track newly selected font for UI.  Note that we do not mark font-features as unselected
		// upon selection of new font -- the UI currently tracks these independently based on 
		// how CoreTextScrollView keeps track of the current viewOptions.  This can result in 
		// displaying a "selected but disabled" font feature in cases where the previously 
		// selected font feature is not supported in the newly selected font.
		self.selectedFontFam = fontNameAndFeatures.fontName;
		// call reloadData to properly show selection accessory view for new cell and
		// remove it for previous selected cell (if any)
		[self.tableView reloadData];
		if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectString:)]) {		
			[delegate fontFamsController:self didSelectString:fontNameAndFeatures.fontName];
		}
	} else if (indexPath.section == 1) {
		ASDFeaturesBits featureBits = [self featureBitsForCurrentSelectedFont];
		switch (indexPath.row) {
			case 0:
				if (featureBits & ASDFeaturesSmallCaps) {
					if (selectedFontFeature == ASDFeaturesSmallCaps) {
						// was previously the selected font feature, so de-select it and update
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:@""];
						}
						selectedFontFeature = 0;
					} else {
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:ASD_SMALL_CAPITALS];
						}
						selectedFontFeature = ASDFeaturesSmallCaps;
					}
					[self.tableView reloadData];
				}
				break;
			case 1:
				if (featureBits & ASDFeaturesLigatures) {
					if (selectedFontFeature == ASDFeaturesLigatures) {
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:@""];
						}
						selectedFontFeature = 0;
					} else {
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:ASD_RARE_LIGATURES];
						}
						selectedFontFeature = ASDFeaturesLigatures;
					}
					[self.tableView reloadData];
				}
				break;
			case 2:
				if (featureBits & ASDFeaturesPropNumbers) {
					if (selectedFontFeature == ASDFeaturesPropNumbers) {
						// was previously the selected font feature, so de-select it and update
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:@""];
						}
						selectedFontFeature = 0;
					} else {
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:ASD_PROP_NUMBERS];
						}
						selectedFontFeature = ASDFeaturesPropNumbers;
					}
					[self.tableView reloadData];
				}
				break;
			case 3:
				if (featureBits & ASDFeaturesStylisticVariants) {
					if (selectedFontFeature == ASDFeaturesStylisticVariants) {
						// was previously the selected font feature, so de-select it and update
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:@""];
						}
						selectedFontFeature = 0;
					} else {
						if (delegate && [delegate respondsToSelector:@selector(fontFamsController:didSelectFeaturesString:)]) {		
							[delegate fontFamsController:self didSelectFeaturesString:ASD_STYLISTIC_VARS];
						}
						selectedFontFeature = ASDFeaturesStylisticVariants;
					}
					[self.tableView reloadData];
				}
				break;
			default:
				break;
		}		
	}
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [fontFamsForDisplay release];
    [super dealloc];
}


@end

