/*
     File: ViewController.m
 Abstract: The view controller creates a few blub views which host the custom layer subclass.
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "ViewController.h"
#import "BulbView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    // Load the bulb image.
    UIImage* bulb = [UIImage imageNamed:@"bulb.png"];

    // Base the size of the bulb views on the screen size.
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat bulbHeight = screenHeight / 2.1;
    
    // Maintain image proportions by basing width on the width-to-height ratio.
    CGFloat widthHeightRatio = bulb.size.width / bulb.size.height;
    NSLog(@"widthHeightRatio: %f", widthHeightRatio );
    CGFloat bulbWidth = ( bulbHeight * widthHeightRatio ) * 1.5; // times 1.5 to fatten up the bulb for added visual effect.
    
    // Define our view hierarchy.
    BulbView* view;
    CGRect startingFrame = CGRectMake( 0, 0, bulbWidth, bulbHeight );
    view = [[BulbView alloc] initWithFrame:startingFrame];
    [view setColor:[UIColor redColor]];
    view.center = CGPointMake( .25 * screenWidth, .20 * screenHeight );
    [self.view addSubview:view];
    view = [[BulbView alloc] initWithFrame:startingFrame];
    [view setColor:[UIColor greenColor]];
    view.center = CGPointMake( .5 * screenWidth, .5 * screenHeight );
    [self.view addSubview:view];
    view = [[BulbView alloc] initWithFrame:startingFrame];
    [view setColor:[UIColor blueColor]];
    view.center = CGPointMake( .75 * screenWidth, .80 * screenHeight );
    [self.view addSubview:view];
    
    // Display an alert view that explains usability.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tap blubs to animate." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    // optional - add more buttons:
    //[alert addButtonWithTitle:@"Ok"];
    [alert show];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
