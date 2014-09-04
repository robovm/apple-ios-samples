/*
     File: CIFilter+FHAdditions.m
 Abstract: CIFilter category for accessing CIImage input attributes.
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

#import "CIFilter+FHAdditions.h"
#import <objc/runtime.h>
#import "FilterStack.h"

@implementation CIFilter (FunHouseAdditions)

- (NSArray *)imageInputAttributeKeys
{
    // cache the enumerated image input attributes
    static const char *associationKey = "_storedImageInputAttributeKeys";
    NSArray *attributes = (NSArray *)objc_getAssociatedObject(self, associationKey);
    if (!attributes)
    {
        NSMutableArray *addingArray = [NSMutableArray array];
        for (NSString *key in self.inputKeys)
        {
            NSDictionary *attrDict = [self.attributes objectForKey:key];
            if ([[attrDict objectForKey:kCIAttributeType] isEqualToString:kCIAttributeTypeImage])
                [addingArray addObject:key];
        }

        attributes = [addingArray copy];
        objc_setAssociatedObject(self, associationKey, attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return attributes;    
}

- (NSUInteger)imageInputCount
{
    return self.imageInputAttributeKeys.count;
}


- (BOOL)onlyRequiresInputImages
{
    return self.imageInputCount == self.inputKeys.count;
}

- (BOOL)isUsableFilter
{
    // for now only CIColorCube is not usable
    return ![[self name] isEqualToString:@"CIColorCube"];
}

- (BOOL)isSourceFilter
{
    return [self isKindOfClass:[SourceFilter class]];
}


+ (BOOL)isAttributeConfigurable:(NSDictionary *)filterAttributeDictionary
{
    static NSArray *names = nil;
    @synchronized(self)
    {
        if (!names)
            names = @[ @"CIColor", @"CIVector", @"NSNumber" ];
    }
    
    if ([names containsObject:[filterAttributeDictionary objectForKey:kCIAttributeClass]])
        return YES;
    
    NSString *attrType = [filterAttributeDictionary objectForKey:kCIAttributeType];
    if ([attrType isEqualToString:kCIAttributeTypeTransform])
        return YES;
    
    return NO;
}

@end


NSString *CIFilterGetShortenedInputAttributeName (NSString *name)
{
    return [name hasPrefix:@"input"] ? [name substringFromIndex:5] : name;
}

BOOL CIFilterIsValueOfTypeCGAffineTransform (id value)
{
    return [value isKindOfClass:[NSValue class]] && !strcmp([value objCType], @encode(CGAffineTransform));
}
