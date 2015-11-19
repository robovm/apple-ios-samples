/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Basic class representing a player in the Four-In-A-Row game.
 */

#import "AAPLPlayer.h"

@interface AAPLPlayer ()
@property (readwrite) AAPLChip chip;
@property (nonatomic, readwrite, copy) NSString *name;
@end

@implementation AAPLPlayer

- (instancetype)initWithChip:(AAPLChip)chip {
    self = [super init];

    if (self) {
        _chip = chip;
    }
    
    return self;
}

+ (AAPLPlayer *)redPlayer {
    return [self playerForChip:AAPLChipRed];
}

+ (AAPLPlayer *)blackPlayer {
    return [self playerForChip:AAPLChipBlack];
}

+ (AAPLPlayer *)playerForChip:(AAPLChip)chip {
	if (chip == AAPLChipNone) {
		return nil;
	}
    
    // Chip enum is 0/1/2, array is 0/1.
    return [self allPlayers][chip - 1];
}

+ (NSArray<AAPLPlayer *> *)allPlayers {
    static NSArray<AAPLPlayer *> *allPlayers = nil;

    if (allPlayers == nil) {
        allPlayers = @[
           [[AAPLPlayer alloc] initWithChip:AAPLChipRed],
           [[AAPLPlayer alloc] initWithChip:AAPLChipBlack],
        ];
    }

    return allPlayers;
}

- (UIColor *)color {
    switch (self.chip) {
        case AAPLChipRed:
            return [UIColor redColor];

        case AAPLChipBlack:
            return [UIColor blackColor];
        
        default:
            return nil;
    }
}

- (NSString *)name {
    switch (self.chip) {
        case AAPLChipRed:
            return @"Red";

        case AAPLChipBlack:
            return @"Black";
        
        default:
            return nil;
    }
}

- (NSString *)debugDescription {
    switch (self.chip) {
        case AAPLChipRed:
            return @"X";

        case AAPLChipBlack:
            return @"O";
        
        default:
            return @" ";
    }
}

- (AAPLPlayer *)opponent {
    switch (self.chip) {
        case AAPLChipRed:
            return [AAPLPlayer blackPlayer];

        case AAPLChipBlack:
            return [AAPLPlayer redPlayer];
        
        default:
            return nil;
    }
}

@end
