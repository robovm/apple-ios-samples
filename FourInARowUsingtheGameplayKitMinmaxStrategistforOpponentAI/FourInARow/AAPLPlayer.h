/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Basic class representing a player in the Four-In-A-Row game.
 */

@import UIKit;

typedef NS_ENUM(NSInteger, AAPLChip) {
    AAPLChipNone = 0,
    AAPLChipRed,
    AAPLChipBlack
};

@interface AAPLPlayer : NSObject

+ (AAPLPlayer *)redPlayer;
+ (AAPLPlayer *)blackPlayer;
+ (NSArray<AAPLPlayer *> *)allPlayers;
+ (AAPLPlayer *)playerForChip:(AAPLChip)chip;

@property (nonatomic, readonly) AAPLChip chip;
@property (nonatomic, readonly) UIColor *color;
@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, readonly) AAPLPlayer *opponent;

@end