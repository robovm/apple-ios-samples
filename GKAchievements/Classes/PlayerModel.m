/*
 
 File: PlayerModel.m
 
 Abstract: Provide an example of how to successfully submit achievements and store them when network connection is not available
 
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

@synthesize storedFilename, storedAchievements;

- (id)init
{
    self = [super init];
    if (self) {
        writeLock = [[NSLock alloc] init]; 
		NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        storedFilename = [[NSString alloc] initWithFormat:@"%@/%@.storedAchievements.plist",[GKLocalPlayer localPlayer].playerID,path];
    }
    return self;
}

- (void)dealloc
{
    [writeLock release];
    [storedFilename release];   
    [storedAchievements release];
    [super dealloc];
}


// Try to submit all stored achievements to update any achievements that were not successful. 
- (void)resubmitStoredAchievements
{
    if (storedAchievements) {
        for (NSString *key in storedAchievements){
            GKAchievement * achievement = [storedAchievements objectForKey:key];
            [storedAchievements removeObjectForKey:key];
            [self submitAchievement:achievement];
        } 
		[self writeStoredAchievements];
    }
}
 
// Load stored achievements and attempt to submit them
- (void)loadStoredAchievements
{
    if (!storedAchievements) {
        NSDictionary *  unarchivedObj = [NSKeyedUnarchiver unarchiveObjectWithFile:storedFilename];;
        
        if (unarchivedObj) {
            storedAchievements = [[NSMutableDictionary alloc] initWithDictionary:unarchivedObj];
            [self resubmitStoredAchievements];
        } else {
            storedAchievements = [[NSMutableDictionary alloc] init];
        }
    }    
}

// store achievements to disk to submit at a later time.
- (void)writeStoredAchievements
{
    [writeLock lock];
    NSData * archivedAchievements = [NSKeyedArchiver archivedDataWithRootObject:storedAchievements];
    NSError * error;
    [archivedAchievements writeToFile:storedFilename options:NSDataWritingFileProtectionNone error:&error];
    if (error) {
        //  Error saving file, handle accordingly
    }
    [writeLock unlock];
}

// Submit an achievement to the server and store if submission fails
- (void)submitAchievement:(GKAchievement *)achievement 
{
    if (achievement) {
        // Submit the achievement. 
        [achievement reportAchievementWithCompletionHandler: ^(NSError *error){
            if (error) {
                // Store achievement to be submitted at a later time. 
                [self storeAchievement:achievement];
            } else {
                if ([storedAchievements objectForKey:achievement.identifier]) {
                    // Achievement is reported, remove from store. 
                    [storedAchievements removeObjectForKey:achievement.identifier];
                } 
                [self resubmitStoredAchievements];
            }
        }];
    }
}

// Create an entry for an achievement that hasn't been submitted to the server 
- (void)storeAchievement:(GKAchievement *)achievement 
{
    GKAchievement * currentStorage = [storedAchievements objectForKey:achievement.identifier];
    if (!currentStorage || (currentStorage && currentStorage.percentComplete < achievement.percentComplete)) {
        [storedAchievements setObject:achievement forKey:achievement.identifier];
        [self writeStoredAchievements];
    }
}

// Reset all the achievements for local player 
- (void)resetAchievements
{
	[GKAchievement resetAchievementsWithCompletionHandler: ^(NSError *error) 
     {
        if (!error) {
             [storedAchievements release];
            storedAchievements = [[NSMutableDictionary alloc] init];
             
            // overwrite any previously stored file
             [self writeStoredAchievements];              
        } else {
            // Error clearing achievements. 
         }
     }];
}

@end
