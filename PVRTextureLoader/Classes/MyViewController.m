/*

    File: MyViewController.m
Abstract: MyViewController is the view controller responsible for managing the views that make up the user interface.
 Version: 1.6

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

#import "MyViewController.h"
#import "EAGLView.h"
#import "ControlView.h"

@implementation MyViewController

- (void)changeCompression:(id)sender
{
	[(EAGLView *)self.view setCompressionSetting:(int)[sender selectedSegmentIndex]];
}


- (void)changeMipmap:(id)sender
{
	[(EAGLView *)self.view setMipmapFilterSetting:(int)[sender selectedSegmentIndex]];
}


- (void)changeFilter:(id)sender
{
	[(EAGLView *)self.view setFilterSetting:(int)[sender selectedSegmentIndex]];
}

- (void)viewDidLoad
{
	_controlView = [[ControlView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height-[ControlView barHeight], 
																 self.view.frame.size.width, 150.0f)];
	
	// Add controls to control view
	CGRect controlFrame;
	int borderWidth = 5;
	float controlSpacing, currSpacing = [ControlView barHeight];
	SEL controlSelectors[] = { @selector(changeCompression:), @selector(changeMipmap:), @selector(changeFilter:) };
	int numControls = sizeof(controlSelectors)/sizeof(controlSelectors[0]);
	UISegmentedControl *controls[numControls];
	int numDivs = 2 + numControls - 1;
	
	NSArray *compressionControlText = [NSArray arrayWithObjects:@"None", @"4BPP", @"2BPP", nil];
	if (![(EAGLView *)self.view compressionSupported])
		compressionControlText = [NSArray arrayWithObjects:@"None", nil];
	
	NSArray *mipmapFilterControlText = [NSArray arrayWithObjects:@"Off", @"Nearest", @"Linear", nil];
	
	NSArray *textureFilterControlText = [NSArray arrayWithObjects:@"Nearest", @"Linear", @"Super", nil];
	if (![(EAGLView *)self.view anisotropySupported])
		textureFilterControlText = [NSArray arrayWithObjects:@"Nearest", @"Linear", nil];
		
	NSArray *controlText = [NSArray arrayWithObjects:compressionControlText, mipmapFilterControlText, textureFilterControlText, nil];
	NSArray *labelText = [NSArray arrayWithObjects:@"Compression", @"Mipmap Filter", @"Texture Filter", nil];
	UILabel *label;
	
	for (int i=0; i < numControls; i++)
	{			
		controls[i] = [[[UISegmentedControl alloc] initWithItems:[controlText objectAtIndex:i]] autorelease];
        [controls[i] setSegmentedControlStyle:UISegmentedControlStyleBar];
		[controls[i] setSelectedSegmentIndex:0];
		controlFrame = controls[i].frame;
		
		if (i == 0)
			currSpacing += controlSpacing = floorf(([_controlView contentHeight] - (controlFrame.size.height * numControls))/numDivs);
		else
			currSpacing += controlSpacing + controls[i].frame.size.height;
		
		label = [[[UILabel alloc] initWithFrame:CGRectMake(borderWidth,
														   currSpacing,
														   _controlView.frame.size.width - (2 * borderWidth) - controls[i].frame.size.width,
														   controls[i].frame.size.height)] autorelease];
		label.text = [labelText objectAtIndex:i];
		label.textColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		[_controlView addSubview:label];
		
		controlFrame.origin.x = _controlView.frame.size.width - controlFrame.size.width - borderWidth;
		controlFrame.origin.y = currSpacing;
		[controls[i] setFrame:controlFrame];
		controls[i].tintColor = [UIColor colorWithRed:0.40f green:0.40f blue:0.40f alpha:0.65f];
		controls[i].tag = i;
		[controls[i] addTarget:self action:controlSelectors[i] forControlEvents:UIControlEventValueChanged];
		[_controlView addSubview:controls[i]];
	}
	
	[self.view addSubview:_controlView];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
	[_controlView release];
	
    [super dealloc];
}

@end
