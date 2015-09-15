/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An Obj-C class which wraps an OpenAL playback environment.
*/

#import "oalPlayback.h"
#import "MyOpenALSupport.h"


@implementation oalPlayback

@synthesize context;
@synthesize isPlaying;
@synthesize wasInterrupted;
@synthesize listenerRotation;
@synthesize iPodIsPlaying;

#pragma mark AVAudioSession
- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        alcMakeContextCurrent(NULL);
        if (self.isPlaying) {
            self.wasInterrupted = YES;
        }
    } else if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
        
        alcMakeContextCurrent(self.context);
        
        if (self.wasInterrupted)
        {
            [self startSound];
            self.wasInterrupted = NO;
        }
    }
}

#pragma mark -Audio Session Route Change Notification

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)initAVAudioSession
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    iPodIsPlaying = [sessionInstance isOtherAudioPlaying];
    NSString *category = iPodIsPlaying ? AVAudioSessionCategoryAmbient : AVAudioSessionCategorySoloAmbient;
    bool success = [sessionInstance setCategory:category error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(handleInterruption:)
                                            name:AVAudioSessionInterruptionNotification
                                            object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(handleRouteChange:)
                                            name:AVAudioSessionRouteChangeNotification
                                            object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

#pragma mark Object Init / Maintenance
- (id)init
{	
	if (self = [super init]) {
		// Start with our sound source slightly in front of the listener
		sourcePos = CGPointMake(0., -70.);
		
		// Put the listener in the center of the stage
		listenerPos = CGPointMake(0., 0.);
		
		// Listener looking straight ahead
		listenerRotation = 0.;
		
		// Setup AVAudioSession
        [self initAVAudioSession];

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

- (ALCcontext *)context
{
    return context;
}

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
