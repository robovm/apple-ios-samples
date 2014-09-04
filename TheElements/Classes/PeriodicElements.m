/*
     File: PeriodicElements.m
 Abstract: Encapsulates the collection of elements and returns them in presorted states.
  Version: 1.12
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "PeriodicElements.h"
#import "AtomicElement.h"

@implementation PeriodicElements

// we use the singleton approach, one collection for the entire application
static PeriodicElements *sharedPeriodicElementsInstance = nil;

+ (PeriodicElements *)sharedPeriodicElements {
    @synchronized(self) {
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{ sharedPeriodicElementsInstance = [[self alloc] init]; });
    }
    return sharedPeriodicElementsInstance;
}
 
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedPeriodicElementsInstance == nil) {
            sharedPeriodicElementsInstance = [super allocWithZone:zone];
            return sharedPeriodicElementsInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// setup the data collection
- init {
	if (self = [super init]) {
		[self setupElementsArray];
	}
	return self;
}

- (void)setupElementsArray {
    
	NSDictionary *eachElement;
	
	// create dictionaries that contain the arrays of element data indexed by
	// name
	self.elementsDictionary = [NSMutableDictionary dictionary];
	// physical state
	self.statesDictionary = [NSMutableDictionary dictionary];
	// unique first characters (for the Name index table)
	self.nameIndexesDictionary = [NSMutableDictionary dictionary];

	// create empty array entries in the states Dictionary or each physical state
	[self.statesDictionary setObject:[NSMutableArray array] forKey:@"Solid"];
	[self.statesDictionary setObject:[NSMutableArray array] forKey:@"Liquid"];
	[self.statesDictionary setObject:[NSMutableArray array] forKey:@"Gas"];
	[self.statesDictionary setObject:[NSMutableArray array] forKey:@"Artificial"];
	
	// read the element data from the plist
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"Elements" ofType:@"plist"];
	NSArray *rawElementsArray = [[NSArray alloc] initWithContentsOfFile:thePath];

	// iterate over the values in the raw elements dictionary
	for (eachElement in rawElementsArray)
	{
		// create an atomic element instance for each
		AtomicElement *anElement = [[AtomicElement alloc] initWithDictionary:eachElement];
		
		// store that item in the elements dictionary with the name as the key
		[self.elementsDictionary setObject:anElement forKey:anElement.name];
		
		// add that element to the appropriate array in the physical state dictionary 
		[[self.statesDictionary objectForKey:anElement.state] addObject:anElement];
		
		// get the element's initial letter
		NSString *firstLetter = [anElement.name substringToIndex:1];
		NSMutableArray *existingArray = [self.nameIndexesDictionary valueForKey:firstLetter];
        
		// if an array already exists in the name index dictionary
		// simply add the element to it, otherwise create an array
		// and add it to the name index dictionary with the letter as the key
        //
		if (existingArray != nil)
		{
            [existingArray addObject:anElement];
		} else {
			NSMutableArray *tempArray = [NSMutableArray array];
			[self.nameIndexesDictionary setObject:tempArray forKey:firstLetter];
			[tempArray addObject:anElement];
		}
	}
	
	// create the dictionary containing the possible element states
	// and presort the states data
	self.elementPhysicalStatesArray = [NSArray arrayWithObjects:@"Solid", @"Liquid", @"Gas", @"Artificial", nil];
	[self presortElementsByPhysicalState];
	
	// presort the dictionaries now
	// this could be done the first time they are requested instead
	//
	[self presortElementInitialLetterIndexes];
	
	self.elementsSortedByNumber = [self presortElementsByNumber];
	self.elementsSortedBySymbol = [self presortElementsBySymbol];
}

// return the array of elements for the requested physical state
- (NSArray *)elementsWithPhysicalState:(NSString *)aState {
    
	return [self.statesDictionary objectForKey:aState];
}

// presort each of the arrays for the physical states
- (void)presortElementsByPhysicalState {
    
	for (NSString *stateKey in self.elementPhysicalStatesArray) {
		[self presortElementsWithPhysicalState:stateKey];
	}
}

- (void)presortElementsWithPhysicalState:(NSString *)state {
    
	NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
																   ascending:YES
																	selector:@selector(localizedCaseInsensitiveCompare:)] ;
	
	NSArray *descriptors = [NSArray arrayWithObject:nameDescriptor];
	[[self.statesDictionary objectForKey:state] sortUsingDescriptors:descriptors];
}

// return an array of elements for an initial letter (ie A, B, C, ...)
- (NSArray *)elementsWithInitialLetter:(NSString*)aKey {
    
	return [self.nameIndexesDictionary objectForKey:aKey];
}

// presort the name index arrays so the elements are in the correct order
- (void)presortElementInitialLetterIndexes {
    
	self.elementNameIndexArray = [[self.nameIndexesDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	for (NSString *eachNameIndex in self.elementNameIndexArray) {
		[self presortElementNamesForInitialLetter:eachNameIndex];
	}
}

- (void)presortElementNamesForInitialLetter:(NSString *)aKey {
    
	NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
																   ascending:YES
																	selector:@selector(localizedCaseInsensitiveCompare:)] ;
	
	NSArray *descriptors = [NSArray arrayWithObject:nameDescriptor];
	[[self.nameIndexesDictionary objectForKey:aKey] sortUsingDescriptors:descriptors];
}

// presort the elementsSortedByNumber array
- (NSArray *)presortElementsByNumber {
    
	NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"atomicNumber"
																   ascending:YES
																	selector:@selector(compare:)] ;
	
	NSArray *descriptors = [NSArray arrayWithObject:nameDescriptor];
	NSArray *sortedElements = [[self.elementsDictionary allValues] sortedArrayUsingDescriptors:descriptors];
	return sortedElements;
}

// presort the elementsSortedBySymbol array
- (NSArray *)presortElementsBySymbol {
    
	NSSortDescriptor *symbolDescriptor = [[NSSortDescriptor alloc] initWithKey:@"symbol"
																   ascending:YES
																	selector:@selector(localizedCaseInsensitiveCompare:)] ;
	
	NSArray *descriptors = [NSArray arrayWithObject:symbolDescriptor];
	NSArray *sortedElements = [[self.elementsDictionary allValues] sortedArrayUsingDescriptors:descriptors];
	return sortedElements;
}

@end