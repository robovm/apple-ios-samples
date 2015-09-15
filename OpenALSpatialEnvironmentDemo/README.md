# OpenAL Spatial Environment Demo

oalTouch uses OpenAL to play an audio file containing uncompressed (PCM) audio data. The application uses Audio File Services to manage audio file data reading. The application also uses Audio Session Services to manage interruptions (as described in Core Audio Overview).

This application shows how to:

* Set up the environment for OpenAL usage by creating oalDevice and oalContext objects.

* Read data from an audio file using the ExtendedAudioFile API and attach into an OpenAL buffer object.

* Create an OpenAL source object and attach a buffer object to it.

* Manipulate various properties of OpenAL source and listener objects.

* Use Core Animation layers to rotate and move image objects based on user input.

* Use Audio Session Services to register an interruption callback.

* Use Audio Session Services to set appropriate audio session categories for recording and playback.

* Use Audio Session Services to pause playback upon receiving an interruption, and to then resume playback if the interruption ends.

* Use UIAccelerometer Services to provide user input from device movement.

* Use UISlider objects as switches.

oalTouch does not demonstrate how to play multiple source objects, nor does it provide more advanced OpenAL usage. 

## Requirements

### Build

iOS 8.3 SDK, Xcode 6.3

### Runtime

iOS 8.3

Copyright (C) 2008-2015 Apple Inc. All rights reserved.
