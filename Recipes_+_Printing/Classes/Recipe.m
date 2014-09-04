/*
     File: Recipe.m 
 Abstract: The model object for storing information about a Recipe 
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
  
 Copyright (C) 2014 Apple Inc. All Rights Reserved. 
  
 */ 

#import "Recipe.h"

@implementation Recipe

/*
 Initialize a recipe object.
 */
- (id)init {
    self = [super init];
	if (self) {
		_ingredients = [[NSMutableArray alloc] init];
	}
	return self;
}

/*
 Release ownership.
 */

// Ingredients array setter
- (void)setIngredients:(NSMutableArray *)newIngredients {
	if (_ingredients != newIngredients) {
		_ingredients = [newIngredients mutableCopy];
	}
}

/*
 This method suplies an html representation of the recipe according to 
 the way it will be displayed when printed. The iOS Printing architecture 
 accepts an html representation via the UIMarkupTextPrintFormatter
 */
- (NSString *)htmlRepresentation {
    NSMutableString *body = [NSMutableString stringWithString:@"<!DOCTYPE html><html><body>"];
    
    if ([[self ingredients] count] > 0) {
        [body appendString:@"<h2>Ingredients</h2>"];
        [body appendString:@"<ul>"];
        for (NSDictionary *ingredient in [self ingredients]) {
            [body appendFormat:@"<li>%@ %@</li>", [ingredient objectForKey:@"amount"], [ingredient objectForKey:@"name"]];
        }
        [body appendString:@"</ul>"];
    }
    
    if ([[self instructions] length] > 0) {
        [body appendString:@"<h2>Instructions</h2>"];
        [body appendFormat:@"<p>%@</p>", [self instructions]];
    }
        
    [body appendString:@"</body></html>"];
    return body;
}

/*
 Aggregate some information in a custom way for printing. 
 Show the description, and Prep Time under the Recipe Title.
 */
- (NSString *)aggregatedInfo {
    
    NSMutableArray *infoPieces = [NSMutableArray array];
    if (self.description.length > 0) {
        [infoPieces addObject:self.description];
    }
    if (self.prepTime.length > 0) {
        [infoPieces addObject:[NSString stringWithFormat:@"Preparation Time: %@", self.prepTime]];
    }
    
    return [infoPieces componentsJoinedByString:@"\n"];
}

@end
