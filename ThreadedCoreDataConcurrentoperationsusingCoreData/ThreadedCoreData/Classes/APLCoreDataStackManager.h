/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Singleton controller to manage the main Core Data stack for the application.
 */

@import CoreData;
@import Foundation;

@interface APLCoreDataStackManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

