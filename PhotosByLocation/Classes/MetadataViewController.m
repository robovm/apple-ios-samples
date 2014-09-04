/*
     File: MetadataViewController.m 
 Abstract: n/a 
  Version: 1.2 
  
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

#import "MetadataViewController.h"

#import <CoreLocation/CoreLocation.h>

@interface MetadataViewController()
- (NSString *)formattedMetadataFromAssetMetadata:(NSDictionary *)assetMetadata;
@end

@implementation MetadataViewController

@synthesize delegate;
@synthesize asset;

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableDictionary *assetMetadata = [[[asset defaultRepresentation] metadata] mutableCopy];
    CLLocation *assetLocation = [asset valueForProperty:ALAssetPropertyLocation];
    NSDictionary *gpsData = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithDouble:[assetLocation coordinate].longitude], @"Longitude", [NSNumber numberWithDouble:[assetLocation coordinate].latitude], @"Latitude", nil];
    [assetMetadata setObject:gpsData forKey:@"Location Information"];
    [gpsData release];
    
    [metadataTextView loadHTMLString:[self formattedMetadataFromAssetMetadata:assetMetadata] baseURL:nil];
    
    [assetMetadata release];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.asset = nil;
    
    [super dealloc];
}

- (void)done:(id)sender {
    [delegate dismissMetadataViewController];
}


#pragma mark -
#pragma mark Helper methods

static NSString *sHTMLHeader = @"<html><body>";
static NSString *sHTMLFooter = @"</body></html>";
static NSString *sHTMLTab = @"&nbsp;&nbsp;&nbsp;&nbsp;";

- (NSString *)formattedDictionaryValue:(id)value key:(NSString *)key tabCount:(NSUInteger)tabCount tabs:(NSString *)tabs {

    NSMutableString *resultingString = [NSMutableString string];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        [resultingString appendFormat:@"<p>%@%@:<b>==></b></p>", tabs, key];
        NSUInteger newTabCount = tabCount + 1;
        NSMutableString *newTabs = [NSMutableString stringWithString:tabs];
        [newTabs appendString:sHTMLTab];
        NSDictionary *section = (NSDictionary *)value;
        for (NSString *sectionKey in section) {
            id sectionValue = [section objectForKey:sectionKey];
            [resultingString appendString:[self formattedDictionaryValue:sectionValue key:sectionKey tabCount:newTabCount tabs:newTabs]];
        }
        
    } else {
        [resultingString appendFormat:@"<p>%@%@:<b>%@</b></p>", tabs, key, value];
    }
    
    return resultingString;
    
}

- (NSString *)formattedMetadataFromAssetMetadata:(NSDictionary *)assetMetadata {
    
    
    NSUInteger tabDepth = 0;
    NSString *currentTabs = @"";
    
    NSMutableString *formattedMetadata = [NSMutableString string];
    [formattedMetadata appendString:sHTMLHeader];
    
    for (NSString *key in assetMetadata) {
        id value = [assetMetadata objectForKey:key];
        [formattedMetadata appendString:[self formattedDictionaryValue:value key:key tabCount:tabDepth tabs:currentTabs]];
    }
    
    [formattedMetadata appendString:sHTMLFooter];
    
    NSLog(@"formatted metadata = %@", formattedMetadata);
    
    return formattedMetadata;
    
//    NSString *description = @"\nKey:value\nSection\n\tkey:value\n\tkey2:value2";
//    NSString *html = @"<html><body><h1>The Meaning of Life</h1><p>...really is <b>42</b>!</p></body></html>";
//    return html;
//    return [assetMetadata description];
}

@end
