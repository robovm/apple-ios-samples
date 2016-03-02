/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays the address data in the placemark acquired from the reverse geocoder.
 */

#import "PlacemarkViewController.h"

@implementation PlacemarkViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	// Get the thoroughfare table cell and set the detail text to show the thoroughfare.
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.detailTextLabel.text = self.placemark.thoroughfare;
    
	// Get the sub-thoroughfare table cell and set the detail text to show the sub-thoroughfare.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    cell.detailTextLabel.text = self.placemark.subThoroughfare;

	// Get the locality table cell and set the detail text to show the locality.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    cell.detailTextLabel.text = self.placemark.locality;

	// Get the sub-locality table cell and set the detail text to show the sub-locality.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    cell.detailTextLabel.text = self.placemark.subLocality;

	// Get the administrative area table cell and set the detail text to show the administrative area.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    cell.detailTextLabel.text = self.placemark.administrativeArea;

	// Get the sub-administrative area table cell and set the detail text to show the sub-administrative area.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    cell.detailTextLabel.text = self.placemark.subAdministrativeArea;

	// Get the postal code table cell and set the detail text to show the postal code.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    cell.detailTextLabel.text = self.placemark.postalCode;

	// Get the country table cell and set the detail text to show the country.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]];
    cell.detailTextLabel.text = self.placemark.country;

	// Get the ISO country code table cell and set the detail text to show the ISO country code.
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:8 inSection:0]];
    cell.detailTextLabel.text = self.placemark.ISOcountryCode;
    
	// Tell the table to reload section zero of the table.
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

@end

