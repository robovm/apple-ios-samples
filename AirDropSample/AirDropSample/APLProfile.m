/*
 
     File: APLProfile.m
 Abstract: Custom class that holds a name and an image, and can be sent over AirDrop.
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

#import "APLProfile.h"
#import "UIImage+Resize.h"
#import "APLUtilities.h"

NSString * const kProfileNameKey = @"kProfileName";
NSString * const kProfileImageKey = @"kProfileImageKey";
NSString * const kProfileImageContentModeKey = @"kProfileImageContentModeKey";
NSString * const kCustomFileUTI = @"com.apple.customProfileUTI.customprofile";


@implementation APLProfile

- (instancetype)initWithName:(NSString *)name image:(UIImage *)image
{
    if ((self = [super init])) {
        _name = name;
        _image = [UIImage imageWithImage:image scaledToFitToSize:CGSizeMake(560, 470)];
    }
    return self;
}

- (NSString *)filename
{
    if (_filename) {
        return _filename;
    }
    
    _filename = [NSString stringWithFormat:@"profile-%@.customprofile", [[[NSUUID UUID] UUIDString] substringWithRange:NSMakeRange(24, 12)]];
    return _filename;
}

- (void)setImage:(UIImage *)image
{
    _image = [UIImage imageWithImage:image scaledToFitToSize:CGSizeMake(560, 470)];
    
    //Update thumbnail image as well
    _thumbnailImage = [UIImage imageWithImage:image scaledToFillToSize:CGSizeMake(44, 44)];
}

- (UIImage *)thumbnailImage
{
    if (_thumbnailImage) {
        return _thumbnailImage;
    }
    
    
    if (self.image) {
        _thumbnailImage = [UIImage imageWithImage:self.image scaledToFillToSize:CGSizeMake(44, 44)];
    }
    
    return _thumbnailImage;
}

#pragma mark - NSCoding

/****************************************************
 NSCoding
 
 The NSCoding protocol is required because the objects need to be serialized into NSData before transmission.
 
 ******************************************************/

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:kProfileNameKey];
    [aCoder encodeObject:_image forKey:kProfileImageKey];
    [aCoder encodeObject:@(_imageContentMode) forKey:kProfileImageContentModeKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    APLProfile *newProfile = nil;
    
    NSString * name = [aDecoder decodeObjectOfClass:[NSString class] forKey:kProfileNameKey];
    UIImage *image = [aDecoder decodeObjectOfClass:[UIImage class] forKey:kProfileImageKey];
    NSNumber *contentMode = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:kProfileImageContentModeKey];
    
    if (name && image && contentMode) {
        newProfile = [self initWithName:name image:image];
        newProfile.imageContentMode = [contentMode integerValue];
    }
    return newProfile;
}

+ (BOOL)supportsSecureCoding
{
    return  YES;
}


#pragma mark - UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    //Let the activity view controller know NSData is being sent by passing this placeholder.
    return [NSData data];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    //Serialize this object for sending. NSCoding protocol must be implemented for the serialization to occur.
    return [APLUtilities securelyArchiveRootObject:self];
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType
{
    //Custom UTI (see ReadMe.txt and Info.plist for more information about creating custom UTIs).
    return kCustomFileUTI;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size
{
    //Image will be displayed in the receiver's sharing alert.
    UIImage *scaledImage;
    if (self.imageContentMode == UIViewContentModeScaleAspectFill) {
        scaledImage = [UIImage imageWithImage:self.image scaledToFillToSize:size];
    }
    else
    {
        scaledImage = [UIImage imageWithImage:self.image scaledToFitToSize:size];
    }
    
    return scaledImage;
}

@end
