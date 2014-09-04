/*

    File: AQLevelMeter.mm
Abstract: n/a
 Version: 2.5

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

Copyright (C) 2012 Apple Inc. All Rights Reserved.


*/

#import "AQLevelMeter.h"

#import "LevelMeter.h"
#import "GLLevelMeter.h"

#import "CAStreamBasicDescription.h"

@interface AQLevelMeter (AQLevelMeter_priv)
- (void)layoutSubLevelMeters;
@end


@implementation AQLevelMeter

@synthesize showsPeaks = _showsPeaks;
@synthesize vertical = _vertical;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_refreshHz = 1. / 30.;
		_showsPeaks = YES;
		_channelNumbers = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0], nil];
		_vertical = NO;
		_useGL = YES;
		_chan_lvls = (AudioQueueLevelMeterState*)malloc(sizeof(AudioQueueLevelMeterState) * [_channelNumbers count]);
		_meterTable = new MeterTable(kMinDBvalue);
		_bgColor = nil;
		_borderColor = nil;
		[self layoutSubLevelMeters];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		_refreshHz = 1. / 30.;
		_showsPeaks = YES;
		_channelNumbers = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0], nil];
		_chan_lvls = (AudioQueueLevelMeterState*)malloc(sizeof(AudioQueueLevelMeterState) * [_channelNumbers count]);
		_vertical = NO;
		_useGL = YES;
		_meterTable = new MeterTable(kMinDBvalue);
		[self layoutSubLevelMeters];
	}
	return self;
}

-(void)setBorderColor: (UIColor *)borderColor
{
	if (_borderColor) [_borderColor release];
	_borderColor = borderColor;
	[_borderColor retain];

	for (NSUInteger i=0; i < [_subLevelMeters count]; i++)
	{
		id meter = [_subLevelMeters objectAtIndex:i];
		if (_useGL)
		{
			((GLLevelMeter*)meter).borderColor = nil;
			((GLLevelMeter*)meter).borderColor = borderColor;
		}
		else
		{
			((LevelMeter*)meter).borderColor = nil;
			((LevelMeter*)meter).borderColor = borderColor;
		}	
	}
}

-(void)setBackgroundColor: (UIColor *)bgColor
{
	if (_bgColor) [_bgColor release];
	_bgColor = bgColor;
	[_bgColor retain];
	
	for (NSUInteger i=0; i < [_subLevelMeters count]; i++)
	{
		id meter = [_subLevelMeters objectAtIndex:i];
		if (_useGL) {
            ((GLLevelMeter*)meter).bgColor = nil;
			((GLLevelMeter*)meter).bgColor = bgColor;
		} else {
            ((GLLevelMeter*)meter).bgColor = nil;
			((LevelMeter*)meter).bgColor = bgColor;
        }
	}
	
}

- (void)layoutSubLevelMeters
{
	int i;
	for (i=0; i<[_subLevelMeters count]; i++)
	{
		UIView *thisMeter = [_subLevelMeters objectAtIndex:i];
		[thisMeter removeFromSuperview];
	}
	[_subLevelMeters release];
	
	NSMutableArray *meters_build = [[NSMutableArray alloc] initWithCapacity:[_channelNumbers count]];
	
	CGRect totalRect;
	
	if (_vertical) totalRect = CGRectMake(0., 0., [self frame].size.width + 2., [self frame].size.height);
	else  totalRect = CGRectMake(0., 0., [self frame].size.width, [self frame].size.height + 2.);
	
	for (i=0; i<[_channelNumbers count]; i++)
	{
		CGRect fr;
		
		if (_vertical) {
			fr = CGRectMake(
							totalRect.origin.x + (((CGFloat)i / (CGFloat)[_channelNumbers count]) * totalRect.size.width), 
							totalRect.origin.y, 
							(1. / (CGFloat)[_channelNumbers count]) * totalRect.size.width - 2., 
							totalRect.size.height
							);
		} else {
			fr = CGRectMake(
							totalRect.origin.x, 
							totalRect.origin.y + (((CGFloat)i / (CGFloat)[_channelNumbers count]) * totalRect.size.height), 
							totalRect.size.width, 
							(1. / (CGFloat)[_channelNumbers count]) * totalRect.size.height - 2.
							);
		}
		
		LevelMeter *newMeter;

		if (_useGL) newMeter = [[GLLevelMeter alloc] initWithFrame:fr];
		else newMeter = [[LevelMeter alloc] initWithFrame:fr];
		
		newMeter.numLights = 30;
		newMeter.vertical = self.vertical;
		newMeter.bgColor = _bgColor;
		newMeter.borderColor = _borderColor;
		
		[meters_build addObject:newMeter];
		[self addSubview:newMeter];
		[newMeter release];
	}	
	
	_subLevelMeters = [[NSArray alloc] initWithArray:meters_build];
	
	[meters_build release];
}


- (void)_refresh
{
	BOOL success = NO;

	// if we have no queue, but still have levels, gradually bring them down
	if (_aq == NULL)
	{
		CGFloat maxLvl = -1.;
		CFAbsoluteTime thisFire = CFAbsoluteTimeGetCurrent();
		// calculate how much time passed since the last draw
		CFAbsoluteTime timePassed = thisFire - _peakFalloffLastFire;
		for (LevelMeter *thisMeter in _subLevelMeters)
		{
			CGFloat newPeak, newLevel;
			newLevel = thisMeter.level - timePassed * kLevelFalloffPerSec;
			if (newLevel < 0.) newLevel = 0.;
			thisMeter.level = newLevel;
			if (_showsPeaks)
			{
				newPeak = thisMeter.peakLevel - timePassed * kPeakFalloffPerSec;
				if (newPeak < 0.) newPeak = 0.;
				thisMeter.peakLevel = newPeak;
				if (newPeak > maxLvl) maxLvl = newPeak;
			}
			else if (newLevel > maxLvl) maxLvl = newLevel;
			
			[thisMeter setNeedsDisplay];
		}
		// stop the timer when the last level has hit 0
		if (maxLvl <= 0.)
		{
			[_updateTimer invalidate];
			_updateTimer = nil;
		}
		
		_peakFalloffLastFire = thisFire;
		success = YES;
	} else {
		
		UInt32 data_sz = sizeof(AudioQueueLevelMeterState) * [_channelNumbers count];
		OSErr status = AudioQueueGetProperty(_aq, kAudioQueueProperty_CurrentLevelMeterDB, _chan_lvls, &data_sz);
		if (status != noErr) goto bail;

		for (int i=0; i<[_channelNumbers count]; i++)
		{
			NSInteger channelIdx = [(NSNumber *)[_channelNumbers objectAtIndex:i] intValue];
			LevelMeter *channelView = [_subLevelMeters objectAtIndex:channelIdx];
			
			if (channelIdx >= [_channelNumbers count]) goto bail;
			if (channelIdx > 127) goto bail;
			
			if (_chan_lvls)
			{
				channelView.level = _meterTable->ValueAt((float)(_chan_lvls[channelIdx].mAveragePower));
				if (_showsPeaks) channelView.peakLevel = _meterTable->ValueAt((float)(_chan_lvls[channelIdx].mPeakPower));
				else channelView.peakLevel = 0.;
				[channelView setNeedsDisplay];
				success = YES;
			}
			
		}
	}
	
bail:
	
	if (!success)
	{
		for (LevelMeter *thisMeter in _subLevelMeters) { thisMeter.level = 0.; [thisMeter setNeedsDisplay]; }
		printf("ERROR: metering failed\n");
	}
}


- (void)dealloc
{
	[_updateTimer invalidate];
	[_channelNumbers release];
	[_subLevelMeters release];
	[_bgColor release];
	[_borderColor release];
	
	delete _meterTable;
	
	[super dealloc];
}


- (AudioQueueRef)aq { return _aq; }
- (void)setAq:(AudioQueueRef)v
{	
	if ((_aq == NULL) && (v != NULL))
	{
		if (_updateTimer) [_updateTimer invalidate];
		
		_updateTimer = [NSTimer 
						scheduledTimerWithTimeInterval:_refreshHz 
						target:self 
						selector:@selector(_refresh) 
						userInfo:nil 
						repeats:YES
						];
	} else if ((_aq != NULL) && (v == NULL)) {
		_peakFalloffLastFire = CFAbsoluteTimeGetCurrent();
	}
	
	_aq = v;
	
	if (_aq)
	{
		try {
			UInt32 val = 1;
			XThrowIfError(AudioQueueSetProperty(_aq, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(UInt32)), "couldn't enable metering");
			
			// now check the number of channels in the new queue, we will need to reallocate if this has changed
			CAStreamBasicDescription queueFormat;
			UInt32 data_sz = sizeof(queueFormat);
			XThrowIfError(AudioQueueGetProperty(_aq, kAudioQueueProperty_StreamDescription, &queueFormat, &data_sz), "couldn't get stream description");

			if (queueFormat.NumberChannels() != [_channelNumbers count])
			{
				NSArray *chan_array;
				if (queueFormat.NumberChannels() < 2)
					chan_array = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0], nil];
				else
					chan_array = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], nil];

				[self setChannelNumbers:chan_array];
				[chan_array release];
				
				_chan_lvls = (AudioQueueLevelMeterState*)realloc(_chan_lvls, queueFormat.NumberChannels() * sizeof(AudioQueueLevelMeterState));
			}
		}
		catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
	} else {
		for (LevelMeter *thisMeter in _subLevelMeters) {
			[thisMeter setNeedsDisplay];
		}
	}
}

- (CGFloat)refreshHz { return _refreshHz; }
- (void)setRefreshHz:(CGFloat)v
{
	_refreshHz = v;
	if (_updateTimer)
	{
		[_updateTimer invalidate];
		_updateTimer = [NSTimer 
						scheduledTimerWithTimeInterval:_refreshHz 
						target:self 
						selector:@selector(_refresh) 
						userInfo:nil 
						repeats:YES
						];
	}
}


- (NSArray *)channelNumbers { return _channelNumbers; }
- (void)setChannelNumbers:(NSArray *)v
{
	[v retain];
	[_channelNumbers release];
	_channelNumbers = v;
	[self layoutSubLevelMeters];
}

- (BOOL)useGL { return _useGL; }
- (void)setUseGL:(BOOL)v
{
	_useGL = v;
	[self layoutSubLevelMeters];
}

/*- (void)pauseTimer
{
	[_updateTimer invalidate];
	_updateTimer = nil;
}

- (void)resumeTimer
{
	if (_aq)
	{
		_updateTimer = [NSTimer 
						scheduledTimerWithTimeInterval:_refreshHz 
						target:self 
						selector:@selector(_refresh) 
						userInfo:nil 
						repeats:YES
						];
	}
}*/

@end
