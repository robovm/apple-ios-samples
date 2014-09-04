/*
 
     File: MoviePlayerUserPrefs.m 
 Abstract: Contains methods to get the application user preferences settings for the movie scaling 
 mode, control style, background color, repeat mode, application audio session and background image.
  
  Version: 1.5 
  
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

#import "MoviePlayerUserPrefs.h"

// Application preference keys
NSString *kScalingModeKey					= @"scalingMode";
NSString *kControlStyleKey					= @"controlStyle";
NSString *kBackgroundColorKey				= @"backgroundColor";
NSString *kRepeatModeKey					= @"repeatMode";
NSString *kMovieBackgroundImageKey			= @"useMovieBackgroundImage";


@implementation MoviePlayerUserPrefs

#pragma mark Movie User Preference Settings

// avoid false positives for scalingModeDefault in the static analyzer
#ifndef __clang_analyzer__

+ (void)registerDefaults
{
    /* First get the movie player settings defaults (scaling, controller type, background color,
	 repeat mode, application audio session) set by the user via the built-in iPhone Settings 
	 application */
    
    NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:kScalingModeKey];
    if (testValue == nil)
    {
        // No default movie player settings values have been set, create them here based on our 
        // settings bundle info.
        //
        // The values to be set for movie playback are:
        //
        //    - scaling mode (None, Aspect Fill, Aspect Fit, Fill)
        //    - controller style (None, Fullscreen, Embedded)
        //    - background color (Any UIColor value)
        //    - repeat mode (None, One)
		//    - use application audio session (On, Off)
		//	  - background image
        
        NSString *pathStr = [[NSBundle mainBundle] bundlePath];
        NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
        NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
        
        NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        NSArray *prefSpecifierArray = settingsDict[@"PreferenceSpecifiers"];
        
        NSNumber *controlStyleDefault = nil;
        NSNumber *scalingModeDefault = nil;
        NSNumber *backgroundColorDefault = nil;
        NSNumber *repeatModeDefault = nil;
		NSNumber *movieBackgroundImageDefault = nil;
        
        NSDictionary *prefItem;
        for (prefItem in prefSpecifierArray)
        {
            NSString *keyValueStr = prefItem[@"Key"];
            id defaultValue = prefItem[@"DefaultValue"];
            
            if ([keyValueStr isEqualToString:kScalingModeKey])
            {
                scalingModeDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kControlStyleKey])
            {
                controlStyleDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kBackgroundColorKey])
            {
                backgroundColorDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kRepeatModeKey])
            {
                repeatModeDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kMovieBackgroundImageKey])
            {
                movieBackgroundImageDefault = defaultValue;
            }
        }
        
        // since no default values have been set, create them here
        NSDictionary *appDefaults =  @{kScalingModeKey: scalingModeDefault,
                                      kControlStyleKey: controlStyleDefault,
                                      kBackgroundColorKey: backgroundColorDefault,
									  kRepeatModeKey: repeatModeDefault,
                                      kMovieBackgroundImageKey: movieBackgroundImageDefault};
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
	else 
	{
		/*
			Writes any modifications to the persistent domains to disk and updates all unmodified 
			persistent domains to what is on disk.
		*/
		[[NSUserDefaults standardUserDefaults] synchronize];
	}


}

#endif

+(MPMovieScalingMode)scalingModeUserSetting
{
	[self registerDefaults];

    /* 
        Movie scaling mode can be one of: MPMovieScalingModeNone, MPMovieScalingModeAspectFit,
            MPMovieScalingModeAspectFill, MPMovieScalingModeFill.
			
		Movie scaling mode describes how the movie content is scaled to fit the frame of its view.
		It may be one of:

			MPMovieScalingModeNone, MPMovieScalingModeAspectFit, MPMovieScalingModeAspectFill,
			MPMovieScalingModeFill.
   */
	return([[NSUserDefaults standardUserDefaults] integerForKey:kScalingModeKey]);
}

+(MPMovieControlStyle)controlStyleUserSetting
{
	[self registerDefaults];

    /* 
        Movie control style can be one of: MPMovieControlStyleNone, MPMovieControlStyleEmbedded,
            MPMovieControlStyleFullscreen.
			
		Movie control style describes the style of the playback controls.
		It can be one of:
			
			MPMovieControlStyleNone, MPMovieControlStyleEmbedded, MPMovieControlStyleFullscreen,
			MPMovieControlStyleDefault, MPMovieControlStyleFullscreen
   */

    return([[NSUserDefaults standardUserDefaults] integerForKey:kControlStyleKey]);
}

+(UIColor *)backgroundColorUserSetting
{
	[self registerDefaults];

    /*
        The color of the background area behind the movie can be any UIColor value.
    */
    UIColor *colors[15] = {[UIColor blackColor], [UIColor darkGrayColor], [UIColor lightGrayColor], [UIColor whiteColor], 
        [UIColor grayColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor cyanColor], 
        [UIColor yellowColor], [UIColor magentaColor],[UIColor orangeColor], [UIColor purpleColor], [UIColor brownColor], 
        [UIColor clearColor]};
    return (colors[ [[NSUserDefaults standardUserDefaults] integerForKey:kBackgroundColorKey] ] );
}

+(MPMovieRepeatMode)repeatModeUserSetting
{
	[self registerDefaults];

    /* 
		Movie repeat mode describes how the movie player repeats content at the end of playback.
	
        Movie repeat mode can be one of: MPMovieRepeatModeNone, MPMovieRepeatModeOne.
			
   */
    return([[NSUserDefaults standardUserDefaults] integerForKey:kRepeatModeKey]);
}

+(BOOL)backgroundImageUserSetting
{
	[self registerDefaults];

	return([[NSUserDefaults standardUserDefaults] integerForKey:kMovieBackgroundImageKey]);
}

@end
