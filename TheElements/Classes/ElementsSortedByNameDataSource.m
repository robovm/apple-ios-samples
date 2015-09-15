/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Provides the table view data for the elements sorted by name.
*/


#import "ElementsSortedByNameDataSource.h"
#import "PeriodicElements.h"
#import "AtomicElementTableViewCell.h"


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
    
	return [[PeriodicElements sharedPeriodicElements] elementsWithInitialLetter:[[PeriodicElements sharedPeriodicElements] elementNameIndexArray][indexPath.section]][indexPath.row];
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
	NSString *initialLetter = [[PeriodicElements sharedPeriodicElements] elementNameIndexArray][section];
	
	// get the array of elements that begin with that letter
	NSArray *elementsWithInitialLetter = [[PeriodicElements sharedPeriodicElements] elementsWithInitialLetter:initialLetter];
	
	// return the count
	return elementsWithInitialLetter.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
	// this table has multiple sections. One for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	// return the letter that represents the requested section
	// this is actually a delegate method, but we forward the request to the datasource in the view controller
	//
	return [[PeriodicElements sharedPeriodicElements] elementNameIndexArray][section];
}

@end
