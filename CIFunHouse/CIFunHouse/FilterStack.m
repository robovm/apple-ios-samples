/*
     File: FilterStack.m
 Abstract: A stack (not in LIFO sense) that manages available/active filters
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

#import "FilterStack.h"

#import "CIFilter+FHAdditions.h"


NSString *const FilterStackActiveFilterListDidChangeNotification = @"FilterStackActiveFilterListDidChangeNotification";


static NSString *const kFilterSettingsKey = @"FilterSettings";
static NSString *const kFilterOrderKey = @"FilterOrder";



@implementation FilterDescriptor
@synthesize name = _name;
@synthesize displayName = _displayName;
@synthesize inputImageCount = _inputImageCount;

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        
        CIFilter* f = [CIFilter filterWithName:name];
        if (f==nil)
        {
            self = nil;
            return nil;
        }
        
        _name = [name copy];
        
        _displayName = [[[f attributes] valueForKey:kCIAttributeFilterDisplayName] copy];

        _inputImageCount = (f.isSourceFilter) ? 0 : f.imageInputCount;
    }
    return self;
}

- (CIFilter*) filter
{
    return [CIFilter filterWithName:_name];
}

@end

@implementation SourceFilter
@synthesize inputImage;

- (CIImage *)outputImage
{
    if (inputImage==nil)
        return [CIImage emptyImage];
    return inputImage;
}

@end

@implementation SourceVideoFilter : SourceFilter

+ (NSDictionary *)customAttributes
{
    return @{ kCIAttributeFilterDisplayName : @"Input Video",
              kCIAttributeFilterCategories : @[kCICategoryVideo] };
}

@end

@implementation SourcePhotoFilter : SourceFilter

+ (NSDictionary *)customAttributes
{
    return @{ kCIAttributeFilterDisplayName : @"Input Photo",
              kCIAttributeFilterCategories : @[kCICategoryStillImage] };
}

@end


@implementation FilterStack
@synthesize activeFilters = _activeFilters;
@synthesize possibleNextFilters = _possibleNextFilters;
@synthesize sources = _sources;
@synthesize sourceCount = _sourceCount;

- (id)init
{
    self = [super init];
    if (self)
    {
        _sourceCount = 0;
        _activeFilters = [[NSArray alloc] init];
        _sources = [[NSMutableArray alloc] init];
        _nonsources = [[NSMutableArray alloc] init];

        FilterDescriptor *d;
        
        FilterDescriptor *video = [[FilterDescriptor alloc] initWithName:@"SourceVideoFilter"];
        [_sources addObject:video];
        
        FilterDescriptor *image = [[FilterDescriptor alloc] initWithName:@"SourcePhotoFilter"];
        [_sources addObject:image];
        
        for (NSString *name in [CIFilter filterNamesInCategory:kCICategoryBuiltIn])
        {
            CIFilter* f = [CIFilter filterWithName:name];
            if (f==nil | f.isUsableFilter == NO)
                continue;
            
            d = [[FilterDescriptor alloc] initWithName:name];
            
            if (f.imageInputCount == 0)
                [_sources addObject:d];
            else
                [_nonsources addObject:d];
        }


        // Add in custom filters here:
        NSArray* customFilters = @[ @"ChromaKey",
                                    @"ColorAccent",
                                    @"PixellatedPeople",
                                    @"TiltShift",
                                    @"OldeFilm",
                                    @"PixellateTransition",
                                    @"DistortionDemo",
                                    @"SobelEdgeH",
                                    @"SobelEdgeV"];

        for (NSString* f in customFilters)
        {
            d = [[FilterDescriptor alloc] initWithName:f];
            [_nonsources addObject:d];
        }
        
        
        _possibleNextFilters = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) _updateFilterList
{
    // Update sourceCount to reflect the number of active sources - i.e,
    // the number of filters that can be used as inputs to new filters
    NSUInteger sourceCount = 0;
    for (CIFilter *filter in _activeFilters)
    {
        for (NSString *attrName in [filter imageInputAttributeKeys])
        {
            if (!filter.isSourceFilter) {
                if (sourceCount > 0)
                    --sourceCount;
            }
        }
        ++sourceCount;
    }
    
    NSUInteger prevSourceCount = _sourceCount;
    _sourceCount = sourceCount;
    
    if (sourceCount != prevSourceCount)
    {
        NSMutableArray *newset = [[NSMutableArray alloc] init];
        
        for (FilterDescriptor* d in _nonsources)
            if (d.inputImageCount <= sourceCount)
                [newset addObject:d];
        
        _possibleNextFilters = newset;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FilterStackActiveFilterListDidChangeNotification object:self];
}

- (BOOL)containsVideoSource
{
    for (CIFilter *filter in _activeFilters)
        if ([filter isKindOfClass:[SourceVideoFilter class]])
            return true;
    return false;
}

- (BOOL)containsPhotoSource
{
    for (CIFilter *filter in _activeFilters)
        if ([filter isKindOfClass:[SourcePhotoFilter class]])
            return true;
    return false;
}

- (void)appendFilter:(CIFilter *)filter
{
    _activeFilters = [_activeFilters arrayByAddingObject:filter];
    [self _updateFilterList];
}

- (void)removeLastFilter
{
    if (_activeFilters.count)
    {
        NSMutableArray *newActiveArray = [_activeFilters mutableCopy];
        [newActiveArray removeLastObject];
        _activeFilters = [newActiveArray copy];
        [self _updateFilterList];
    }
}


@end


static CGFloat gFSGlobalCropFilterMaxValue = INFINITY;

void FCSetGlobalCropFilterMaxValue(CGFloat max)
{
    gFSGlobalCropFilterMaxValue = max;
}

CGFloat FCGetGlobalCropFilterMaxValue(void)
{
    return gFSGlobalCropFilterMaxValue;
}
