/*
     File: MusicCubePlayback.m
 Abstract: Defines the audio playback object for the application. The object responds to the OpenAL environment.
  Version: 1.3
 
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

#import "MusicCubePlayback.h"
#import "MyOpenALSupport.h"

#import <AVFoundation/AVAudioSession.h>


@implementation MusicCubePlayback

@synthesize isPlaying = _isPlaying;
@synthesize wasInterrupted = _wasInterrupted;
@synthesize listenerRotation = _listenerRotation;

#pragma mark Object Init / Maintenance


- (void)handleInterruption:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = [[[notification userInfo]
                                                        objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if (AVAudioSessionInterruptionTypeBegan == interruptionType)
    {
        // do nothing
        [self teardownOpenAL];
        if (_isPlaying) {
            _wasInterrupted = YES;
            _isPlaying = NO;
        }
    }
    else if (AVAudioSessionInterruptionTypeEnded == interruptionType)
    {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (nil != error) NSLog(@"Error setting audio session active! %@", error);
        
        [self initOpenAL];
        if (_wasInterrupted)
        {
            [self startSound];
            _wasInterrupted = NO;
        }
    }
}

- (id)init
{	
	if (self = [super init]) {
		// initial position of the sound source and 
		// initial position and rotation of the listener
		// will be set by the view
		
		// setup our audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                    object:sessionInstance];
        
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryAmbient error:&error];
        if(nil != error) NSLog(@"Error setting audio session category! %@", error);
        else {
            [sessionInstance setActive:YES error:&error];
            if (nil != error) NSLog(@"Error setting audio session active! %@", error);
        }
		
		_wasInterrupted = NO;
		
		// Initialize our OpenAL environment
		[self initOpenAL];
	}
	
	return self;
}

- (void)dealloc
{
	if (_data) free(_data);
		
	[self teardownOpenAL];
	[super dealloc];
}

#pragma mark OpenAL

- (void) initBuffer
{
	ALenum  error = AL_NO_ERROR;
	ALenum  format = 0;
	ALsizei size = 0;
	ALsizei freq = 0;
	
	NSBundle*				bundle = [NSBundle mainBundle];
	
	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource:@"sound" ofType:@"wav"]] retain];
	
	if (fileURL)
	{	
		_data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		CFRelease(fileURL);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error loading sound: %x\n", error);
			exit(1);
		}
		
		// use the static buffer data API
		alBufferDataStaticProc(_buffer, format, _data, size, freq);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error attaching audio to buffer: %x\n", error);
		}		
	}
	else
	{
		printf("Could not find file!\n");
		_data = NULL;
	}
}

- (void) initSource
{
	ALenum error = AL_NO_ERROR;
	alGetError(); // Clear the error
    
	// Turn Looping ON
	alSourcei(_source, AL_LOOPING, AL_TRUE);
	
	// Set Source Position
	alSourcefv(_source, AL_POSITION, _sourcePos);
	
	// Set Source Reference Distance
	alSourcef(_source, AL_REFERENCE_DISTANCE, 0.15f);
	
	// attach OpenAL Buffer to OpenAL Source
	alSourcei(_source, AL_BUFFER, _buffer);
	
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("Error attaching buffer to source: %x\n", error);
		exit(1);
	}	
}


- (void)initOpenAL
{
	ALenum			error;
	ALCcontext		*newContext = NULL;
	ALCdevice		*newDevice = NULL;
	
	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		newContext = alcCreateContext(newDevice, 0);
		if (newContext != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(newContext);
			
			// Create some OpenAL Buffer Objects
			alGenBuffers(1, &_buffer);
			if((error = alGetError()) != AL_NO_ERROR) {
				printf("Error Generating Buffers: %x", error);
				exit(1);
			}
			
			// Create some OpenAL Source Objects
			alGenSources(1, &_source);
			if(alGetError() != AL_NO_ERROR) 
			{
				printf("Error generating sources! %x\n", error);
				exit(1);
			}
			
		}
	}
	// clear any errors
	alGetError();
	
	[self initBuffer];	
	[self initSource];
}

- (void)teardownOpenAL
{
    ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
	
	// Delete the Sources
    alDeleteSources(1, &_source);
	// Delete the Buffers
    alDeleteBuffers(1, &_buffer);
	
	//Get active context (there can only be one)
    context = alcGetCurrentContext();
    //Get device for active context
    device = alcGetContextsDevice(context);
    //Release context
    alcDestroyContext(context);
    //Close device
    alcCloseDevice(device);
}

#pragma mark Play / Pause

- (void)startSound
{
	ALenum error;
	
	printf("Start!\n");
	// Begin playing our source file
	alSourcePlay(_source);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error starting source: %x\n", error);
	} else {
		// Mark our state as playing
		self.isPlaying = YES;
	}
}

- (void)stopSound
{
	ALenum error;
	
	printf("Stop!!\n");
	// Stop playing our source file
	alSourceStop(_source);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error stopping source: %x\n", error);
	} else {
		// Mark our state as not playing
		self.isPlaying = NO;
	}
}

#pragma mark Setters / Getters

- (float*)sourcePos
{
	return _sourcePos;
}

- (void)setSourcePos:(float*)SOURCEPOS
{
	int i;
	for (i=0; i<3; i++)
		_sourcePos[i] = SOURCEPOS[i];
	
	// Move our audio source coordinates
	alSourcefv(_source, AL_POSITION, _sourcePos);
}



- (float*)listenerPos
{
	return _listenerPos;
}

- (void)setListenerPos:(float*)LISTENERPOS
{
	int i;
	for (i=0; i<3; i++)
		_listenerPos[i] = LISTENERPOS[i];
	
	// Move our listener coordinates
	alListenerfv(AL_POSITION, _listenerPos);
}



- (float)listenerRotation
{
	return _listenerRotation;
}

- (void)setListenerRotation:(float)radians
{
	_listenerRotation = radians;
	float ori[] = {0., cos(radians), sin(radians), 1., 0., 0.};
	// Set our listener orientation (rotation)
	alListenerfv(AL_ORIENTATION, ori);
}

@end
