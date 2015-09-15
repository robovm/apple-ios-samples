/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Provides the table view data for the elements sorted by their standard physical state.
*/


#import "ElementsSortedByStateDataSource.h"
#import "PeriodicElements.h"
#import "AtomicElementTableViewCell.h"

@implementation ElementsSortedByStateDataSource

// protocol methods for "ElementsDataSourceProtocol"

// return the data used by the navigation controller and tab bar item

- (NSString *)name {
    
	return @"State";
}

- (NSString *)navigationBarName {
    
	return @"Grouped by State";
}

- (UIImage *)tabBarImage {
    
	return [UIImage imageNamed:@"state_gray.png"];
}

// atomic state is displayed in a grouped style tableview
- (UITableViewStyle)tableViewStyle {
    
	return UITableViewStylePlain;
} 

// return the atomic element at the index 
- (AtomicElement *)atomicElementForIndexPath:(NSIndexPath *)indexPath {
	
	// this table has multiple sections. One for each physical state
	// [solid, liquid, gas, artificial]
	// the section represents the index in the state array
	// the row the index into the array of data for a particular state
	
	// get the state
	NSString *elementState = [[PeriodicElements sharedPeriodicElements] elementPhysicalStatesArray][indexPath.section];
	
	// return the element in the state array
	return [[PeriodicElements sharedPeriodicElements] elementsWithPhysicalState:elementState][indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	AtomicElementTableViewCell *cell =
        (AtomicElementTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AtomicElementTableViewCell"];
    
	// set the element for this cell as specified by the datasource. The atomicElementForIndexPath: is declared
	// as part of the ElementsDataSource Protocol and will return the appropriate element for the index row
    //
	cell.element = [self atomicElementForIndexPath:indexPath];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    
	// this table has multiple sections. One for each physical state
	// [solid, liquid, gas, artificial]
	// return the number of items in the states array
    //
	return [[[PeriodicElements sharedPeriodicElements] elementPhysicalStatesArray] count];
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
    
	// this table has multiple sections. One for each physical state
	// [solid, liquid, gas, artificial]
	
	// get the state key for the requested section
	NSString *stateKey = [[PeriodicElements sharedPeriodicElements] elementPhysicalStatesArray][section];
	
	// return the number of items that are in the array for that state
	return [[[PeriodicElements sharedPeriodicElements] elementsWithPhysicalState:stateKey] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
	// this table has multiple sections. One for each physical state
	
	// [solid, liquid, gas, artificial]
	// return the state that represents the requested section
	// this is actually a delegate method, but we forward the request to the datasource in the view controller
	//
	return [[PeriodicElements sharedPeriodicElements] elementPhysicalStatesArray][section];
}

@end
