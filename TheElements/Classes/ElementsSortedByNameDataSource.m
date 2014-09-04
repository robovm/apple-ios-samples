/*
     File: ElementsSortedByNameDataSource.m
 Abstract: Provides the table view data for the elements sorted by name.
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

#import "ElementsSortedByNameDataSource.h"
#import "TheElementsAppDelegate.h"
#import "PeriodicElements.h"
#import "AtomicElement.h"
#import "AtomicElementTableViewCell.h"
#import "AtomicElementViewController.h"

@implementation ElementsSortedByNameDataSource

// protocol methods for "ElementsDataSourceProtocol"

// return the data used by the navigation controller and tab bar item

- (NSString *)name {
    
	return @"Name";
}

- (NSString *)navigationBarName {
    
	return @"Sorted by Name";
}

- (UIImage *)tabBarImage {
    
	return [UIImage imageNamed:@"name_gray.png"];
}

// atomic name is displayed in a plain style tableview

- (UITableViewStyle)tableViewStyle {
    
	return UITableViewStylePlain;
}

// return the atomic element at the index 
- (AtomicElement *)atomicElementForIndexPath:(NSIndexPath *)indexPath {
    
	return [[[PeriodicElements sharedPeriodicElements] elementsWithInitialLetter:[[[PeriodicElements sharedPeriodicElements] elementNameIndexArray] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AtomicElementTableViewCell *cell =
        (AtomicElementTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AtomicElementTableViewCell"];
    
	// set the element for this cell as specified by the datasource. The atomicElementForIndexPath: is declared
	// as part of the ElementsDataSource Protocol and will return the appropriate element for the index row
    //
	cell.element = [self atomicElementForIndexPath:indexPath];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
	// this table has multiple sections. One for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	// return the count of that array
	return [[[PeriodicElements sharedPeriodicElements] elementNameIndexArray] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
	// returns the array of section titles. There is one entry for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	return [[PeriodicElements sharedPeriodicElements] elementNameIndexArray];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
	return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
	// the section represents the initial letter of the element
	// return that letter
	NSString *initialLetter = [[[PeriodicElements sharedPeriodicElements] elementNameIndexArray] objectAtIndex:section];
	
	// get the array of elements that begin with that letter
	NSArray *elementsWithInitialLetter = [[PeriodicElements sharedPeriodicElements] elementsWithInitialLetter:initialLetter];
	
	// return the count
	return [elementsWithInitialLetter count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
	// this table has multiple sections. One for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	// return the letter that represents the requested section
	// this is actually a delegate method, but we forward the request to the datasource in the view controller
	//
	return [[[PeriodicElements sharedPeriodicElements] elementNameIndexArray] objectAtIndex:section];
}

@end
