/*
     File: RecipesController.m 
 Abstract: A controller object for managing a set of Recipe objects 
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

#import "RecipesController.h"
#import "Recipe.h"

static NSString *DataFilename = @"Recipes.archive";

@interface RecipesController (DemoData)
- (void)createDemoData;
@end

@implementation RecipesController
{
    NSMutableIndexSet *selectedIndexes;
}

/*
 Since this sample is intended to focus more on printing versus Core Data demonstration, see the
 sample code titled iPhoneCoreDataRecipes for more information on creating custom UITableViewCells.
 */

- (id)init {
	if ((self = [super init])) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		if ([paths count] == 0) {
			[self createDemoData];
		} else {		
			NSString *documentsDirectory = [paths objectAtIndex:0];
			NSString *appFile = [documentsDirectory stringByAppendingPathComponent:DataFilename];

			NSFileManager *fm = [NSFileManager defaultManager];
			if (/*0 && */[fm fileExistsAtPath:appFile]) {
				_recipes = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
			} else {		
				[self createDemoData];
			}
		}
        [self sortAlphabeticallyAscending:YES];
        
        selectedIndexes = [[NSMutableIndexSet alloc] init];
	}
	return self;
}

- (void)sortAlphabeticallyAscending:(BOOL)ascending {    
    NSSortDescriptor *sortInfo = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:ascending];
    [self.recipes sortUsingDescriptors:[NSArray arrayWithObject:sortInfo]];
}

/*
 Create the recipe objects and initialize them from the Recipes.plist file on the app bundle
 */
- (void)createDemoData {
	_recipes = [[NSMutableArray alloc] init];
	NSArray *recipeDictionaries = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"plist"]];
	
	NSArray *propertyNames = [[NSArray alloc] initWithObjects:@"name", @"description", @"prepTime", @"instructions", @"ingredients", nil];
	
	for (NSDictionary *recipeDictionary in recipeDictionaries) {
		
		Recipe *newRecipe = [[Recipe alloc] init];
		for (NSString *property in propertyNames) {
			[newRecipe setValue:[recipeDictionary objectForKey:property] forKey:property];
		}
		
		NSString *imageName = [recipeDictionary objectForKey:@"imageName"];
		newRecipe.image = [UIImage imageNamed:imageName];
		
		imageName = [[imageName stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail.png"];
		newRecipe.thumbnailImage = [UIImage imageNamed:imageName];

		[_recipes addObject:newRecipe];
	}
}

- (unsigned)countOfRecipes {
    return [_recipes count];
}

- (id)objectInRecipesAtIndex:(unsigned)theIndex {
    return [_recipes objectAtIndex:theIndex];
}


@end
