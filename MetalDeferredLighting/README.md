# MetalDeferredLighting

MetalDeferredLighting is designed as an example of rendering of a g-buffer and light accumulation in a single render encoder in one pass using programmable blending. In this sample, we render in 2 passes. As such it is also an example of a multipass renderer in Metal. A "pass" in this case is defined as all draws to a texture before swapping it out for a new texture. 

The first pass renders a shadow map based on the calculated position of a sun. The second pass performs a deferred lighting algorithm by writing to and reading from a framebuffer containing 4 color attachments.  Three of the attachments are seeded with the g-buffer values (albedo, linear depth, normal).  Next, light primitives are rendered to accumulate light into the light accumulation attachment, reading the g-buffer values directly from the other attachments. A full screen quad combines the light accumulation buffer with the albedo texture, samples the shadow map as a texture, and applies the light contribution from the sun.  The results of this composition pass overwrites the albedo attachment with the final composited output.  Lastly, particles representing each point light (lovingly called fairies) are rendered on top.  What began as the albedo texture in the g-buffer now contains the final value, which can be presented to the display as its texture is the CAMetalLayer's drawable texture.

## Requirements

### Build

iOS 8 SDK

### Runtime

iOS 8, 64 bit devices

Copyright (C) 2014 Apple Inc. All rights reserved.
