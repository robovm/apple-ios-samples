/*
     File: MainViewController.m
 Abstract: Implements the main interface to the demo application, allowing the user to display which of Quartz's drawing facilities to demonstrate.
  Version: 3.0
 
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

#import "MainViewController.h"
#import "QuartzViewController.h"
#import "QuartzLines.h"
#import "QuartzPolygons.h"
#import "QuartzCurves.h"
#import "QuartzImages.h"
#import "QuartzRendering.h"
#import "QuartzBlending.h"
#import "QuartzClipping.h"
#import "QuartzBlendingViewController.h"
#import "QuartzPolyViewController.h"
#import "QuartzGradientViewController.h"
#import "QuartzLineViewController.h"
#import "QuartzDashViewController.h"	

#define kCellIdentifier @"com.apple.samplecode.QuartzDemo.CellIdentifier"

@interface MainViewController()
-(void)addController:(QuartzViewController*)controller toSection:(NSString*)sectionName;
-(NSInteger)sectionCount;
-(NSInteger)sectionRowCount:(NSInteger)sectionIndex;
-(NSString*)sectionTitle:(NSInteger)sectionIndex;
-(QuartzViewController*)controllerAtIndexPath:(NSIndexPath*)path;
@end

@implementation MainViewController

-(void)addController:(QuartzViewController*)controller toSection:(NSString*)sectionName
{
	if(sections == nil)
	{
		sections = [[NSMutableDictionary alloc] init];
		sectionNames = [[NSMutableArray alloc] init];
	}
	NSMutableArray *list = sections[sectionName];
	if(list == nil)
	{
		list = [NSMutableArray array];
		[sections setValue:list forKey:sectionName];
		[sectionNames addObject:sectionName];
	}
	[list addObject:controller];
}

-(NSInteger)sectionCount
{
	return sections.count;
}

-(NSInteger)sectionRowCount:(NSInteger)sectionIndex;
{
	return [sections[sectionNames[sectionIndex]] count];
}

-(NSString*)sectionTitle:(NSInteger)sectionIndex
{
	return sectionNames[sectionIndex];
}

-(QuartzViewController*)controllerAtIndexPath:(NSIndexPath*)path
{
	return sections[sectionNames[path.section]][path.row];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	// create our view controllers
	QuartzViewController *controller;

	// Line drawing demo
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzLineView class]];
	controller.title = @"Lines";
	controller.demoInfo = @"QuartzLineView";
	[self addController:controller toSection:@"QuartzLines.m"];

	// Showing the effects of line caps, joins & width
	controller = [[QuartzLineViewController alloc] init];
	controller.title = @"Caps, Joins & Width";
	controller.demoInfo = @"QuartzCapJoinWidthView";
	[self addController:controller toSection:@"QuartzLines.m"];
	
	// Showing the effects of line dash patterns
	controller = [[QuartzDashViewController alloc] init];
	controller.title = @"Dash Patterns";
	controller.demoInfo = @"QuartzDashView";
	[self addController:controller toSection:@"QuartzLines.m"];

	// Rectangle drawing demo
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzRectView class]];
	controller.title = @"Rectangles";
	controller.demoInfo = @"QuartzRectView";
	[self addController:controller toSection:@"QuartzPolygons.m"];

	// Polygon drawing demo
	controller = [[QuartzPolyViewController alloc] init];
	controller.title = @"Polygons";
	controller.demoInfo = @"QuartzPolygonView";
	[self addController:controller toSection:@"QuartzPolygons.m"];

	// Ellipses, arcs, and as a bonus round-rects!
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzEllipseArcView class]];
	controller.title = @"Ellipses & Arcs";
	controller.demoInfo = @"QuartzEllipseArcView";
	[self addController:controller toSection:@"QuartzCurves.m"];

	// Bezier and Quadratic curves
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzBezierView class]];
	controller.title = @"Beziers & Quadratics";
	controller.demoInfo = @"QuartzBezierView";
	[self addController:controller toSection:@"QuartzCurves.m"];

	// Images (drawing once and tiling an image)
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzImageView class]];
	controller.title = @"Images & Tiling";
	controller.demoInfo = @"QuartzImageView";
	[self addController:controller toSection:@"QuartzImages.m"];

	// Drawing a PDF page
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzPDFView class]];
	controller.title = @"PDF";
	controller.demoInfo = @"QuartzPDFView";
	// Since the PDF page is primarily white, we'll use the default status bar style rather than the black status bar style.
	controller.statusStyle = UIStatusBarStyleDefault;
	[self addController:controller toSection:@"QuartzImages.m"];

	// Text
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzTextView class]];
	controller.title = @"Text";
	controller.demoInfo = @"QuartzTextView";
	[self addController:controller toSection:@"QuartzImages.m"];

	// Drawing Patterns
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzPatternView class]];
	controller.title = @"Patterns";
	controller.demoInfo = @"QuartzPatternView";
	[self addController:controller toSection:@"QuartzRendering.m"];

	// Drawing Linear and Radial Gradients
	controller = [[QuartzGradientViewController alloc] init];
	controller.title = @"Gradients";
	controller.demoInfo = @"QuartzGradientView";
	[self addController:controller toSection:@"QuartzRendering.m"];

	// Blending Demo
	controller = [[QuartzBlendingViewController alloc] init];
	controller.title = @"Blending Modes";
	controller.demoInfo = @"QuartzBlendingView";
	[self addController:controller toSection:@"QuartzBlending.m"];

	// Clipping Demo
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzClippingView class]];
	controller.title = @"Clipping";
	controller.demoInfo = @"QuartzClippingView";
	[self addController:controller toSection:@"QuartzClipping.m"];

	// Masking Demo
	controller = [[QuartzViewController alloc] initWithNibName:@"DemoView" viewClass:[QuartzMaskingView class]];
	controller.title = @"Masking";
	controller.demoInfo = @"QuartzMaskingView";
	[self addController:controller toSection:@"QuartzClipping.m"];
}


#pragma mark UIViewController delegate

- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to appear
	// make sure we remove the current selection from our table view
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	// Set the navbar style to its default color for the list view.
	self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	// Set the status bar to its default color for the list view.
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark UITableView delegate methods

// the table's selection has changed, switch to that item's UIViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	QuartzViewController *targetViewController = [self controllerAtIndexPath:indexPath];
	[[self navigationController] pushViewController:targetViewController animated:YES];
}

#pragma mark UITableView data source methods

// tell our table how many sections or groups it will have (always 1(our case)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self sectionCount];
}

// tell our table how many rows it will have,(our case the size of our menuList
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self sectionRowCount:section];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self sectionTitle:section];
}

// tell our table what kind of cell to use and its title for the given row
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
	}
	QuartzViewController *vc = [self controllerAtIndexPath:indexPath];
	cell.textLabel.text = vc.title;
	cell.detailTextLabel.text = vc.demoInfo;
	cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

@end

