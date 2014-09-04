/*
    File: AUGraphController.mm
Abstract: Sets up the AUGraph, loading up the audio data using ExtAudioFile, the input render procedure and so on.
 Version: 1.2.2

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

#import "AUGraphController.h"

const Float64 kGraphSampleRate = 44100.0;

#pragma mark- Render

// render some silence
static void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}

// audio render procedure to render our client data format
// 2 ch 'lpcm' 16-bit little-endian signed integer interleaved this is mClientFormat data, see CAStreamBasicDescription SetCanonical()
static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    SourceAudioBufferDataPtr userData = (SourceAudioBufferDataPtr)inRefCon;
    
    AudioSampleType *in = userData->soundBuffer[inBusNumber].data;
    AudioSampleType *out = (AudioSampleType *)ioData->mBuffers[0].mData;
    
    UInt32 sample = userData->frameNum * userData->soundBuffer[inBusNumber].asbd.mChannelsPerFrame;
    
    // make sure we don't attempt to render more data than we have available in the source buffers
    // if one buffer is larger than the other, just render silence for that bus until we loop around again
    if ((userData->frameNum + inNumberFrames) > userData->soundBuffer[inBusNumber].numFrames) {
        UInt32 offset = (userData->frameNum + inNumberFrames) - userData->soundBuffer[inBusNumber].numFrames;
        if (offset < inNumberFrames) {
            // copy the last bit of source
            SilenceData(ioData);
            memcpy(out, &in[sample], ((inNumberFrames - offset) * userData->soundBuffer[inBusNumber].asbd.mBytesPerFrame));
            return noErr;
        } else {
            // we have no source data
            SilenceData(ioData);
            *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
            return noErr;
        }
    }
	
    memcpy(out, &in[sample], ioData->mBuffers[0].mDataByteSize);
    
    //printf("render input bus %ld from sample %ld\n", inBusNumber, sample);
    
    return noErr;
}

// the render notification is used to keep track of the frame number position in the source audio
static OSStatus renderNotification(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    SourceAudioBufferDataPtr userData = (SourceAudioBufferDataPtr)inRefCon;
    
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
    
        //printf("post render notification frameNum %ld inNumberFrames %ld\n", userData->frameNum, inNumberFrames);
        
        userData->frameNum += inNumberFrames;
        if (userData->frameNum >= userData->maxNumFrames) {
            userData->frameNum = 0;
        }
    }
    
    return noErr;
}

#pragma mark- AUGraphController

@interface AUGraphController (hidden)
 
- (void)loadFiles;
 
@end

@implementation AUGraphController

@synthesize mIsPlaying, mEQPresetsArray;

- (void)dealloc
{    
    printf("AUGraphController dealloc\n");
    
    DisposeAUGraph(mGraph);
    
    free(mUserData.soundBuffer[0].data);
    free(mUserData.soundBuffer[1].data);
    
    CFRelease(sourceURL[0]);
    CFRelease(sourceURL[1]);
    
    CFRelease(mEQPresetsArray);

	[super dealloc];
}

- (void)awakeFromNib
{
    printf("AUGraphController awakeFromNib\n");
    
	mIsPlaying = false;

    // clear the mSoundBuffer struct
	memset(&mUserData.soundBuffer, 0, sizeof(mUserData.soundBuffer));
    
    // create the URLs we'll use for source A and B
    NSString *sourceA = [[NSBundle mainBundle] pathForResource:@"Track1" ofType:@"mp4"];
    NSString *sourceB = [[NSBundle mainBundle] pathForResource:@"Track2" ofType:@"mp4"];
    sourceURL[0] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceA, kCFURLPOSIXPathStyle, false);
    sourceURL[1] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceB, kCFURLPOSIXPathStyle, false);
}

- (void)initializeAUGraph
{
    printf("initializeAUGraph\n");
    
    AUNode outputNode;
    AUNode eqNode;
	AUNode mixerNode;
    
    printf("create client ASBD\n");
    
    // client format audio goes into the mixer
    mClientFormat.SetCanonical(2, true);						
    mClientFormat.mSampleRate = kGraphSampleRate;
    mClientFormat.Print();
    
    printf("create output ASBD\n");
    
    // output format
    mOutputFormat.SetAUCanonical(2, false);						
	mOutputFormat.mSampleRate = kGraphSampleRate;
    mOutputFormat.Print();
	
	OSStatus result = noErr;
    
    // load up the audio data
    printf("load up audio data\n");
    [self loadFiles];
    
    printf("\nnew AUGraph\n");
    
    // create a new AUGraph
	result = NewAUGraph(&mGraph);
    if (result) { printf("NewAUGraph result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
	
    // create three Audio Component Descriptons for the AUs we want in the graph using the CAComponentDescription helper class
    
    // output unit
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
    
    // iPodEQ unit
    CAComponentDescription eq_desc(kAudioUnitType_Effect, kAudioUnitSubType_AUiPodEQ, kAudioUnitManufacturer_Apple);
    
    // multichannel mixer unit
	CAComponentDescription mixer_desc(kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer, kAudioUnitManufacturer_Apple);
    
    printf("add nodes\n");

    // create a node in the graph that is an AudioUnit, using the supplied AudioComponentDescription to find and open that unit
	result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
	if (result) { printf("AUGraphNewNode 1 result %lu %4.4s\n", result, (char*)&result); return; }
    
    result = AUGraphAddNode(mGraph, &eq_desc, &eqNode);
    if (result) { printf("AUGraphNewNode 2 result %lu %4.4s\n", result, (char*)&result); return; }

	result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
	if (result) { printf("AUGraphNewNode 3 result %lu %4.4s\n", result, (char*)&result); return; }

    // connect a node's output to a node's input
    // mixer -> eq -> output
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, eqNode, 0);
	if (result) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", result, (char*)&result); return; }
	
    result = AUGraphConnectNodeInput(mGraph, eqNode, 0, outputNode, 0);
    if (result) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", result, (char*)&result); return; }
    
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
	result = AUGraphOpen(mGraph);
	if (result) { printf("AUGraphOpen result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
	
    // grab the audio unit instances from the nodes
	result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    if (result) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    result = AUGraphNodeInfo(mGraph, eqNode, NULL, &mEQ);
    if (result) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }

    // set bus count
	UInt32 numbuses = 2;
	
    printf("set input bus count %lu\n", numbuses);
	
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }

	for (UInt32 i = 0; i < numbuses; ++i) {
		// setup render callback struct
		AURenderCallbackStruct rcbs;
		rcbs.inputProc = &renderInput;
		rcbs.inputProcRefCon = &mUserData;
        
        printf("set AUGraphSetNodeInputCallback\n");
        
        // set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &rcbs);
        if (result) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
		
		printf("set input bus %d, client kAudioUnitProperty_StreamFormat\n", (unsigned int)i);
        
        // set the input stream format, this is the format of the audio for mixer input
		result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &mClientFormat, sizeof(mClientFormat));
        if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
	}
    
    printf("get EQ kAudioUnitProperty_FactoryPresets\n");
    
    // get the eq's factory preset list -- this is a read-only CFArray array of AUPreset structures
    // host owns the retuned array and should release it when no longer needed
    UInt32 size = sizeof(mEQPresetsArray);
    result = AudioUnitGetProperty(mEQ, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &mEQPresetsArray, &size);
    if (result) { printf("AudioUnitGetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    /* this code can be used if you're interested in dumping out the preset list
    printf("iPodEQ Factory Preset List:\n");
    UInt8 count = CFArrayGetCount(mEQPresetsArray);
    for (int i = 0; i < count; ++i) {
        AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, i);
        CFShow(aPreset->presetName);
    }*/
    
    printf("set output kAudioUnitProperty_StreamFormat\n");
    mOutputFormat.Print();
    
    // set the output stream format of the mixer
	result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mOutputFormat, sizeof(mOutputFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    // set the output stream format of the iPodEQ audio unit
    result = AudioUnitSetProperty(mEQ, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mOutputFormat, sizeof(mOutputFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }

    printf("set render notification\n");
    
    // add a render notification, this is a callback that the graph will call every time the graph renders
    // the callback will be called once before the graph’s render operation, and once after the render operation is complete
    result = AUGraphAddRenderNotify(mGraph, renderNotification, &mUserData);
    if (result) { printf("AUGraphAddRenderNotify result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
		
    printf("AUGraphInitialize\n");
								
    // now that we've set everything up we can initialize the graph, this will also validate the connections
	result = AUGraphInitialize(mGraph);
    if (result) { printf("AUGraphInitialize result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    CAShow(mGraph);
}

// load up audio data from the demo files into mSoundBuffer.data used in the render proc
- (void)loadFiles
{
    mUserData.frameNum = 0;
    mUserData.maxNumFrames = 0;
        
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++)  {
        printf("loadFiles, %d\n", i);
        
        ExtAudioFileRef xafref = 0;
        
        // open one of the two source files
        OSStatus result = ExtAudioFileOpenURL(sourceURL[i], &xafref);
        if (result || 0 == xafref) { printf("ExtAudioFileOpenURL result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
        
        // get the file data format, this represents the file's actual data format
        // for informational purposes only -- the client format set on ExtAudioFile is what we really want back
        CAStreamBasicDescription fileFormat;
        UInt32 propSize = sizeof(fileFormat);
        
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
        if (result) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
        
        printf("file %d, native file format\n", i);
        fileFormat.Print();
        
        // set the client format to be what we want back
        // this is the same format audio we're giving to the the mixer input
        result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, sizeof(mClientFormat), &mClientFormat);
        if (result) { printf("ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
        
        // get the file's length in sample frames
        UInt64 numFrames = 0;
        propSize = sizeof(numFrames);
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
        if (result || numFrames == 0) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
               
        // keep track of the largest number of source frames
        if (numFrames > mUserData.maxNumFrames) mUserData.maxNumFrames = numFrames;
        
        // set up our buffer
        mUserData.soundBuffer[i].numFrames = numFrames;
        mUserData.soundBuffer[i].asbd = mClientFormat;

        UInt32 samples = numFrames * mUserData.soundBuffer[i].asbd.mChannelsPerFrame;
        mUserData.soundBuffer[i].data = (AudioSampleType *)calloc(samples, sizeof(AudioSampleType));
        
        // set up a AudioBufferList to read data into
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = mUserData.soundBuffer[i].asbd.mChannelsPerFrame;
        bufList.mBuffers[0].mData = mUserData.soundBuffer[i].data;
        bufList.mBuffers[0].mDataByteSize = samples * sizeof(AudioSampleType);

        // perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
        UInt32 numPackets = numFrames;
        result = ExtAudioFileRead(xafref, &numPackets, &bufList);
        if (result) {
            printf("ExtAudioFileRead result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); 
            free(mUserData.soundBuffer[i].data);
            mUserData.soundBuffer[i].data = 0;
            return;
        }
        
        // close the file and dispose the ExtAudioFileRef
        ExtAudioFileDispose(xafref);
    }
}

#pragma mark-

// enable or disables a specific bus
- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue
{
    printf("BUS %ld isON %f\n", inputNum, isONValue);
         
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }

}

// sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value
{
	OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
}

// sets the overall mixer output volume
- (void)setOutputVolume:(AudioUnitParameterValue)value
{
	OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
}

- (void)selectEQPreset:(NSInteger)value;
{
    AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, value);
    OSStatus result = AudioUnitSetProperty(mEQ, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; };
    
    printf("SET EQ PRESET %d ", value);
    CFShow(aPreset->presetName);
}

// stars render
- (void)startAUGraph
{
    printf("PLAY\n");
    
	OSStatus result = AUGraphStart(mGraph);
    if (result) { printf("AUGraphStart result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
	mIsPlaying = true;
}

// stops render
- (void)stopAUGraph
{
	printf("STOP\n");

    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if (result) { printf("AUGraphIsRunning result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
    
    if (isRunning) {
        result = AUGraphStop(mGraph);
        if (result) { printf("AUGraphStop result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
        mIsPlaying = false;
    }
}

@end