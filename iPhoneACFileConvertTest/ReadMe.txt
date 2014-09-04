iPhoneACFileConvertTest

===========================================================================
DESCRIPTION:

iPhoneACFileConvertTest demonstrates the use of the Audio Converter APIs to convert from a PCM audio format to a compressed format.

All the relevant code is in the file AudioConverterFileConvert.cpp.

Touching the "Convert" button calls the function DoConvertFile() producing an output.caf file using the
encoding and sample rate chosen in the UI. The output.caf file is then played back after conversion using AVAudioPlayer
to confirm success.

Audio format information for the source file and output file are also displayed.

Interruption handling during audio processing (conversion) is also demonstrated.
 
===========================================================================
RELATED INFORMATION:

Core Audio Overview
Audio Session Programming Guide
Audio Converter Services Reference

===========================================================================
SPECIAL CONSIDERATIONS:

AAC encoding using the Audio Converter requires iOS 4.1 and a hardware capable device such
as the iPhone 3GS or newer.

IPhone 5s does not have a hardware encoder and only one encoder will show up.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.9.x Xcode 5.0.2+, iOS 7.0.4

===========================================================================
RUNTIME REQUIREMENTS:

Simulator: Mac OS X v10.9.x
iPhone: iOS 7.0.4

===========================================================================
PACKAGING LIST:

iPhoneACFileConvertTest.h
iPhoneACFileConvertTest.m

The ACFileConvertAppDelegate class defines the application delegate object, responsible for adding the navigation
controllers view to the application window.

MyViewController.h
MyViewController.m

The MyViewController class defines the controller object for the application. The object helps set up the user interface,
responds to and manages user interaction, and implements sound playback.

AudioConverterFileConvert.cpp

This file implements the DoConvertFile function which is called on a background thread from the MyViewController class.

All the code demonstrating how to perform conversion is contained in this one file, the rest of the sample may be thought of
as a simple framework for the demonstration code in this file.

Audio Format and Sample Rate choices presented in the UI are simply used for testing purposes, developers are free to choose any other
supported file type or encoding format and present these choices however they wish.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0, tested with iPhone OS 4.1 First public release.
Version 1.0.2, tested with iOS 6.1 Minor Update for 6.1 SDK.
Version 1.0.3, updated to support iPhone 5s and software AAC encode with iOS 7.

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.