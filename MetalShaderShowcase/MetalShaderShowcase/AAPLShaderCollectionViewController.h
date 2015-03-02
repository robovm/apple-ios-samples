/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The CollectionViewController for the CollectionView of the shaders. 
 */

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

typedef enum
{
    Phong, Wood, Fog, CelShading, SphereMap, NormalMap, ParticleSystem
} ShaderType;

@interface AAPLShaderCollectionViewController : UICollectionViewController

// renderer will create a default device at init time.
@property (nonatomic, readonly) id <MTLDevice> device;

@end
