/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Basic class representing the Four-In-A-Row game board.
 */

@import Foundation;

#import "AAPLPlayer.h"

const static NSInteger AAPLCountToWin = 4;

@interface AAPLBoard : NSObject

@property AAPLPlayer *currentPlayer;

+ (NSInteger)width;
+ (NSInteger)height;

- (AAPLChip)chipInColumn:(NSInteger)column row:(NSInteger)row;
- (BOOL)canMoveInColumn:(NSInteger)column;
- (void)addChip:(AAPLChip)chip inColumn:(NSInteger)column;
- (BOOL)isFull;

- (NSArray<NSNumber *> *)runCountsForPlayer:(AAPLPlayer *)player;

- (void)updateChipsFromBoard:(AAPLBoard *)otherBoard;

@end
