
AVCustomEdit
============

AVCustomEdit is a simple AVFoundation based movie editing application demonstrating custom compositing to add transitions. The sample demonstrates the use of custom compositors to add transitions to an AVMutableComposition. It implements the AVVideoCompositing and AVVideoCompositionInstruction protocols to have access to individual source frames, which are then be rendered using OpenGL off screen rendering. 

Note: The sample has been developed for iPhones 4S and above/iPods with 4-inch display and iPads. These developed transitions are not supported on simulator.

====================================================================================

The main classes are as follows:

APLSimpleEditor
 This class setups an AVComposition with relevant AVVideoCompositions using the provided clips and time ranges.

APLCustomVideoCompositionInstruction
 Custom video composition instruction class implementing AVVideoCompositionInstruction protocol.

APLCustomVideoCompositor
 Custom video compositor class implementing AVVideoCompositing protocol.

APLOpenGLRenderer
 Base class renderer setups an EAGLContext for rendering, it also loads, compiles and links the vertex and fragment shaders for both Y and UV plane.

APLDiagonalWipeRenderer
 A subclass of APLOpenGLRenderer, renders the given source buffers to perform a diagonal wipe over the transition time range.

APLCrossDissolveRenderer
 A subclass of APLOpenGLRenderer, renders the given source buffers to perform a cross dissolve over the transition time range.

APLViewController
 A UIViewController subclass. This contains the view controller logic including playback and editing setup.

APLTransitionTypeController
 A subclass of UITableViewController which controls UI for selecting transition type.

==============================================================
Copyright © 2013 Apple Inc. All rights reserved.