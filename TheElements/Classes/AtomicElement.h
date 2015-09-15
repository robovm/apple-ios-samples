/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Simple object that encapsulate the Atomic Element values and images for the states.
*/

@interface AtomicElement : NSObject

@property (nonatomic, strong) NSNumber *atomicNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *symbol;
@property (nonatomic, strong) NSString *state;
@property (weak, readonly) UIImage *flipperImageForAtomicElementNavigationItem;
@property (weak, readonly) UIImage *stateImageForAtomicElementTileView;
@property (weak, readonly) UIImage *stateImageForAtomicElementView;
@property (nonatomic, strong) NSString *atomicWeight;
@property (nonatomic, strong) NSNumber *group;
@property (nonatomic, strong) NSNumber *period;
@property (nonatomic, strong) NSString *discoveryYear;

- (instancetype)initWithDictionary:(NSDictionary *)aDictionary;

@end
