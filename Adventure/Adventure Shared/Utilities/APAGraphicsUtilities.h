/*
     File: APAGraphicsUtilities.h
 Abstract: n/a
  Version: 1.2
 
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

/* Generate a random float between 0.0f and 1.0f. */
#define APA_RANDOM_0_1() (arc4random() / (float)(0xffffffffu))

/* The assets are all facing Y down, so offset by pi half to get into X right facing. */
#define APA_POLAR_ADJUST(x) x + (M_PI * 0.5f)


/* Load an array of APADataMap or APATreeMap structures for the given map file name. */
void *APACreateDataMap(NSString *mapName);

/* Distance and coordinate utility functions. */
CGFloat APADistanceBetweenPoints(CGPoint first, CGPoint second);
CGFloat APARadiansBetweenPoints(CGPoint first, CGPoint second);
CGPoint APAPointByAddingCGPoints(CGPoint first, CGPoint second);

/* Load the named frames in a texture atlas into an array of frames. */
NSArray *APALoadFramesFromAtlas(NSString *atlasName, NSString *baseFileName, int numberOfFrames);

/* Run the given emitter once, for duration. */
void APARunOneShotEmitter(SKEmitterNode *emitter, CGFloat duration);


/* Define structures that map exactly to 4 x 8-bit ARGB pixel data. */
#pragma pack(1)
typedef struct {
    uint8_t bossLocation, wall, goblinCaveLocation, heroSpawnLocation;
} APADataMap;

typedef struct {
    uint8_t unusedA, bigTreeLocation, smallTreeLocation, unusedB;
} APATreeMap;
#pragma pack()

typedef APADataMap *APADataMapRef;
typedef APATreeMap *APATreeMapRef;


/* Category on NSValue to make it easy to access the pointValue/CGPointValue from iOS and OS X. */
@interface NSValue (APAAdventureAdditions)
- (CGPoint)apa_CGPointValue;
+ (instancetype)apa_valueWithCGPoint:(CGPoint)point;
@end


/* Category on SKEmitterNode to make it easy to load an emitter from a node file created by Xcode. */
@interface SKEmitterNode (APAAdventureAdditions)
+ (instancetype)apa_emitterNodeWithEmitterNamed:(NSString *)emitterFileName;
@end