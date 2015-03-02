# MetalShaderShowcase

Metal Shader Showcase demonstrates a variety of visual techniques optimized with Metal. It contains 7 unique shaders: a Phong shader, a wood shader, a fog shader, a cel shader, a normal map shader, and a particle system shader. 

The user is presented with a collection view that has thumbnails and names for all the available shaders. When the user chooses a shader, a renderer with the selected shaders and necessary data are allocated and initialized. The program then uses a push segue to transition to the view of the renderer.

The rendering architecture of the program is based on reflection. We have one main renderer that is passed a vertex shader, a fragment shader, a mesh, and optionally a texture. Based on reflection, the renderer queries the shaders for what arguments are needed, and presents them to the render encoder. Having a main renderer, and using reflection severely simplified the code allowing it to be shorter, and more flexible. 

Since the particle system uses such different techniques and data for rendering, the main renderer was subclassed. This allowed it to more easily pass it’s unique data, enable blending, draw a different primitive type, do different transformations, and still reuse much of the same rendering code. 

The shaders and their implementations are described below. 

Phong Shader
A shader using using the Phong shading model for the Metal Shader Showcase. This is a simple and frequently used shader that many developers will implement. The technique is accomplished by computing an ambient, diffuse, and specular component and adds them together to get the final color. 

Wood Shader
A shader using random noise to create a wood texture for the Metal Shader Showcase. This is an example of a 3D procedural texture based shader. The wood texture is accomplished by making rings of two different colors and using perlin noise to add some variation to the rings. 

Fog Shader
A shader implementing image based fog for the Metal Shader Showcase. Fog is a common effect that is built in to OpenGL and is a good sample to show implemented in Metal. The effect is accomplished by setting a start to the fog, where the fog gives no contribution to the final color, and an end to the fog, where the final color is the fog color. Using these two numbers, you calculate how much fog is between the object and the camera, and color accordingly. 

Cel Shader
A shader implementing cel shading for the Metal Shader Showcase. This is a common implementation of non-photorealistic rendering technique. This effect is accomplished by breaking down the diffuse component into 3 different shades and the specular into only one. The diffuse color is decided upon by calculating the angle between the normal and the light vector, and setting three different angles as the boundaries of these regions. It is similarly done with the specular component with only one angle between the viewer and the reflection vector determining the boundary.

Sphere Map Shader
A shader implementing sphere mapping for the Metal Shader Showcase. Environment mapping is used for reflections and refractions in many real time graphics applications, and this is one possible implementation of the technique. This is done by using a texture of a mirrored sphere that captures the environment. Because it is a sphere, it captures all possible reflection angles a viewer could see. Thus, we calculate the reflection vector from the object, and use the texture to lookup what is reflected there. 

Normal Map Shader
A shader implementing normal mapping for the Metal Shader Showcase. This is a common technique that is used in many 3D applications that increases geometric detail without incurring high computational cost. This is done by storing surface details in a texture and then using that texture to change the normals of the object.

Particle System Shader
A shader representing a particle system for the Metal Shader Showcase. Particles are a common effect implemented in many 3D applications.  Each particle's initial random direction and birth offset is passed into the vertex shader. It uses these values to calculate the particles position based on the current time. Then the fragment shader uses these points and colors them as circles that fade out at the edges.

## Requirements

### Build

iOS 8 SDK

### Runtime

iOS 8, 64 bit devices

Copyright (C) 2014 Apple Inc. All rights reserved.
