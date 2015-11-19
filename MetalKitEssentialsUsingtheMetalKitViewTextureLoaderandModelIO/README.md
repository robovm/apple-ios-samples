# MetalKitEssentials: Using the MetalKit View, Texture Loaded, and Model I/O

This sample demonstrates how to use key functionality provided by MetalKit on both iOS and OS X, including usage of the MetalKit view, texture loader, and the Model I/O integration. The sample uses the MetalKit view to get Metal rendering, the texture loader to load 2D assets, and the Model I/O framework to load an OBJ file with help from MetalKit to render the mesh object. This sample also demonstrates the sharing of data types between Objective-C++ and Metal Shading Language code via a shared header.

It implements a ViewController which also serves as a delegate to the MetalKit view.  After configuring the view, it creates a Metal Vertex Descriptor describing the layout of verticies expected by the our Render State Pipeline.  It reuses the Metal Vertex Descriptor to create a Model I/O Vertex Descriptor describing the layout of vertices to be loaded by Model I/O.  It also creates a Metal Kit Mesh Buffer Allocator so that Model I/O can load vertex and index data directly into GPU backed Metal buffers.  Once MetalKit Mesh and Submesh objects are created, the sample renders the model.

## Requirements
iOS or OSX device supporting Metal

### Build

Xcode 7.0, iOS 9.0 SDK, iOS device, OS X 10.11 SDK

### Runtime

iOS 9.0, iOS device, OS X 10.11

Copyright (C) 2015 Apple Inc. All rights reserved.
