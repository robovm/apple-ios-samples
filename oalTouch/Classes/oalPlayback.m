/*

    File: oalPlayback.m
Abstract: An Obj-C class which wraps an OpenAL playback environment
 Version: 1.9

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.


*/

#import "oalPlayback.h"
#import "MyOpenALSupport.h"


@implementation oalPlayback

@synthesize isPlaying;
@synthesize wasInterrupted;
@synthesize listenerRotation;
@synthesize iPodIsPlaying;

#pragma mark Object Init / Maintenance
void interruptionListener(	void *	inClientData,
							UInt32	inInterruptionState)
{
	oalPlayback* THIS = (oalPlayback*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
			alcMakeContextCurrent(NULL);		
			if ([THIS isPlaying]) {
				THIS.wasInterrupted = YES;
			}
	}
	else if (inInterruptionState == kAudioSessionEndInterruption)
	{
		OSStatus result = AudioSessionSetActive(true);
		if (result) NSLog(@"Error setting audio session active! %d\n", result);

		alcMakeContextCurrent(THIS->context);

		if (THIS.wasInterrupted)
		{
			[THIS startSound];			
			THIS.wasInterrupted = NO;
		}
	}
}

void RouteChangeListener(	void *                  inClientData,
							AudioSessionPropertyID	inID,
							UInt32                  inDataSize,
							const void *            inData)
{
	CFDictionaryRef dict = (CFDictionaryRef)inData;
	
	CFStringRef oldRoute = CFDictionaryGetValue(dict, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
	
	UInt32 size = sizeof(CFStringRef);
	
	CFStringRef newRoute;
	OSStatus result = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);

	NSLog(@"result: %d Route changed from %@ to %@", result, oldRoute, newRoute);
}
								
- (id)init
{	
	if (self = [super init]) {
		// Start with our sound source slightly in front of the listener
		sourcePos = CGPointMake(0., -70.);
		
		// Put the listener in the center of the stage
		listenerPos = CGPointMake(0., 0.);
		
		// Listener looking straight ahead
		listenerRotation = 0.;
		
		// setup our audio session
		OSStatus result = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
		if (result) NSLog(@"Error initializing audio session! %d\n", result);
		else {
			// if there is other audio playing, we don't want to play the background music
			UInt32 size = sizeof(iPodIsPlaying);
			result = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &iPodIsPlaying);
			if (result) NSLog(@"Error getting other audio playing property! %d", result);

			// if the iPod is playing, use the ambient category to mix with it
			// otherwise, use solo ambient to get the hardware for playing the app background track
			UInt32 category = (iPodIsPlaying) ? kAudioSessionCategory_AmbientSound : kAudioSessionCategory_SoloAmbientSound;
						
			result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
			if (result) NSLog(@"Error setting audio session category! %d\n", result);

			result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, RouteChangeListener, self);
			if (result) NSLog(@"Couldn't add listener: %d", result);

			result = AudioSessionSetActive(true);
			if (result) NSLog(@"Error setting audio session active! %d\n", result);
		}

		bgURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"background" ofType:@"m4a"]];
		bgPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:bgURL error:nil];	
				
		wasInterrupted = NO;
		
		// Initialize our OpenAL environment
		[self initOpenAL];
	}
	
	return self;
}

- (void)checkForMusic
{
	if (iPodIsPlaying) {
		//the iPod is playing, so we should disable the background music switch
		NSLog(@"Disabling background music, iPod is active");
		musicSwitch.enabled = NO;
	}
	else {
		musicSwitch.enabled = YES;
	}
}

- (void)dealloc
{
	[super dealloc];

	[self teardownOpenAL];
	[bgURL release];
	[bgPlayer release];
}

#pragma mark AVAudioPlayer

- (IBAction)toggleMusic:(UISwitch*)sender {
	NSLog(@"togging music %s", sender.on ? "on" : "off");
	
	if (bgPlayer) {
	
		if (sender.on) {
			[bgPlayer play];
		}
		else {
			[bgPlayer stop];
		}
	}	
}

#pragma mark OpenAL

- (void) initBuffer
{
	ALenum  error = AL_NO_ERROR;
	ALenum  format;
	ALsizei size;
	ALsizei freq;
	
	NSBundle*				bundle = [NSBundle mainBundle];
	
	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource:@"sound" ofType:@"caf"]] retain];
	
	if (fileURL)
	{	
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		CFRelease(fileURL);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"error loading sound: %x\n", error);
			exit(1);
		}
		
		// use the static buffer data API
		alBufferDataStaticProc(buffer, format, data, size, freq);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"error attaching audio to buffer: %x\n", error);
		}		
	}
	else
		NSLog(@"Could not find file!\n");
}

- (void) initSource
{
	ALenum error = AL_NO_ERROR;
	alGetError(); // Clear the error
    
	// Turn Looping ON
	alSourcei(source, AL_LOOPING, AL_TRUE);
	
	// Set Source Position
	float sourcePosAL[] = {sourcePos.x, kDefaultDistance, sourcePos.y};
	alSourcefv(source, AL_POSITION, sourcePosAL);
	
	// Set Source Reference Distance
	alSourcef(source, AL_REFERENCE_DISTANCE, 50.0f);
	
	// attach OpenAL Buffer to OpenAL Source
	alSourcei(source, AL_BUFFER, buffer);
	
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"Error attaching buffer to source: %x\n", error);
		exit(1);
	}	
}


- (void)initOpenAL
{
	ALenum			error;
	
	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	device = alcOpenDevice(NULL);
	if (device != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		context = alcCreateContext(device, 0);
		if (context != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(context);
			
			// Create some OpenAL Buffer Objects
			alGenBuffers(1, &buffer);
			if((error = alGetError()) != AL_NO_ERROR) {
				NSLog(@"Error Generating Buffers: %x", error);
				exit(1);
			}
			
			// Create some OpenAL Source Objects
			alGenSources(1, &source);
			if(alGetError() != AL_NO_ERROR) 
			{
				NSLog(@"Error generating sources! %x\n", error);
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
	// Delete the Sources
    alDeleteSources(1, &source);
	// Delete the Buffers
    alDeleteBuffers(1, &buffer);
	
    //Release context
    alcDestroyContext(context);
    //Close device
    alcCloseDevice(device);
}

#pragma mark Play / Pause

- (void)startSound
{
	ALenum error;
	
	NSLog(@"Start!\n");
	// Begin playing our source file
	alSourcePlay(source);
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"error starting source: %x\n", error);
	} else {
		// Mark our state as playing (the view looks at this)
		self.isPlaying = YES;
	}
}

- (void)stopSound
{
	ALenum error;
	
	NSLog(@"Stop!!\n");
	// Stop playing our source file
	alSourceStop(source);
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"error stopping source: %x\n", error);
	} else {
		// Mark our state as not playing (the view looks at this)
		self.isPlaying = NO;
	}
}

#pragma mark Setters / Getters

- (CGPoint)sourcePos
{
	return sourcePos;
}

- (void)setSourcePos:(CGPoint)SOURCEPOS
{
	sourcePos = SOURCEPOS;
	float sourcePosAL[] = {sourcePos.x, kDefaultDistance, sourcePos.y};
	// Move our audio source coordinates
	alSourcefv(source, AL_POSITION, sourcePosAL);
}



- (CGPoint)listenerPos
{
	return listenerPos;
}

- (void)setListenerPos:(CGPoint)LISTENERPOS
{
	listenerPos = LISTENERPOS;
	float listenerPosAL[] = {listenerPos.x, 0., listenerPos.y};
	// Move our listener coordinates
	alListenerfv(AL_POSITION, listenerPosAL);
}



- (CGFloat)listenerRotation
{
	return listenerRotation;
}

- (void)setListenerRotation:(CGFloat)radians
{
	listenerRotation = radians;
	float ori[] = {cos(radians + M_PI_2), sin(radians + M_PI_2), 0., 0., 0., 1.};
	// Set our listener orientation (rotation)
	alListenerfv(AL_ORIENTATION, ori);
}

@end
