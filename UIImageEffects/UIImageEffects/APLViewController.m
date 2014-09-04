/*
     File: APLViewController.m
 Abstract: Simple view controller to loads a view and update an image.
  Version: 1.1
 
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

#import "APLViewController.h"
#import "UIImageEffects.h"

#import <mach/mach.h>
#import <mach/mach_time.h>

@interface APLViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *effectLabel;

@property (nonatomic) UIImage *image;
@property (nonatomic) int imageIndex;

@end


@implementation APLViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.image = [UIImage imageNamed:@"DisplayImage"];    
    [self updateImage:nil];
    
    [self showAlertForFirstRun];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.1)
    {
        // There was a bug in iOS versions 7.0.x which caused vImage buffers
        // created using vImageBuffer_InitWithCGImage to be initialized with data
        // that had the reverse channel ordering (RGBA) if BOTH of the following
        // conditions were met:
        //      1) The vImage_CGImageFormat structure passed to
        //         vImageBuffer_InitWithCGImage was configured with
        //         (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little)
        //         for the bitmapInfo member.  That is, if you wanted a BGRA
        //         vImage buffer.
        //      2) The CGImage object passed to vImageBuffer_InitWithCGImage
        //         was loaded from an asset catalog.
        //
        // To reiterate, this bug only affected images loaded from asset
        // catalogs.
        //
        // The workaround is to setup a bitmap context, draw the image, and
        // capture the contents of the bitmap context in a new image.
        UIGraphicsBeginImageContextWithOptions(self.image.size, NO, self.image.scale);
        [self.image drawAtPoint:CGPointZero];
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}


//| ----------------------------------------------------------------------------
- (IBAction)updateImage:(id)sender
{
    NSString *effectText = @"";
    UIImage *effectImage = nil;
    
    switch (self.imageIndex)
    {
        case 0:
            effectImage = self.image;
            break;
        case 1:
            effectImage = [UIImageEffects imageByApplyingLightEffectToImage:self.image];
            effectText = NSLocalizedString(@"Light", @"");
            self.effectLabel.textColor = [UIColor darkTextColor];
            break;
        case 2:
            effectImage = [UIImageEffects imageByApplyingExtraLightEffectToImage:self.image];
            effectText = NSLocalizedString(@"Extra light", @"");
            self.effectLabel.textColor = [UIColor darkTextColor];
            break;
        case 3:
            effectImage = [UIImageEffects imageByApplyingDarkEffectToImage:self.image];
            effectText = NSLocalizedString(@"Dark", @"");
            self.effectLabel.textColor = [UIColor lightTextColor];
            break;
        case 4:
            effectImage = [UIImageEffects imageByApplyingTintEffectWithColor:[UIColor blueColor] toImage:self.image];
            effectText = NSLocalizedString(@"Color tint", @"");
            self.effectLabel.textColor = [UIColor lightTextColor];
            break;
    }
    
    self.imageView.image = effectImage;
    self.effectLabel.text = effectText;
    
}


//| ----------------------------------------------------------------------------
- (IBAction)nextEffect:(id)sender
{
    self.imageIndex++;
    
    if (self.imageIndex > 4)
    {
        self.imageIndex = 0;
    }

    [self updateImage:sender];
}


//| ----------------------------------------------------------------------------
- (void)showAlertForFirstRun
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    static NSString *DidFirstRunKey = @"DidFirstRun";
    BOOL didFirstRun = [userDefaults boolForKey:DidFirstRunKey];
    if (!didFirstRun)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tap to change image effect", @"") message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") otherButtonTitles:nil];
        [alert show];
        [userDefaults setBool:YES forKey:DidFirstRunKey];
    }
}


@end
