/*
     File: FilterAttributeBinding.m
 Abstract: Binding between a CIFilter's attribute and a SliderCell instance.
  Version: 1.0
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "FilterAttributeBinding.h"
#import "FilterStack.h"
#import "CIFilter+FHAdditions.h"

NSString *const FilterAttributeValueDidUpdateNotification = @"FilterAttributeValueDidUpdateNotification";
NSString *const FilterAttributeBindingFilterNameKey = @"FilterName";
NSString *const FilterAttributeBindingAttributeNameKey = @"AttributeName";
NSString *const FilterAttributeBindingAttributeValueStringKey = @"AttributeValueString";

NSString *const kFilterObject = @"FilterObject";
NSString *const kFilterInputValue = @"FilterInputValue";
NSString *const kFilterInputKey = @"FilterInputKey";

@implementation FilterAttributeBinding
@synthesize minElementValue = _minElementValue;
@synthesize maxElementValue = _maxElementValue;

- (id)initWithFilter:(CIFilter *)aFilter attributeName:(NSString *)name dictionary:(NSDictionary *)dictionary screenSize:(CGSize)screenSize;
{
    self = [super init];
    if (self)
    {
        _filter = aFilter;
        _attrName = [name copy];
        _screenSize = screenSize;
        
        NSString *className = [dictionary objectForKey:kCIAttributeClass];
        _attrClass = NSClassFromString(className);
        NSAssert1(_attrClass != nil, @"Must have a valid CIAttributeClass: %@", className);
        
        _attrDefault = [dictionary objectForKey:kCIAttributeDefault];
        
        _attrType = [dictionary objectForKey:kCIAttributeType];
        
        NSNumber *n = nil;
        if ((n = [dictionary objectForKey:kCIAttributeSliderMin]) != nil)
            _minElementValue = [n doubleValue];
        else if ((n = [dictionary objectForKey:kCIAttributeMin]) != nil)
            _minElementValue = [n doubleValue];            
        else
            _minElementValue = -5.0;
        
        if ((n = [dictionary objectForKey:kCIAttributeSliderMax]) != nil)
            _maxElementValue = [n doubleValue];
        else if ((n = [dictionary objectForKey:kCIAttributeMax]) != nil)
            _maxElementValue = [n doubleValue];            
        else
            _maxElementValue = 5.0;
        
        if ([[_filter name] isEqualToString:@"CICrop"])
        {
            // special settings for CICrop
            _minElementValue = 0.0;            
            _maxElementValue = FCGetGlobalCropFilterMaxValue();
            
            CIVector *inputRect = [_filter valueForKey:@"inputRectangle"];
            if ([inputRect isEqual:_attrDefault])
            {
                NSDictionary *info = @{ kFilterObject : _filter,
                                        kFilterInputValue : [CIVector vectorWithX:_minElementValue Y:_minElementValue Z:_maxElementValue W:_maxElementValue],
                                        kFilterInputKey : @"inputRectangle" };
                                        
                [[NSNotificationCenter defaultCenter] postNotificationName:FilterAttributeValueDidUpdateNotification object:nil userInfo:info];
            }
        }
        else if ([[_filter name] isEqualToString:@"CITemperatureAndTint"]) {

            // special settings for CITemperatureAndTint
            _minElementValue = 0.0;
            _maxElementValue = 15000.0;
        }
        else if ([[_filter name] isEqualToString:@"CIAffineTransform"]) {

            // special settings for CIAffineTransform
            _minElementValue = -M_PI * 2;
            _maxElementValue = M_PI * 2;
        }
        
        _sliderCellBindings = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (NSString *)elementTitleForIndex:(NSUInteger)index
{
    if ([_attrDefault isKindOfClass:[NSNumber class]])
    {
        return @"Value";
    }
    else if ([_attrDefault isKindOfClass:[CIVector class]])
    {
        if ([(CIVector*)_attrDefault count] > 4)
            return [NSString stringWithFormat:@"%lu",(unsigned long)index];
        else
            return [NSString stringWithFormat:@"%c", "XYZW"[index] ];
    }
    else if ([_attrDefault isKindOfClass:[CIColor class]])
    {
        switch (index) {
            case 0: return @"R";
            case 1: return @"G";
            case 2: return @"B";
            case 3: return @"A";
            default: return @"Invalid";
        }
    }
    else if (CIFilterIsValueOfTypeCGAffineTransform(_attrDefault))
    {
        switch (index) {
            case 0: return @"a";
            case 1: return @"b";
            case 2: return @"c";
            case 3: return @"d";
            case 4: return @"tx";
            case 5: return @"ty";
            default: return @"Invalid";
        }        
    }
    
    return @"Invalid";
}

- (double)valueForIndex:(NSUInteger)index attribute:(id)attr
{
    if ([attr isKindOfClass:[NSNumber class]])
    {
        return [(NSNumber *)attr doubleValue];
    }
    else if ([attr isKindOfClass:[CIVector class]])
    {
        double v = [(CIVector *)attr valueAtIndex:index];
        if ([_attrType isEqualToString:kCIAttributeTypePosition])
        {
            if (index==0)
                v /= _screenSize.width;
            if (index==1)
                v /= _screenSize.height;
        }
        return v;
    }
    else if ([_attrDefault isKindOfClass:[CIColor class]])
    {
        switch (index) {
            case 0: return [(CIColor *)attr red];
            case 1: return [(CIColor *)attr green];
            case 2: return [(CIColor *)attr blue];
            case 3: return [(CIColor *)attr alpha];
            default: return NAN;
        }
    }
    else if (CIFilterIsValueOfTypeCGAffineTransform(_attrDefault))
    {
        CGAffineTransform transform;
        [attr getValue:&transform];
        switch (index) {
            case 0: return transform.a;
            case 1: return transform.b;
            case 2: return transform.c;
            case 3: return transform.d;
            case 4: return transform.tx;
            case 5: return transform.ty;
            default: return NAN;                
        }
    }
    
    return NAN;
}

- (double)defaultValueForIndex:(NSUInteger)index
{
    return [self valueForIndex:index attribute:_attrDefault];
}

- (double)elementValueForIndex:(NSUInteger)index
{
    return [self valueForIndex:index attribute:[_filter valueForKey:_attrName]];
}

- (void)bindSliderCell:(SliderCell *)cell toElementIndex:(NSUInteger)index
{
    NSAssert([_sliderCellBindings objectForKey:cell] == nil, @"Cell must not already be bound");
    [_sliderCellBindings setObject:[NSNumber numberWithUnsignedInteger:index] forKey:cell];
}

- (void)unbindSliderCell:(SliderCell *)cell
{
    NSAssert([_sliderCellBindings objectForKey:cell] != nil, @"Cell must already be bound");
    [_sliderCellBindings removeObjectForKey:cell];
}

- (void)revertToDefaultValues
{
    //[_filter setValue:_attrDefault forKey:_attrName]
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:_filter, kFilterObject, _attrDefault, kFilterInputValue, _attrName, kFilterInputKey, nil];

    // special case for CICrop
    if ([[_filter name] isEqualToString:@"CICrop"])
    {
        info = @{ kFilterObject : _filter,
                  kFilterInputValue : [CIVector vectorWithX:_minElementValue Y:_minElementValue Z:_maxElementValue W:_maxElementValue],
                  kFilterInputKey : @"inputRectangle" };
    }
    
    for (SliderCell *cell in _sliderCellBindings)
    {
        NSNumber *indexObj = [_sliderCellBindings objectForKey:cell];
        cell.slider.value = [self elementValueForIndex:[indexObj unsignedIntegerValue]];
        [cell.slider sendActionsForControlEvents:UIControlEventValueChanged];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:FilterAttributeValueDidUpdateNotification object:_filter userInfo:info];
}

#pragma mark - Properties

- (NSUInteger)elementCount
{
    if ([_attrDefault isKindOfClass:[NSNumber class]])
        return 1;
    
    else if ([_attrDefault isKindOfClass:[CIVector class]])
        return [(CIVector *)_attrDefault count];
    
    else if ([_attrDefault isKindOfClass:[CIColor class]])
        return 4;
    
    else if (CIFilterIsValueOfTypeCGAffineTransform(_attrDefault))
        return 6;
    
    return 0;
}

- (NSString *)title
{
    return CIFilterGetShortenedInputAttributeName(_attrName);
}

#pragma mark - Delegate methods

- (void)sliderCellValueDidChange:(SliderCell *)cell
{
    NSNumber *indexObj = [_sliderCellBindings objectForKey:cell];
    NSAssert(index, @"Slider cell value change must be originated from a binding");
    
    NSUInteger index = [indexObj unsignedIntegerValue];
    
    id attrValue = nil;
    
    if ([_attrDefault isKindOfClass:[NSNumber class]])
    {
        double value = (double)cell.slider.value;
        //[_filter setValue:[NSNumber numberWithDouble:value] forKey:_attrName];
        attrValue = [NSNumber numberWithDouble:value];
    }
    else if ([_attrDefault isKindOfClass:[CIVector class]])
    {
        CGFloat newValue = (CGFloat)cell.slider.value;
        if ([_attrType isEqualToString:kCIAttributeTypePosition])
        {
            if (index==0)
                newValue *= _screenSize.width;
            if (index==1)
                newValue *= _screenSize.height;
        }

        CIVector *vOld = (CIVector *)[_filter valueForKey:_attrName];
        int vCount = [vOld count];
        
        if (index>=vCount)
            NSAssert(0, @"Invalid element index");
        
        CGFloat* vals = calloc(vCount, sizeof(CGFloat));
        for (int i=0; i<vCount; i++)
            vals[i] = [vOld valueAtIndex:i];
        
        vals[index] = newValue;
        
        CIVector* vNew  = [CIVector vectorWithValues:vals count:vCount];
 
        attrValue = vNew;

        free(vals);
    }
    else if ([_attrDefault isKindOfClass:[CIColor class]])
    {
        CGFloat newValue = (CGFloat)cell.slider.value;
        CIColor *c = (CIColor *)[_filter valueForKey:_attrName];
        CGFloat r = [c red];
        CGFloat g = [c green];
        CGFloat b = [c blue];
        CGFloat a = [c alpha];      
        
        switch (index) {
            case 0: r = newValue; break;
            case 1: g = newValue; break;
            case 2: b = newValue; break;
            case 3: a = newValue; break;
            default:
                NSAssert(0, @"Invalid element index");
        }
        
        c = [CIColor colorWithRed:r green:g blue:b alpha:a];
        //[_filter setValue:c forKey:_attrName];
        attrValue = c;
    }
    else if (CIFilterIsValueOfTypeCGAffineTransform(_attrDefault))
    {
        CGFloat newValue = (CGFloat)cell.slider.value;
        CGAffineTransform transform;
        [[_filter valueForKey:_attrName] getValue:&transform];
        switch (index) {
            case 0: transform.a = newValue; break;
            case 1: transform.b = newValue; break;
            case 2: transform.c = newValue; break;
            case 3: transform.d = newValue; break;
            case 4: transform.tx = newValue; break;
            case 5: transform.ty = newValue; break;
            default:
                NSAssert(0, @"Invalid element index");                
        }
        
        NSValue *newTransformValue = [NSValue valueWithCGAffineTransform:transform];
        attrValue = newTransformValue;
    }

    if (attrValue)
    {
        NSDictionary *info = @{ kFilterObject : _filter,  kFilterInputValue : attrValue,  kFilterInputKey : _attrName };
        [[NSNotificationCenter defaultCenter] postNotificationName:FilterAttributeValueDidUpdateNotification
                                                            object:_filter
                                                          userInfo:info];
    }
}

@end
