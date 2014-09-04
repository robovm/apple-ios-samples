/*
        File: AudioConverterFileConvert.cpp
    Abstract: Demonstrates converting audio using AudioConverterFillComplexBuffer.
     Version: 1.0.3
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    
*/

// standard includes
#include <AudioToolbox/AudioToolbox.h>

// helpers
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

#include <pthread.h>

/* 

For more information on the importance of interruption handling and Audio Session setup when performing offline
encoding please see the Audio Session Programming Guide.

Offline format conversion requires interruption handling. Specifically, you must handle interruptions at the audio data buffer level.

By way of background, you can use a hardware assisted-codec—on certain devices—to encode linear PCM audio to AAC format.
The codec is available on the iPhone 3GS and on the iPod touch (2nd generation), but not on older models. You use the codec as part
of an Audio Converter object (of type AudioConverterRef).
For information on these opaque types, refer to Audio Converter Services Reference and Extended Audio File Services Reference.

To handle an interruption during hardware-assisted encoding, take two things into account:

1. The codec may or may not be able to resume encoding after the interruption ends.
2. The codec may be unavailable, probably due to an interruption.

Note: iOS 7 provides for software AAC encode, devices with hardware encoder will show as having two encoders, devices such as the iPhone 5s only has
      a software encoder that is much faster and more flexible than the older hardware encoders.

Encoding takes place as you repeatedly call the AudioConverterFillComplexBuffer function supplying new buffers of input audio data via the input data procedure
producing buffers of audio encoded in the output format.
To handle an interruption, you respond to the function’s result code, as described here:

• kAudioConverterErr_HardwareInUse — This result code indicates that the underlying hardware codec has become unavailable, probably due to an interruption.
In this case, your application must stop calling AudioConverterFillComplexBuffer.  If you can resume conversion, wait for an interruption-ended call from
the audio session. In your interruption-end handler, reactivate the session and then resume converting the audio data.

To check if the AAC codec can resume, obtain the value of the associated converter’s kAudioConverterPropertyCanResumeFromInterruption property.
The value is 1 (can resume) or 0 (cannot resume) or the property itself may not be supported (implies software codec use where we can resume).
You can obtain this value any time after instantiating the converter—immediately after instantiation, upon interruption, or after interruption ends.

If the converter cannot resume, then on interruption you must abandon the conversion. After the interruption ends, or after the user relaunches your application
and indicates they want to resume conversion, re-instantiate the extended audio file object and perform the conversion again.

*/

#pragma mark- Thread State
/* Since we perform conversion in a background thread, we must ensure that we handle interruptions appropriately.
   In this sample we're using a mutex protected variable tracking thread states. The background conversion threads state transistions from Done to Running
   to Done unless we've been interrupted in which case we are Paused blocking the conversion thread and preventing further calls
   to AudioConverterFillComplexBuffer (since it would fail if we were using the hardware codec).
   Once the interruption has ended, we unblock the background thread as the state transitions to Running once again.
   Any errors returned from AudioConverterFillComplexBuffer must be handled appropriately. Additionally, if the Audio Converter cannot
   resume conversion after an interruption, you should not call AudioConverterFillComplexBuffer again.
*/

static pthread_mutex_t  sStateLock;         // protects sState
static pthread_cond_t   sStateChanged;      // signals when interruption thread unblocks conversion thread
enum ThreadStates {
    kStateRunning,
    kStatePaused,
    kStateDone
};
static ThreadStates sState;

// initialize the thread state
void ThreadStateInitalize()
{
    int rc;

    assert([NSThread isMainThread]);
    
    rc = pthread_mutex_init(&sStateLock, NULL);
    assert(rc == 0);
    
    rc = pthread_cond_init(&sStateChanged, NULL);
    assert(rc == 0);
    
    sState = kStateDone;
}

// handle begin interruption - transition to kStatePaused
void ThreadStateBeginInterruption()
{
    int rc;

    assert([NSThread isMainThread]);
    
    rc = pthread_mutex_lock(&sStateLock);
    assert(rc == 0);
    
    if (sState == kStateRunning) {
        sState = kStatePaused;
    }
    
    rc = pthread_mutex_unlock(&sStateLock);
    assert(rc == 0);
}

// handle end interruption - transition to kStateRunning
void ThreadStateEndInterruption()
{
    int rc;

    assert([NSThread isMainThread]);
    
    rc = pthread_mutex_lock(&sStateLock);
    assert(rc == 0);
    
    if (sState == kStatePaused) {
        sState = kStateRunning;
        
        rc = pthread_cond_signal(&sStateChanged);
        assert(rc == 0);
    }
    
    rc = pthread_mutex_unlock(&sStateLock);
    assert(rc == 0);                
}

// set state to kStateRunning
void ThreadStateSetRunning()
{
    int rc = pthread_mutex_lock(&sStateLock);
    assert(rc == 0);
    
    assert(sState == kStateDone);
    sState = kStateRunning;
    
    rc = pthread_mutex_unlock(&sStateLock);
    assert(rc == 0);
}

// block for state change to kStateRunning
Boolean ThreadStatePausedCheck()
{
    Boolean wasInterrupted = false;
    
    int rc = pthread_mutex_lock(&sStateLock);
    assert(rc == 0);

    assert(sState != kStateDone);

    while (sState == kStatePaused) {
        rc = pthread_cond_wait(&sStateChanged, &sStateLock);
        assert(rc == 0);
        wasInterrupted = true;
    }

    // we must be running or something bad has happened
    assert(sState == kStateRunning);

    rc = pthread_mutex_unlock(&sStateLock);
    assert(rc == 0);
    
    return wasInterrupted;
}

void ThreadStateSetDone()
{
    int rc = pthread_mutex_lock(&sStateLock);
    assert(rc == 0);
    
    assert(sState != kStateDone);
    sState = kStateDone;
    
    rc = pthread_mutex_unlock(&sStateLock);
    assert(rc == 0);
}

// ***********************
#pragma mark- Converter
/* The main Audio Conversion function using AudioConverter */

enum {
    kMyAudioConverterErr_CannotResumeFromInterruptionError = 'CANT',
    eofErr = -39 // End of file
};

typedef struct {
	AudioFileID                  srcFileID;
	SInt64                       srcFilePos;
	char *                       srcBuffer;
	UInt32                       srcBufferSize;
	CAStreamBasicDescription     srcFormat;
	UInt32                       srcSizePerPacket;
	UInt32                       numPacketsPerRead;
	AudioStreamPacketDescription *packetDescriptions;
} AudioFileIO, *AudioFileIOPtr;

#pragma mark-

// Input data proc callback
static OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
	AudioFileIOPtr afio = (AudioFileIOPtr)inUserData;
    OSStatus error;
	
    // figure out how much to read
	UInt32 maxPackets = afio->srcBufferSize / afio->srcSizePerPacket;
	if (*ioNumberDataPackets > maxPackets) *ioNumberDataPackets = maxPackets;

    // read from the file
	UInt32 outNumBytes;
	error = AudioFileReadPackets(afio->srcFileID, false, &outNumBytes, afio->packetDescriptions, afio->srcFilePos, ioNumberDataPackets, afio->srcBuffer);
	if (eofErr == error) error = noErr;
	if (error) { printf ("Input Proc Read error: %ld (%4.4s)\n", error, (char*)&error); return error; }
	
    //printf("Input Proc: Read %lu packets, at position %lld size %lu\n", *ioNumberDataPackets, afio->srcFilePos, outNumBytes);
	
    // advance input file packet position
	afio->srcFilePos += *ioNumberDataPackets;

    // put the data pointer into the buffer list
	ioData->mBuffers[0].mData = afio->srcBuffer;
	ioData->mBuffers[0].mDataByteSize = outNumBytes;
	ioData->mBuffers[0].mNumberChannels = afio->srcFormat.mChannelsPerFrame;

    // don't forget the packet descriptions if required
	if (outDataPacketDescription) {
		if (afio->packetDescriptions) {
			*outDataPacketDescription = afio->packetDescriptions;
		} else {
			*outDataPacketDescription = NULL;
        }
	}
    
    return error;
}

#pragma mark-

// Some audio formats have a magic cookie associated with them which is required to decompress audio data
// When converting audio data you must check to see if the format of the data has a magic cookie
// If the audio data format has a magic cookie associated with it, you must add this information to anAudio Converter
// using AudioConverterSetProperty and kAudioConverterDecompressionMagicCookie to appropriately decompress the data
// http://developer.apple.com/mac/library/qa/qa2001/qa1318.html
static void ReadCookie(AudioFileID sourceFileID, AudioConverterRef converter)
{
    // grab the cookie from the source file and set it on the converter
	UInt32 cookieSize = 0;
	OSStatus error = AudioFileGetPropertyInfo(sourceFileID, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
    
    // if there is an error here, then the format doesn't have a cookie - this is perfectly fine as some formats do not
	if (noErr == error && 0 != cookieSize) {
		char* cookie = new char [cookieSize];
		
		error = AudioFileGetProperty(sourceFileID, kAudioFilePropertyMagicCookieData, &cookieSize, cookie);
        if (noErr == error) {
            error = AudioConverterSetProperty(converter, kAudioConverterDecompressionMagicCookie, cookieSize, cookie);
            if (error) printf("Could not Set kAudioConverterDecompressionMagicCookie on the Audio Converter!\n");
        } else {
            printf("Could not Get kAudioFilePropertyMagicCookieData from source file!\n");
        }
		
		delete [] cookie;
	}
}

// Some audio formats have a magic cookie associated with them which is required to decompress audio data
// When converting audio, a magic cookie may be returned by the Audio Converter so that it may be stored along with
// the output data -- This is done so that it may then be passed back to the Audio Converter at a later time as required
static void WriteCookie(AudioConverterRef converter, AudioFileID destinationFileID)
{
    // grab the cookie from the converter and write it to the destinateion file
	UInt32 cookieSize = 0;
	OSStatus error = AudioConverterGetPropertyInfo(converter, kAudioConverterCompressionMagicCookie, &cookieSize, NULL);
    
    // if there is an error here, then the format doesn't have a cookie - this is perfectly fine as some formats do not
	if (noErr == error && 0 != cookieSize) {
		char* cookie = new char [cookieSize];
		
		error = AudioConverterGetProperty(converter, kAudioConverterCompressionMagicCookie, &cookieSize, cookie);
        if (noErr == error) {
            error = AudioFileSetProperty(destinationFileID, kAudioFilePropertyMagicCookieData, cookieSize, cookie);
            if (noErr == error) {
                printf("Writing magic cookie to destination file: %ld\n", cookieSize);
            } else {
                printf("Even though some formats have cookies, some files don't take them and that's OK\n");
            }
        } else {
            printf("Could not Get kAudioConverterCompressionMagicCookie from Audio Converter!\n");
        }
        
		delete [] cookie;
	}
}

// Write output channel layout to destination file
static void WriteDestinationChannelLayout(AudioConverterRef converter, AudioFileID sourceFileID, AudioFileID destinationFileID)
{
    UInt32 layoutSize = 0;
    bool layoutFromConverter = true;
    
    OSStatus error = AudioConverterGetPropertyInfo(converter, kAudioConverterOutputChannelLayout, &layoutSize, NULL);
        
    // if the Audio Converter doesn't have a layout see if the input file does
    if (error || 0 == layoutSize) {
        error = AudioFileGetPropertyInfo(sourceFileID, kAudioFilePropertyChannelLayout, &layoutSize, NULL);
        layoutFromConverter = false;
    }
    
    if (noErr == error && 0 != layoutSize) {
        char* layout = new char[layoutSize];
        
        if (layoutFromConverter) {
            error = AudioConverterGetProperty(converter, kAudioConverterOutputChannelLayout, &layoutSize, layout);
            if (error) printf("Could not Get kAudioConverterOutputChannelLayout from Audio Converter!\n");
        } else {
            error = AudioFileGetProperty(sourceFileID, kAudioFilePropertyChannelLayout, &layoutSize, layout);
            if (error) printf("Could not Get kAudioFilePropertyChannelLayout from source file!\n");
        }
        
        if (noErr == error) {
            error = AudioFileSetProperty(destinationFileID, kAudioFilePropertyChannelLayout, layoutSize, layout);
            if (noErr == error) {
                printf("Writing channel layout to destination file: %ld\n", layoutSize);
            } else {
                printf("Even though some formats have layouts, some files don't take them and that's OK\n");
            }
        }
        
        delete [] layout;
    }
}

// Sets the packet table containing information about the number of valid frames in a file and where they begin and end
// for the file types that support this information.
// Calling this function makes sure we write out the priming and remainder details to the destination file	
static void WritePacketTableInfo(AudioConverterRef converter, AudioFileID destinationFileID)
{
    UInt32 isWritable;
    UInt32 dataSize;
    OSStatus error = AudioFileGetPropertyInfo(destinationFileID, kAudioFilePropertyPacketTableInfo, &dataSize, &isWritable);
    if (noErr == error && isWritable) {

        AudioConverterPrimeInfo primeInfo;
        dataSize = sizeof(primeInfo);

        // retrieve the leadingFrames and trailingFrames information from the converter,
        error = AudioConverterGetProperty(converter, kAudioConverterPrimeInfo, &dataSize, &primeInfo);
        if (noErr == error) {
            // we have some priming information to write out to the destination file
            /* The total number of packets in the file times the frames per packet (or counting each packet's
               frames individually for a variable frames per packet format) minus mPrimingFrames, minus
               mRemainderFrames, should equal mNumberValidFrames.
            */
            AudioFilePacketTableInfo pti;
            dataSize = sizeof(pti);
            error = AudioFileGetProperty(destinationFileID, kAudioFilePropertyPacketTableInfo, &dataSize, &pti);
            if (noErr == error) {
                // there's priming to write out to the file
                UInt64 totalFrames = pti.mNumberValidFrames + pti.mPrimingFrames + pti.mRemainderFrames; // get the total number of frames from the output file
                printf("Total number of frames from output file: %lld\n", totalFrames);
                
                pti.mPrimingFrames = primeInfo.leadingFrames;
                pti.mRemainderFrames = primeInfo.trailingFrames;
                pti.mNumberValidFrames = totalFrames - pti.mPrimingFrames - pti.mRemainderFrames;
            
                error = AudioFileSetProperty(destinationFileID, kAudioFilePropertyPacketTableInfo, sizeof(pti), &pti);
                if (noErr == error) {
                    printf("Writing packet table information to destination file: %ld\n", sizeof(pti));
                    printf("     Total valid frames: %lld\n", pti.mNumberValidFrames);
                    printf("         Priming frames: %ld\n", pti.mPrimingFrames);
                    printf("       Remainder frames: %ld\n", pti.mRemainderFrames);
                } else {
                    printf("Some audio files can't contain packet table information and that's OK\n");
                }
            } else {
                 printf("Getting kAudioFilePropertyPacketTableInfo error: %ld\n", error);
            }
        } else {
            printf("No kAudioConverterPrimeInfo available and that's OK\n");
        }
    } else {
        printf("GetPropertyInfo for kAudioFilePropertyPacketTableInfo error: %ld, isWritable: %ld\n", error, isWritable);
    }
}

#pragma mark-

OSStatus DoConvertFile(CFURLRef sourceURL, CFURLRef destinationURL, OSType outputFormat, Float64 outputSampleRate) 
{
	AudioFileID         sourceFileID = 0;
    AudioFileID         destinationFileID = 0;
    AudioConverterRef   converter = NULL;
    Boolean             canResumeFromInterruption = true; // we can continue unless told otherwise
    
    CAStreamBasicDescription srcFormat, dstFormat;
    AudioFileIO afio = {};
    
    char                         *outputBuffer = NULL;
    AudioStreamPacketDescription *outputPacketDescriptions = NULL;
    
    OSStatus error = noErr;
    
    // in this sample we should never be on the main thread here
    assert(![NSThread isMainThread]);
    
    // transition thread state to kStateRunning before continuing
    ThreadStateSetRunning();
    
    printf("\nDoConvertFile\n");
    
    try {
        // get the source file
        XThrowIfError(AudioFileOpenURL(sourceURL, kAudioFileReadPermission, 0, &sourceFileID), "AudioFileOpenURL failed");
	
        // get the source data format
        UInt32 size = sizeof(srcFormat);
        XThrowIfError(AudioFileGetProperty(sourceFileID, kAudioFilePropertyDataFormat, &size, &srcFormat), "couldn't get source data format");
        
        // setup the output file format
        dstFormat.mSampleRate = (outputSampleRate == 0 ? srcFormat.mSampleRate : outputSampleRate); // set sample rate
        if (outputFormat == kAudioFormatLinearPCM) {
            // if the output format is PC create a 16-bit int PCM file format description as an example
            dstFormat.mFormatID = outputFormat;
            dstFormat.mChannelsPerFrame = srcFormat.NumberChannels();
            dstFormat.mBitsPerChannel = 16;
            dstFormat.mBytesPerPacket = dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame;
            dstFormat.mFramesPerPacket = 1;
            dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger; // little-endian
        } else {
            // compressed format - need to set at least format, sample rate and channel fields for kAudioFormatProperty_FormatInfo
            dstFormat.mFormatID = outputFormat;
            dstFormat.mChannelsPerFrame =  (outputFormat == kAudioFormatiLBC ? 1 : srcFormat.NumberChannels()); // for iLBC num channels must be 1
            
            // use AudioFormat API to fill out the rest of the description
            size = sizeof(dstFormat);
            XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &dstFormat), "couldn't create destination data format");
        }
        
        printf("Source File format: "); srcFormat.Print();
        printf("Destination format: "); dstFormat.Print();
	
        // create the AudioConverter
        
        XThrowIfError(AudioConverterNew(&srcFormat, &dstFormat, &converter), "AudioConverterNew failed!");
    
        // if the source has a cookie, get it and set it on the Audio Converter
        ReadCookie(sourceFileID, converter);

        // get the actual formats back from the Audio Converter
        size = sizeof(srcFormat);
        XThrowIfError(AudioConverterGetProperty(converter, kAudioConverterCurrentInputStreamDescription, &size, &srcFormat), "AudioConverterGetProperty kAudioConverterCurrentInputStreamDescription failed!");

        size = sizeof(dstFormat);
        XThrowIfError(AudioConverterGetProperty(converter, kAudioConverterCurrentOutputStreamDescription, &size, &dstFormat), "AudioConverterGetProperty kAudioConverterCurrentOutputStreamDescription failed!");

        printf("Formats returned from AudioConverter:\n");
        printf("              Source format: "); srcFormat.Print();
        printf("    Destination File format: "); dstFormat.Print();
        
        // if encoding to AAC set the bitrate
        // kAudioConverterEncodeBitRate is a UInt32 value containing the number of bits per second to aim for when encoding data
        // when you explicitly set the bit rate and the sample rate, this tells the encoder to stick with both bit rate and sample rate
        //     but there are combinations (also depending on the number of channels) which will not be allowed
        // if you do not explicitly set a bit rate the encoder will pick the correct value for you depending on samplerate and number of channels
        // bit rate also scales with the number of channels, therefore one bit rate per sample rate can be used for mono cases
        //    and if you have stereo or more, you can multiply that number by the number of channels.
        if (dstFormat.mFormatID == kAudioFormatMPEG4AAC) {
            UInt32 outputBitRate = 64000; // 64kbs
            UInt32 propSize = sizeof(outputBitRate);
            
            if (dstFormat.mSampleRate >= 44100) {
                outputBitRate = 192000; // 192kbs
            } else if (dstFormat.mSampleRate < 22000) {
                outputBitRate = 32000; // 32kbs
            }
            
            // set the bit rate depending on the samplerate chosen
            XThrowIfError(AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate, propSize, &outputBitRate),
                           "AudioConverterSetProperty kAudioConverterEncodeBitRate failed!");
            
            // get it back and print it out
            AudioConverterGetProperty(converter, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
            printf ("AAC Encode Bitrate: %ld\n", outputBitRate);
        }

        // can the Audio Converter resume conversion after an interruption?
        // this property may be queried at any time after construction of the Audio Converter after setting its output format
        // there's no clear reason to prefer construction time, interruption time, or potential resumption time but we prefer
        // construction time since it means less code to execute during or after interruption time
        UInt32 canResume = 0;
        size = sizeof(canResume);
        error = AudioConverterGetProperty(converter, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
        if (noErr == error) {
            // we recieved a valid return value from the GetProperty call
            // if the property's value is 1, then the codec CAN resume work following an interruption
            // if the property's value is 0, then interruptions destroy the codec's state and we're done
            
            if (0 == canResume) canResumeFromInterruption = false;
            
            printf("Audio Converter %s continue after interruption!\n", (canResumeFromInterruption == 0 ? "CANNOT" : "CAN"));
        } else {
            // if the property is unimplemented (kAudioConverterErr_PropertyNotSupported, or paramErr returned in the case of PCM),
            // then the codec being used is not a hardware codec so we're not concerned about codec state
            // we are always going to be able to resume conversion after an interruption
            
            if (kAudioConverterErr_PropertyNotSupported == error) {
                printf("kAudioConverterPropertyCanResumeFromInterruption property not supported - see comments in source for more info.\n");
            } else {
                printf("AudioConverterGetProperty kAudioConverterPropertyCanResumeFromInterruption result %ld, paramErr is OK if PCM\n", error);
            }
            
            error = noErr;
        }
        
        // create the destination file 
        XThrowIfError(AudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &dstFormat, kAudioFileFlags_EraseFile, &destinationFileID), "AudioFileCreateWithURL failed!");

        // set up source buffers and data proc info struct
        afio.srcFileID = sourceFileID;
        afio.srcBufferSize = 32768;
        afio.srcBuffer = new char [afio.srcBufferSize];
        afio.srcFilePos = 0;
        afio.srcFormat = srcFormat;
		
        if (srcFormat.mBytesPerPacket == 0) {
            // if the source format is VBR, we need to get the maximum packet size
            // use kAudioFilePropertyPacketSizeUpperBound which returns the theoretical maximum packet size
            // in the file (without actually scanning the whole file to find the largest packet,
            // as may happen with kAudioFilePropertyMaximumPacketSize)
            size = sizeof(afio.srcSizePerPacket);
            XThrowIfError(AudioFileGetProperty(sourceFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &afio.srcSizePerPacket), "AudioFileGetProperty kAudioFilePropertyPacketSizeUpperBound failed!");
            
            // how many packets can we read for our buffer size?
            afio.numPacketsPerRead = afio.srcBufferSize / afio.srcSizePerPacket;
            
            // allocate memory for the PacketDescription structures describing the layout of each packet
            afio.packetDescriptions = new AudioStreamPacketDescription [afio.numPacketsPerRead];
        } else {
            // CBR source format
            afio.srcSizePerPacket = srcFormat.mBytesPerPacket;
            afio.numPacketsPerRead = afio.srcBufferSize / afio.srcSizePerPacket;
            afio.packetDescriptions = NULL;
        }

        // set up output buffers
        UInt32 outputSizePerPacket = dstFormat.mBytesPerPacket; // this will be non-zero if the format is CBR
        UInt32 theOutputBufSize = 32768;
        outputBuffer = new char[theOutputBufSize];
        
        if (outputSizePerPacket == 0) {
            // if the destination format is VBR, we need to get max size per packet from the converter
            size = sizeof(outputSizePerPacket);
            XThrowIfError(AudioConverterGetProperty(converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &outputSizePerPacket), "AudioConverterGetProperty kAudioConverterPropertyMaximumOutputPacketSize failed!");
            
            // allocate memory for the PacketDescription structures describing the layout of each packet
            outputPacketDescriptions = new AudioStreamPacketDescription [theOutputBufSize / outputSizePerPacket];
        }
        UInt32 numOutputPackets = theOutputBufSize / outputSizePerPacket;

        // if the destination format has a cookie, get it and set it on the output file
        WriteCookie(converter, destinationFileID);

        // write destination channel layout
        if (srcFormat.mChannelsPerFrame > 2) {
            WriteDestinationChannelLayout(converter, sourceFileID, destinationFileID);
        }

        UInt64 totalOutputFrames = 0; // used for debgging printf
        SInt64 outputFilePos = 0;
        
        // loop to convert data
        printf("Converting...\n");
        while (1) {

            // set up output buffer list
            AudioBufferList fillBufList;
            fillBufList.mNumberBuffers = 1;
            fillBufList.mBuffers[0].mNumberChannels = dstFormat.mChannelsPerFrame;
            fillBufList.mBuffers[0].mDataByteSize = theOutputBufSize;
            fillBufList.mBuffers[0].mData = outputBuffer;
            
            // this will block if we're interrupted
            Boolean wasInterrupted = ThreadStatePausedCheck();
            
            if ((error || wasInterrupted) && (false == canResumeFromInterruption)) {
                // this is our interruption termination condition
                // an interruption has occured but the Audio Converter cannot continue
                error = kMyAudioConverterErr_CannotResumeFromInterruptionError;
                break;
            }

            // convert data
            UInt32 ioOutputDataPackets = numOutputPackets;
            printf("AudioConverterFillComplexBuffer...\n");
            error = AudioConverterFillComplexBuffer(converter, EncoderDataProc, &afio, &ioOutputDataPackets, &fillBufList, outputPacketDescriptions);
            // if interrupted in the process of the conversion call, we must handle the error appropriately
            if (error) {
                if (kAudioConverterErr_HardwareInUse == error) {
                     printf("Audio Converter returned kAudioConverterErr_HardwareInUse!\n");
                } else {
                    XThrowIfError(error, "AudioConverterFillComplexBuffer error!");
                }
            } else {
                if (ioOutputDataPackets == 0) {
                    // this is the EOF conditon
                    error = noErr;
                    break;
                }
            }
            
            if (noErr == error) {
                // write to output file
                UInt32 inNumBytes = fillBufList.mBuffers[0].mDataByteSize;
                XThrowIfError(AudioFileWritePackets(destinationFileID, false, inNumBytes, outputPacketDescriptions, outputFilePos, &ioOutputDataPackets, outputBuffer), "AudioFileWritePackets failed!");
            
                printf("Convert Output: Write %lu packets at position %lld, size: %ld\n", ioOutputDataPackets, outputFilePos, inNumBytes);
                
                // advance output file packet position
                outputFilePos += ioOutputDataPackets;

                if (dstFormat.mFramesPerPacket) { 
                    // the format has constant frames per packet
                    totalOutputFrames += (ioOutputDataPackets * dstFormat.mFramesPerPacket);
                } else if (outputPacketDescriptions != NULL) {
                    // variable frames per packet require doing this for each packet (adding up the number of sample frames of data in each packet)
                    for (UInt32 i = 0; i < ioOutputDataPackets; ++i)
                        totalOutputFrames += outputPacketDescriptions[i].mVariableFramesInPacket;
                }
            }
        } // while

        if (noErr == error) {
            // write out any of the leading and trailing frames for compressed formats only
            if (dstFormat.mBitsPerChannel == 0) {
                // our output frame count should jive with
                printf("Total number of output frames counted: %lld\n", totalOutputFrames); 
                WritePacketTableInfo(converter, destinationFileID);
            }
        
            // write the cookie again - sometimes codecs will update cookies at the end of a conversion
            WriteCookie(converter, destinationFileID);
        }
    }
    catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        error = e.mError;
	}
    
    // cleanup
    if (converter) AudioConverterDispose(converter);
    if (destinationFileID) AudioFileClose(destinationFileID);
	if (sourceFileID) AudioFileClose(sourceFileID);
    
    if (afio.srcBuffer) delete [] afio.srcBuffer;
    if (afio.packetDescriptions) delete [] afio.packetDescriptions;
    if (outputBuffer) delete [] outputBuffer;
    if (outputPacketDescriptions) delete [] outputPacketDescriptions;
    
    // transition thread state to kStateDone before continuing
    ThreadStateSetDone();
    
    return error;
}