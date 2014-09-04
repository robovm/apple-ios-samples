/*
 
 File: PlayerModel.m
 
 Abstract: Provide an example of how to successfully submit scores to leaderboards
 and store them when submission fails.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "PlayerModel.h"

@implementation PlayerModel

@synthesize storedScores, 
            storedScoresFilename;

- (id)init
{
    self = [super init];
    if (self) {
        NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        storedScoresFilename = [[NSString alloc] initWithFormat:@"%@/%@.storedScores.plist",path,[GKLocalPlayer localPlayer].playerID];
        writeLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [storedScores release];
    [writeLock release];
    [storedScoresFilename release];   
    [super dealloc];
}

// Attempt to resubmit the scores.
- (void)resubmitStoredScores
{
    if (storedScores) {
        // Keeping an index prevents new entries to be added when the network is down 
        int index = [storedScores count]-1;
        while( index >= 0 ) {
            GKScore * score = [storedScores objectAtIndex:index];
            [self submitScore:score];
            [storedScores removeObjectAtIndex:index];
            index--;
        }
        [self writeStoredScore];
    }
}

// Load stored scores from disk.
- (void)loadStoredScores
{
    NSArray *  unarchivedObj = [NSKeyedUnarchiver unarchiveObjectWithFile:storedScoresFilename];
    
    if (unarchivedObj) {
        storedScores = [[NSMutableArray alloc] initWithArray:unarchivedObj];
        [self resubmitStoredScores];
    } else {
        storedScores = [[NSMutableArray alloc] init];
    }
}


// Save stored scores to file. 
- (void)writeStoredScore
{
    [writeLock lock];
    NSData * archivedScore = [NSKeyedArchiver archivedDataWithRootObject:storedScores];
    NSError * error;
    [archivedScore writeToFile:storedScoresFilename options:NSDataWritingFileProtectionNone error:&error];
    if (error) {
        //  Error saving file, handle accordingly 
    }
    [writeLock unlock];
}

// Store score for submission at a later time.
- (void)storeScore:(GKScore *)score 
{
    [storedScores addObject:score];
    [self writeStoredScore];
}

// Attempt to submit a score. On an error store it for a later time.
- (void)submitScore:(GKScore *)score 
{
    if ([GKLocalPlayer localPlayer].authenticated) {
        if (!score.value) {
            // Unable to validate data. 
            return;
        }
        
        // Store the scores if there is an error. 
        [score reportScoreWithCompletionHandler:^(NSError *error){
            if (!error || (![error code] && ![error domain])) {
                // Score submitted correctly. Resubmit others
                [self resubmitStoredScores];
            } else {
                // Store score for next authentication. 
                [self storeScore:score];
            }
        }];
    } 
}

@end
