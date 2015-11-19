# MetalBasic3D

MetalBasic3D renders a set of cubes using Metal and alternates their colors directly by modifying each cubes uniforms. Several parameters can be modified directly in the AAPLRenderer.mm file including the number of cubes and their size. The cubes are rendered into a helix path using spherical coordinate system to get x,y,z for the translation matrix. Each cube is renderered individually using a basic 3D phong lighting shader. The number of cubes is directly equivelent to the number of draw calls performed in the scene. In essence, the same scene can be rendered using instanced draw methods, but the purpose of this sample is to experiment with draw call count and see how it effects FPS. Note, for each frame, each cube's transformation matrix is update along with its color, therefore in each frame the sample must traverese through 2n cubes. Its possible to do even less CPU work and achieve even higher frame rates with more draw calls but this should provide a basic idea of what is possible wth Metal. 

## Requirements

### Build

iOS 9 SDK, OSX 10.11 SDK

### Runtime

iOS 9, 64 bit devices
OSX 10.11

Copyright (C) 2014~2015 Apple Inc. All rights reserved.
