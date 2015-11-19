/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Basic class representing the Four-In-A-Row game board.
 */

#import "AAPLBoard.h"

const static NSInteger AAPLBoardWidth = 7;
const static NSInteger AAPLBoardHeight = 6;

@implementation AAPLBoard {
    AAPLChip _cells[AAPLBoardWidth * AAPLBoardHeight];
}

+ (NSInteger)width {
	return AAPLBoardWidth;
}

+ (NSInteger)height {
	return AAPLBoardHeight;
}

- (instancetype)init {
	self = [super init];

    if (self) {
		_currentPlayer = [AAPLPlayer redPlayer];
	}
	
    return self;
}

- (void)updateChipsFromBoard:(AAPLBoard *)otherBoard {
	memcpy(_cells, otherBoard->_cells, sizeof(_cells));
}

- (AAPLChip)chipInColumn:(NSInteger)column row:(NSInteger)row {
    return _cells[row + column * AAPLBoardHeight];
}

- (void)setChip:(AAPLChip)chip inColumn:(NSInteger)column row:(NSInteger)row {
    _cells[row + column * AAPLBoardHeight] = chip;
}

- (NSString *)debugDescription {
    NSMutableString *output = [NSMutableString string];

    for (NSInteger row = AAPLBoardHeight - 1; row >= 0; row--) {
        for (NSInteger column = 0; column < AAPLBoardWidth; column++) {
            AAPLChip chip = [self chipInColumn:column row:row];
            
            NSString *playerDescription = [AAPLPlayer playerForChip:chip].debugDescription ?: @" ";
            [output appendString:playerDescription];
            
			NSString *cellDescription = (column + 1 < AAPLBoardWidth) ? @"." : @"";
            [output appendString:cellDescription];
        }
    
        [output appendString:((row > 0) ? @"\n" : @"")];
    }

    return output;
}

- (NSInteger)nextEmptySlotInColumn:(NSInteger)column {
    for (NSInteger row = 0; row < AAPLBoardHeight; row++) {
        if ([self chipInColumn:column row:row] == AAPLChipNone) {
            return row;
        }
    }
    
    return -1;
}

- (BOOL)canMoveInColumn:(NSInteger)column {
    return [self nextEmptySlotInColumn:column] >= 0;
}

- (void)addChip:(AAPLChip)chip inColumn:(NSInteger)column {
    NSInteger row = [self nextEmptySlotInColumn:column];

    if (row >= 0) {
        [self setChip:chip inColumn:column row:row];
    }
}

- (BOOL)isFull {
    for (NSInteger column = 0; column < AAPLBoardWidth; column++) {
        if ([self canMoveInColumn:column]) {
            return NO;
        }
    }

    return YES;
}

- (NSArray<NSNumber *> *)runCountsForPlayer:(AAPLPlayer *)player {
	AAPLChip chip = player.chip;
	NSMutableArray<NSNumber *> *counts = [NSMutableArray array];
	
    // Detect horizontal runs.
    for (NSInteger row = 0; row < AAPLBoardHeight; row++) {
        NSInteger runCount = 0;
        for (NSInteger column = 0; column < AAPLBoardWidth; column++) {
            if ([self chipInColumn:column row:row] == chip) {
				++runCount;
			}
            else {
                // Run isn't continuing, note it and reset counter.
				if (runCount > 0) {
					[counts addObject:@(runCount)];
				}
                runCount = 0;
            }
        }
		if (runCount > 0) {
			// Note the run if still on one at the end of the row.
			[counts addObject:@(runCount)];
		}
    }
    
    // Detect vertical runs.
    for (NSInteger column = 0; column < AAPLBoardWidth; column++) {
        NSInteger runCount = 0;
        for (NSInteger row = 0; row < AAPLBoardHeight; row++) {
            if ([self chipInColumn:column row:row] == chip) {
				++runCount;
            }
            else {
				// Run isn't continuing, note it and reset counter.
				if (runCount > 0) {
					[counts addObject:@(runCount)];
				}
				runCount = 0;
			}
		}
		if (runCount > 0) {
			// Note the run if still on one at the end of the column.
			[counts addObject:@(runCount)];
		}
    }

	// Detect diagonal (northeast) runs
	for (NSInteger startColumn = -AAPLBoardHeight; startColumn < AAPLBoardWidth; startColumn++) {
		// Start from off the edge of the board to catch all the diagonal lines through it.
		NSInteger runCount = 0;
		for (NSInteger offset = 0; offset < AAPLBoardHeight; offset++) {
			NSInteger column = startColumn + offset;
			if (column < 0 || column > AAPLBoardWidth) {
				continue; // Ignore areas that aren't on the board.
			}
			if ([self chipInColumn:column row:offset] == chip) {
				++runCount;
			}
			else {
				// Run isn't continuing, note it and reset counter.
				if (runCount > 0) {
					[counts addObject:@(runCount)];
				}
				runCount = 0;
			}
		}
		if (runCount > 0) {
			// Note the run if still on one at the end of the line.
			[counts addObject:@(runCount)];
		}
	}

	// Detect diagonal (northwest) runs
	for (NSInteger startColumn = 0; startColumn < AAPLBoardWidth + AAPLBoardHeight; startColumn++) {
		// Iterate through areas off the edge of the board to catch all the diagonal lines through it.
		NSInteger runCount = 0;
		for (NSInteger offset = 0; offset < AAPLBoardHeight; offset++) {
			NSInteger column = startColumn - offset;
			if (column < 0 || column > AAPLBoardWidth) {
				continue; // Ignore areas that aren't on the board.
			}
			if ([self chipInColumn:column row:offset] == chip) {
				++runCount;
			}
			else {
				// Run isn't continuing, note it and reset counter.
				if (runCount > 0) {
					[counts addObject:@(runCount)];
				}
				runCount = 0;
			}
		}
		if (runCount > 0) {
			// Note the run if still on one at the end of the line.
			[counts addObject:@(runCount)];
		}
	}

    return counts;
}

@end
