/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Additions to the game model classes adding GameplayKit protocols for use with the minmax strategist.
 */

@import GameplayKit;

#import "AAPLPlayer.h"
#import "AAPLBoard.h"

@interface AAPLMove : NSObject <GKGameModelUpdate>

// Required by GKGameModelUpdate for storing move ratings during GKMinmaxStrategist move selection.
@property (nonatomic) NSInteger value;

// Identifies the column in which to make a move.
@property (nonatomic) NSInteger column;

+ (AAPLMove *)moveInColumn:(NSInteger)column;

@end

@interface AAPLPlayer (AAPLMinmaxStrategy) <GKGameModelPlayer>
@end

@interface AAPLBoard (AAPLMinmaxStrategy) <GKGameModel>
@end