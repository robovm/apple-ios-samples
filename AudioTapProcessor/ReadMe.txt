### AudioTapProcessor ###

===========================================================================
DESCRIPTION:

Sample application that uses the MTAudioProcessingTap in combination with AV Foundation to visualize audio samples as well as applying a Core Audio audio unit effect (Bandpass Filter) to the audio data.

Note: The sample requires at least one video asset in the Asset Library (Camera Roll) to use as the source media. It will automatically select the first one it finds.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.6.3 or later, iOS 6.1.3 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.1.3 or later
iPad 2 or later iPad device

===========================================================================
PACKAGING LIST:

MYAudioTapProcessor.h & MYAudioTapProcessor.m contain the main code demonstrating the focus of this sample.

This includes setup of the AVAudioTapProcessorContext and the AVMutableAudioMix as well as instantiating the Bandpass filter Audio Unit and the render proc. which provides the demo processing being done to the audio data comming from the asset.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 - First version WWDC 2012
Version 1.0.1 - iOS Reference Library Version

===========================================================================
Copyright (C) 2012-2013 Apple Inc. All rights reserved.
