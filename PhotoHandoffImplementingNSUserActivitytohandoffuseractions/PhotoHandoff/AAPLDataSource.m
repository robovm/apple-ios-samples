/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLDataSource.h"

@interface AAPLDataSource ()
@property (nonatomic, strong) NSDictionary *data;
@end


#pragma mark -

@implementation AAPLDataSource

- (instancetype)init {
    
    self = [super init];
    if (self != nil) {
        NSString *pathToData = [[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"];
        self.data = [NSDictionary dictionaryWithContentsOfFile:pathToData];
    }
    return self;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return 32;
}

- (NSString *)identifierForIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%ld", (long)indexPath.row];
}

- (NSString *)titleForIdentifier:(NSString *)identifier {
    
    NSString *title = identifier ? (self.data)[identifier] : nil;
    if (title == nil) {
        title = @"Image";
    }
    return title;
}

- (UIImage *)thumbnailForIdentifier:(NSString *)identifier {
    
    if (identifier == nil) {
        return nil;
    }
    NSString *pathToImage = [[NSBundle mainBundle] pathForResource:identifier ofType:@"JPG"];
    return [[UIImage alloc] initWithContentsOfFile:pathToImage];
}

- (UIImage *)imageForIdentifier:(NSString *)identifier {
    
    if (identifier == nil) {
        return nil;
    }
    NSString *imageName = [NSString stringWithFormat:@"%@_full", identifier];
    NSString *pathToImage = [[NSBundle mainBundle] pathForResource:imageName ofType:@"JPG"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:pathToImage];
    return image;
}

@end
