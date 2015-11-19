/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages the main character, including its animations, sounds and direction.
 */

@import Foundation;

typedef NS_ENUM(NSUInteger, AAPLFloorMaterial) {
    AAPLFloorMaterialGrass,
    AAPLFloorMaterialRock,
    AAPLFloorMaterialWater,
    AAPLFloorMaterialInTheAir,
    AAPLFloorMaterialCount
};

@interface AAPLCharacter : NSObject

// Character nodes
@property(nonatomic,readonly) SCNNode *node;
@property(nonatomic,readonly) SCNNode *physicsNode;

// Character states
@property(nonatomic, getter=isWalking) BOOL walk;
@property(readonly, getter=isBurning) BOOL burning;
@property(nonatomic) float direction;
@property(nonatomic) AAPLFloorMaterial floorMaterial;

- (void)hit; //hit by fire!
- (void)pshhhh; //pshhh in water :)

@end

