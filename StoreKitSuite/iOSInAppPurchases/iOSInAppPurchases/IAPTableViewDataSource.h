/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An object that adopts IAPTableViewDataSource must reload its UI with the provided data.
 
 */


@protocol IAPTableViewDataSource <NSObject>

// Tells the receiver to reload its UI with the provided data
-(void)reloadUIWithData:(NSMutableArray *)data;

@end