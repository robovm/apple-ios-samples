/*
 
     File: APLUtilities.m
 Abstract: Methods to handle loading and saving APLProfile files.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 
 */

#import "APLUtilities.h"
#import "APLProfile.h"

NSString * const kProfileCustomFileExtension = @"customprofile";
NSString * const kProfileFilesFolderName = @"ProfileFiles";
NSString * const kCustomURLFile = @"customURL";
NSString * const kProfileArchiveKey = @"ProfileArchiveKey";

@implementation APLUtilities

#pragma mark - APLProfile Saving/Loading

//Saves one profile at a time, that way loadProfiles can iterate over all the files in the directory
+ (void)saveProfile:(APLProfile *)profile
{
    NSString *savePath = [APLUtilities profilesFolderPath];
    savePath = [savePath stringByAppendingPathComponent:profile.filename];
    [APLUtilities securelyArchiveRootObject:profile toFile:savePath];
}

+ (NSArray *)loadProfiles
{
    //Only returns the names of the files not the paths
    NSArray *directoryFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[APLUtilities profilesFolderPath] error:nil];
    
    NSMutableArray *profiles = [NSMutableArray arrayWithCapacity:[directoryFiles count]];
    
    //Iterate over all profiles in the folder
    for (NSString *fileName in directoryFiles) {
        
        //Only read in files that conform to the custom UTI
        if ([[fileName pathExtension] isEqualToString:kProfileCustomFileExtension]) {
            
            //Create path with folder path plus file name
            NSString *absolutePath = [[APLUtilities profilesFolderPath] stringByAppendingPathComponent:fileName];
            
            //Create profile
            APLProfile *profile = [APLUtilities securelyUnarchiveProfileWithFile:absolutePath];
            
            if (profile) {
                profile.filename = fileName;
                [profiles addObject:profile];
            }
            
        }
    }
    return profiles;
}

+ (APLProfile *)loadProfileForFilename:(NSString *)filename
{
    NSString *directoryPath = [APLUtilities profilesFolderPath];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:filename];
    
    APLProfile *profile = [APLUtilities securelyUnarchiveProfileWithFile:filePath];

    if (profile) {
        profile.filename = filename;
    }
    
    return profile;
    
}

+ (void)deleteProfile:(APLProfile *)profile
{
    NSString *profilePath = [APLUtilities profilesFolderPath];
    profilePath = [profilePath stringByAppendingPathComponent:profile.filename];
    
    //Delete file from the file system
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:profilePath error:&error];
    
    if (error) {
        NSLog(@"Error When Deleting APLProfile: %@", [error localizedDescription]);
    }
}

#pragma mark - Custom URL Saving/Loading

+ (void)saveCustomURL:(NSURL *)url
{
    NSString *savePath = [APLUtilities documentsDirectory];
    savePath = [savePath stringByAppendingPathComponent:kCustomURLFile];
    [[url description] writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSURL *)loadCustomURL
{
    NSString *savePath = [APLUtilities documentsDirectory];
    savePath = [savePath stringByAppendingPathComponent:kCustomURLFile];
    
    NSString *urlString = [NSString stringWithContentsOfFile:savePath encoding:NSUTF8StringEncoding error:nil];
    
    NSURL *customURL = nil;
    if (urlString) {
        customURL = [NSURL URLWithString:urlString];
    }
    return customURL;
}

#pragma mark - Convenience Methods

+ (NSString *)profilesFolderPath
{
    NSString *doucumentFolder = [APLUtilities documentsDirectory];
    doucumentFolder = [doucumentFolder stringByAppendingPathComponent:kProfileFilesFolderName];
    
    //Create directory to store files if it does not already exist
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:doucumentFolder isDirectory:&isDir];
    
    if (!exists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:doucumentFolder
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return doucumentFolder;
}

+ (NSString *)documentsDirectory
{
    //Get path to the app's document directory
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([path count] > 0) ? [path objectAtIndex:0] : nil;
}

+ (NSData *)securelyArchiveRootObject:(id)object
{
    //Use secure encoding because files could be transfered from anywhere by anyone
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    //Ensure that secure encoding is used
    [archiver setRequiresSecureCoding:YES];
    [archiver encodeObject:object forKey:kProfileArchiveKey];
    [archiver finishEncoding];
    
    return data;
}

+ (void)securelyArchiveRootObject:(id)object toFile:(NSString *)filePath
{
    NSData * data = [APLUtilities securelyArchiveRootObject:object];
    [data writeToFile:filePath atomically:YES];
}

+ (APLProfile *)securelyUnarchiveProfileWithFile:(NSString *)filePath
{
    //Use secure encoding because files could be transfered from anywhere by anyone
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:fileData];

    //Ensure that secure encoding is used
    [unarchiver setRequiresSecureCoding:YES];
    
    APLProfile *profile = nil;
    @try {
        profile = [unarchiver decodeObjectOfClass:[APLProfile class] forKey:kProfileArchiveKey];
    }
    @catch (NSException *exception) {
        if ([[exception name] isEqualToString:NSInvalidArchiveOperationException]) {
            NSLog(@"%@ failed to unarchive APLProfile: %@", NSStringFromSelector(_cmd), exception);
        }
        else
        {
            [exception raise];
        }
    }
    
    return profile;
}

@end
