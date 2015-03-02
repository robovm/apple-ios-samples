
RosyWriter

This sample demonstrates how to use AVCaptureVideoDataOutput to bring frames from the camera into various processing pipelines, including CPU-based, OpenGL (i.e. on the GPU), CoreImage filters, and OpenCV. It also demonstrates best practices for writing the processed output of these pipelines to a movie file using AVAssetWriter.

The project includes a different target for each of the different processing pipelines.

Classes
RosyWriterViewController
-- This file contains the view controller logic, including support for the Record button and video preview.
RosyWriterCapturePipeline
-- This file manages the audio and video capture pipelines, including the AVCaptureSession, the various queues, and resource management.

Renderers
RosyWriterRenderer
-- This file defines a generic protocol for renderer objects used by RosyWriterCapturePipeline.
RosyWriterOpenGLRenderer
-- This file manages the OpenGL (GPU) processing for the "rosy" effect and delivers rendered buffers.
RosyWriterCPURenderer
-- This file manages the CPU processing for the "rosy" effect and delivers rendered buffers.
RosyWriterCIFilterRenderer
-- This file manages the CoreImage processing for the "rosy" effect and delivers rendered buffers.
RosyWriterOpenCVRenderer
-- This file manages the delivery of frames to an OpenCV processing block and delivers rendered buffers.

RosyWriterAppDelegate
-- This file is a standard application delegate class.

Shaders
myFilter
-- OpenGL shader code for the "rosy" effect

Utilities
MovieRecorder
-- Illustrates real-time use of AVAssetWriter to record the displayed effect.
OpenGLPixelBufferView
-- This is a view that displays pixel buffers on the screen using OpenGL.

GL
-- Utilities used by the GL processing pipeline.


===============================================================
Copyright © 2014 Apple Inc. All rights reserved.
