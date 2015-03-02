/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Data Source to manage assets used by this application
  
 */

#import <Foundation/Foundation.h>

@interface AAPLDataSource : NSObject <UIStateRestoring>

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (NSString *)identifierForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)titleForIdentifier:(NSString *)identifier;
- (UIImage *)thumbnailForIdentifier:(NSString *)identifier;
- (UIImage *)imageForIdentifier:(NSString *)identifier;

@end
