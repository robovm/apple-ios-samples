/*

<codex>

*/

#import <UIKit/UIKit.h>

#ifndef LEVELMETER_CLAMP
#define LEVELMETER_CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

// The LevelMeterColorThreshold struct is used to define the colors for the LevelMeter, 
// and at what values each of those colors begins.
typedef struct LevelMeterColorThreshold {
	CGFloat			maxValue; // A value from 0 - 1. The maximum value shown in this color
	UIColor			*color; // A UIColor to be used for this value range
} LevelMeterColorThreshold;

@interface LevelMeter : UIView {
	NSUInteger					_numLights;
	CGFloat						_level, _peakLevel;
	LevelMeterColorThreshold	*_colorThresholds;
	NSUInteger					_numColorThresholds;
	BOOL						_vertical;
	BOOL						_variableLightIntensity;
	UIColor						*_bgColor, *_borderColor;
    CGFloat                     _scaleFactor;
}

// The current level, from 0 - 1
@property						CGFloat level;

// Optional peak level, will be drawn if > 0
@property						CGFloat peakLevel;

// The number of lights to show, or 0 to show a continuous bar
@property						NSUInteger numLights;

// Whether the view is oriented V or H. This is initially automatically set based on the 
// aspect ratio of the view.
@property(getter=isVertical)	BOOL vertical;

// Whether to use variable intensity lights. Has no effect if numLights == 0.
@property						BOOL variableLightIntensity;

// The background color of the lights
@property(retain)				UIColor *bgColor;

// The border color of the lights
@property(retain)				UIColor *borderColor;

// Returns a pointer to the first LevelMeterColorThreshold struct. The number of color 
// thresholds is returned in count
- (LevelMeterColorThreshold *)colorThresholds:(NSUInteger *)count;

// Load <count> elements from <thresholds> and use these as our color threshold values.
- (void)setColorThresholds:(LevelMeterColorThreshold *)thresholds count:(NSUInteger)count;

@end
