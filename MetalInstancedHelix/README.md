# MetalInstancedHelix

This example renders a set of cubes using Metal and alternates their colors by modifying each cube's uniforms directly in the shared CPU/GPU memory buffer. Several parameters can be modified directly in the AAPLRenderer.mm file including the number of cubes and their size. The cubes are rendered into a helix path using spherical coordinate system to get x,y,z for the translation matrix. Each cube is renderered individually using a basic 3D phong lighting shader, but drawn in only a single draw call using Metal's instancing API. Note, for each frame, each cube's transformation matrix is update along with its color, therefore in each frame the sample must traverese through 2n cubes. 

## Requirements

### Build

iOS 8 SDK

### Runtime

iOS 8, 64 Bit device

Copyright (C) 2015 Apple Inc. All rights reserved.
