/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Provides the table view data for the elements sorted by atomic symbol.
*/


#import "ElementsSortedBySymbolDataSource.h"
#import "PeriodicElements.h"
#import "AtomicElementTableViewCell.h"

@implementation ElementsSortedBySymbolDataSource

// protocol methods for "ElementsDataSourceProtocol"

// return the data used by the navigation controller and tab bar item

- (NSString *)navigationBarName {
    
	return @"Sorted by Atomic Symbol";
}

- (NSString *)name {
    
	return @"Symbol";
}

- (UIImage *)tabBarImage {
    
	return [UIImage imageNamed:@"symbol_gray.png"];
}

// atomic number is displayed in a plain style tableview
- (UITableViewStyle)tableViewStyle {
    
	return UITableViewStylePlain;
}

// return the atomic element at the index in the sorted by symbol array
- (AtomicElement *)atomicElementForIndexPath:(NSIndexPath *)indexPath {
    
	return [[PeriodicElements sharedPeriodicElements] elementsSortedBySymbol][indexPath.row];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
	// this table has only one section
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
    
	// get the shared elements object
	// ask for, and return, the number of elements in the array of elements sorted by symbol
	
	return [[[PeriodicElements sharedPeriodicElements] elementsSortedBySymbol] count];
}

@end
