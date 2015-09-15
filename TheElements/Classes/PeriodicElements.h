/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Encapsulates the collection of elements and returns them in presorted states.
*/


@interface PeriodicElements : NSObject

@property (nonatomic, strong) NSMutableDictionary *statesDictionary;
@property (nonatomic, strong) NSMutableDictionary *elementsDictionary;
@property (nonatomic, strong) NSMutableDictionary *nameIndexesDictionary;
@property (nonatomic, strong) NSArray *elementNameIndexArray;
@property (nonatomic, strong) NSArray *elementsSortedByNumber;
@property (nonatomic, strong) NSArray *elementsSortedBySymbol;
@property (nonatomic, strong) NSArray *elementPhysicalStatesArray;

+ (PeriodicElements*)sharedPeriodicElements;

- (NSArray *)elementsWithPhysicalState:(NSString*)aState;
- (NSArray *)elementsWithInitialLetter:(NSString*)aKey;

@end
