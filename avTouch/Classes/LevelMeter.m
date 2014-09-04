/*

<codex>

*/

#import "LevelMeter.h"


int _cmp_levelThresholds(const void * a, const void * b)
{
	if (((LevelMeterColorThreshold *)a)->maxValue > ((LevelMeterColorThreshold *)b)->maxValue) return 1;
	if (((LevelMeterColorThreshold *)a)->maxValue < ((LevelMeterColorThreshold *)b)->maxValue) return -1;
	return 0;
}


@implementation LevelMeter

@synthesize vertical = _vertical;
@synthesize bgColor = _bgColor;
@synthesize borderColor = _borderColor;
@synthesize variableLightIntensity = _variableLightIntensity;

- (void)_performInit
{
	_level = 0.;
	_numLights = 0;
	_numColorThresholds = 3;
	_variableLightIntensity = YES;
	_bgColor = [[UIColor alloc] initWithRed:0. green:0. blue:0. alpha:0.6];
	_borderColor = [[UIColor alloc] initWithRed:0. green:0. blue:0. alpha:1.];
	_colorThresholds = malloc(3 * sizeof(LevelMeterColorThreshold));
	_colorThresholds[0].maxValue = 0.25;
	_colorThresholds[0].color = [[UIColor alloc] initWithRed:0. green:1. blue:0. alpha:1.];
	_colorThresholds[1].maxValue = 0.8;
	_colorThresholds[1].color = [[UIColor alloc] initWithRed:1. green:1. blue:0. alpha:1.];
	_colorThresholds[2].maxValue = 1.;
	_colorThresholds[2].color = [[UIColor alloc] initWithRed:1. green:0. blue:0. alpha:1.];
	_vertical = ([self frame].size.width < [self frame].size.height) ? YES : NO;
}


- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self _performInit];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder]) {
		[self _performInit];
	}
	return self;
}


- (void)drawRect:(CGRect)rect
{
	CGColorSpaceRef cs = NULL;
	CGContextRef cxt = NULL;
	CGRect bds;
	
	cxt = UIGraphicsGetCurrentContext();
	cs = CGColorSpaceCreateDeviceRGB();
	
	if (_vertical)
	{
		CGContextTranslateCTM(cxt, 0., [self bounds].size.height);
		CGContextScaleCTM(cxt, 1., -1.);
		bds = [self bounds];
	} else {
		CGContextTranslateCTM(cxt, 0., [self bounds].size.height);
		CGContextRotateCTM(cxt, -M_PI_2);
		bds = CGRectMake(0., 0., [self bounds].size.height, [self bounds].size.width);
	}
	
	CGContextSetFillColorSpace(cxt, cs);
	CGContextSetStrokeColorSpace(cxt, cs);
	
	if (_numLights == 0)
	{
		int i;
		CGFloat currentTop = 0.;
		
		if (_bgColor)
		{
			[_bgColor set];
			CGContextFillRect(cxt, bds);
		}
		
		for (i=0; i<_numColorThresholds; i++)
		{
			LevelMeterColorThreshold thisThresh = _colorThresholds[i];
			CGFloat val = MIN(thisThresh.maxValue, _level);
			
			CGRect rect = CGRectMake(
									 0, 
									 (bds.size.height) * currentTop, 
									 bds.size.width, 
									 (bds.size.height) * (val - currentTop)
									 );
			
			[thisThresh.color set];
			CGContextFillRect(cxt, rect);
			
			if (_level < thisThresh.maxValue) break;
			
			currentTop = val;
		}
		
		if (_borderColor)
		{
			[_borderColor set];
			CGContextStrokeRect(cxt, CGRectInset(bds, .5, .5));
		}
		
	} else {
		int light_i;
		CGFloat lightMinVal = 0.;
		CGFloat insetAmount, lightVSpace;
		lightVSpace = bds.size.height / (CGFloat)_numLights;
		if (lightVSpace < 4.) insetAmount = 0.;
		else if (lightVSpace < 8.) insetAmount = 0.5;
		else insetAmount = 1.;
		
		int peakLight = -1;
		if (_peakLevel > 0.)
		{
			peakLight = _peakLevel * _numLights;
			if (peakLight >= _numLights) peakLight = _numLights - 1;
		}
		
		for (light_i=0; light_i<_numLights; light_i++)
		{
			CGFloat lightMaxVal = (CGFloat)(light_i + 1) / (CGFloat)_numLights;
			CGFloat lightIntensity;
			CGRect lightRect;
			UIColor *lightColor;
			
			if (light_i == peakLight)
			{
				lightIntensity = 1.;
			} else {
				lightIntensity = (_level - lightMinVal) / (lightMaxVal - lightMinVal);
				lightIntensity = LEVELMETER_CLAMP(0., lightIntensity, 1.);
				if ((!_variableLightIntensity) && (lightIntensity > 0.)) lightIntensity = 1.;
			}
			
			lightColor = _colorThresholds[0].color;
			int color_i;
			for (color_i=0; color_i<(_numColorThresholds-1); color_i++)
			{
				LevelMeterColorThreshold thisThresh = _colorThresholds[color_i];
				LevelMeterColorThreshold nextThresh = _colorThresholds[color_i + 1];
				if (thisThresh.maxValue <= lightMaxVal) lightColor = nextThresh.color;
			}
			
			lightRect = CGRectMake(
								   0., 
								   bds.size.height * ((CGFloat)(light_i) / (CGFloat)_numLights), 
								   bds.size.width,
								   bds.size.height * (1. / (CGFloat)_numLights)
								   );
			lightRect = CGRectInset(lightRect, insetAmount, insetAmount);
			
			if (_bgColor)
			{
				[_bgColor set];
				CGContextFillRect(cxt, lightRect);
			}
			
			if (lightIntensity == 1.)
			{
				[lightColor set];
				CGContextFillRect(cxt, lightRect);
			} else if (lightIntensity > 0.) {
				CGColorRef clr = CGColorCreateCopyWithAlpha([lightColor CGColor], lightIntensity);
				CGContextSetFillColorWithColor(cxt, clr);
				CGContextFillRect(cxt, lightRect);
				CGColorRelease(clr);
			}
			
			if (_borderColor)
			{
				[_borderColor set];
				CGContextStrokeRect(cxt, CGRectInset(lightRect, 0.5, 0.5));
			}
			
			lightMinVal = lightMaxVal;
		}
		
	}
	
	CGColorSpaceRelease(cs);
}


- (void)dealloc {
	int i;
	for (i=0; i<_numColorThresholds; i++) [_colorThresholds[i].color release];
	free(_colorThresholds);
	
	[_bgColor release];
	[_borderColor release];
	
	[super dealloc];
}


- (CGFloat)level { return _level; }
- (void)setLevel:(CGFloat)v { _level = v; }

- (CGFloat)peakLevel { return _peakLevel; }
- (void)setPeakLevel:(CGFloat)v { _peakLevel = v; }

- (NSUInteger)numLights { return _numLights; }
- (void)setNumLights:(NSUInteger)v { _numLights = v; }

- (LevelMeterColorThreshold *)colorThresholds:(NSUInteger *)count
{
	*count = _numColorThresholds;
	return _colorThresholds;
}

- (void)setColorThresholds:(LevelMeterColorThreshold *)thresholds count:(NSUInteger)count
{
	int i;
	for (i=0; i<_numColorThresholds; i++) [_colorThresholds[i].color release];
	_colorThresholds = realloc(_colorThresholds, sizeof(LevelMeterColorThreshold) * count);
	
	for (i=0; i<count; i++)
	{
		_colorThresholds[i].maxValue = thresholds[i].maxValue;
		_colorThresholds[i].color = [thresholds[i].color copy];
	}
	
	qsort(_colorThresholds, count, sizeof(LevelMeterColorThreshold), _cmp_levelThresholds);
	
	_numColorThresholds = count;
}



@end
