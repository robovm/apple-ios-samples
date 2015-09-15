GLEssentials

================================================================================
DESCRIPTION:

This sample provides an example of some of the techniques described in the 
"OpenGL Essential Design Practices" WWDC 2010 session.  There are usages of 
Vertex Buffer Objects (VBOs), Vertex Array Objects (VAOs),  Framebuffer Objects 
(FBO), and GLSL Program Objects.  It creates a VAO and VBOs from model data 
loaded in.  It creates a texture for the model from image data and GLSL shaders 
from source also loaded in.   It also creates an FBO and texture to render a 
reflection of the model.  It uses an environment mapping GLSL program to apply 
the reflection texture to a plane.  This sample also demonstrates sharing of 
OpenGL ES source code for iPhone OS and OpenGL source code for OS X.  
Additionally, it implement fullscreen rendering, retina display support, and
demonstrates how to obtain and use an OpenGL 3.2 rendering context on OS X.

================================================================================
BUILD REQUIREMENTS:

Mac version: Mac OS X 10.8 or later, Xcode 5 or later
iOS version: iOS SDK 5.0 or later

================================================================================
RUNTIME REQUIREMENTS:

Mac version: Mac OS X 10.8 or later
iOS version: iOS 5.0 or later (with OpenGL ES 2.0 support) 

================================================================================
Copyright (C) 2010~2013 Apple Inc. All rights reserved.
