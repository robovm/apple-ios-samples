/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages the main character, including its animations, sounds and direction.
*/

@import Foundation;

typedef NS_ENUM(NSUInteger, AAPLGroundType) {
   AAPLGroundTypeGrass,
   AAPLGroundTypeRock,
   AAPLGroundTypeWater,
   AAPLGroundTypeInTheAir,
   AAPLGroundTypeCount
};

@interface AAPLCharacter : NSObject

@property(nonatomic, readonly) SCNNode *node;

- (SCNNode *)walkInDirection:(vector_float3)direction time:(NSTimeInterval)time scene:(SCNScene *)scene groundTypeFromMaterial:(AAPLGroundType(^)(SCNMaterial *))groundTypeFromMaterial;
- (void)catchFire;
- (void)haltFire;

@end

