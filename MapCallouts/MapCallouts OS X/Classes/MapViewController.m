/*
     File: MapViewController.m
 Abstract: Header file for this sample's main NSViewController.
 
  Version: 1.5
 
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

#import "MapViewController.h"
#import <MapKit/MapKit.h>

#import "SFAnnotation.h"            // annotation for the city of San Francisco
#import "BridgeAnnotation.h"        // annotation for the Golden Gate bridge

#import "CustomAnnotation.h"        // annotation for the Tea Garden
#import "CustomAnnotationView.h"    // annotation view for the Tea Carbon

#import "BridgeViewController.h"    // custom NSViewController used for the popover


@interface MapViewController () <MKMapViewDelegate>

@property (strong) IBOutlet MKMapView *mapView;

@property (strong) IBOutlet NSMatrix *annotationStates; // series of radio buttons to hide/show annotations
@property (strong) NSMutableArray *mapAnnotations;

@property (strong) NSPopover *myPopover;    // popover to display Golden Gate bridge (or BridgeViewController)
@property (strong) IBOutlet BridgeViewController *bridgeViewController;

@end


#pragma mark -

@implementation MapViewController

+ (CGFloat)annotationPadding    { return 10.0f; }
+ (CGFloat)calloutHeight        { return 40.0f; }

- (void)gotoDefaultLocation
{
    // start off by default in San Francisco
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = 37.786996;
    newRegion.center.longitude = -122.440100;
    newRegion.span.latitudeDelta = 0.112872;
    newRegion.span.longitudeDelta = 0.109863;
    
    [self.mapView setRegion:newRegion animated:YES];
}

- (void)awakeFromNib
{
	// create out annotations array (in this example only 3)
    self.mapAnnotations = [[NSMutableArray alloc] initWithCapacity:2];
    
    // annotation for the City of San Francisco
    SFAnnotation *sfAnnotation = [[SFAnnotation alloc] init];
    [self.mapAnnotations addObject:sfAnnotation];
    
    // annotation for Golden Gate Bridge
    BridgeAnnotation *bridgeAnnotation = [[BridgeAnnotation alloc] init];
    [self.mapAnnotations addObject:bridgeAnnotation];
    
    // annotation for Japanese Tea Garden
    CustomAnnotation *item = [[CustomAnnotation alloc] init];
    item.place = @"Tea Garden";
    item.imageName = @"teagarden";
    item.coordinate = CLLocationCoordinate2DMake(37.770, -122.4701);
    [self.mapAnnotations addObject:item];
    
    [self gotoDefaultLocation];    // go to San Francisco
    
    // default by showing all annotations
    [self.annotationStates selectAll:self]; // select all the annotation checkboxes
    [self.mapView addAnnotations:self.mapAnnotations];
    
    [self.mapView setShowsZoomControls:YES];
}


#pragma mark - Action methods

- (IBAction)annotationsAction:(id)sender
{
    NSMatrix *annotationStates = (NSMatrix *)sender;
    
    NSInteger colIdx = [annotationStates selectedColumn];
    NSInteger rowIdx = [annotationStates selectedRow];
    NSButton *checkCheckBox = [annotationStates cellAtRow:rowIdx column:colIdx];
    
    [self gotoDefaultLocation];
    
    if (colIdx > 2)
    {
        // user chose "All" checkbox
        [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
        
        NSButton *allCheckbox = [annotationStates cellAtRow:rowIdx column:colIdx];
        if ([allCheckbox state])
        {
            [annotationStates selectAll:self];
            [self.mapView addAnnotations:self.mapAnnotations];
        }
        else
        {
            [annotationStates deselectAllCells];
        }
    }
    else
    {
        // user chose an individual checkbox
        if ([checkCheckBox state])
            [self.mapView addAnnotation:[self.mapAnnotations objectAtIndex:colIdx]];
        else
            [self.mapView removeAnnotation:[self.mapAnnotations objectAtIndex:colIdx]];
    }
}

- (IBAction)bridgeInfoAction:(id)sender
{
    // user clicked the Info button inside the BridgeAnnotation
    //
    NSButton *targetButton = (NSButton *)sender;
    
    // configure the preferred position of the popover
    NSRectEdge prefEdge = CGRectMaxYEdge;
    
    [self createPopover];
    [self.myPopover showRelativeToRect:[targetButton bounds] ofView:sender preferredEdge:prefEdge];
}

- (void)createPopover
{
    if (self.myPopover == nil)
    {
        // create and setup our popover
        _myPopover = [[NSPopover alloc] init];

        self.myPopover.contentViewController = self.bridgeViewController;
        self.myPopover.animates = YES;
        
        // AppKit will close the popover when the user interacts with a user interface
        // element outside the popover.  Note that interacting with menus or panels that
        // become key only when needed will not cause a transient popover to close.
        //
        self.myPopover.behavior = NSPopoverBehaviorTransient;
    }
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *returnedAnnotationView = nil;
    
    // in case it's the user location, we already have an annotation, so just return nil
    if (![annotation isKindOfClass:[MKUserLocation class]])
    {
        // handle our three custom annotations
        //
        if ([annotation isKindOfClass:[BridgeAnnotation class]]) // for Golden Gate Bridge
        {
            // create/dequeue the pin annotation view first
            returnedAnnotationView = [BridgeAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];

            // add a detail disclosure button to the callout which will open a popover for the bridge
            NSButton *rightButton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 80.0)];
            [rightButton setTitle:@"Info"];
            [rightButton setTarget:self];
            [rightButton setAction:@selector(bridgeInfoAction:)];
            [rightButton setBezelStyle:NSShadowlessSquareBezelStyle];
            returnedAnnotationView.rightCalloutAccessoryView = rightButton;
        }
        else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
        {
            // create/dequeue the city annotation
            //
            returnedAnnotationView = [SFAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            returnedAnnotationView.image = [NSImage imageNamed:@"flag.png"];
            
            // provide the left image icon for the annotation
            NSImage *sfImage = [NSImage imageNamed:@"SFIcon.png"];
            NSRect imageRect = NSMakeRect(0.0, 0.0, sfImage.size.width, sfImage.size.height);
            NSImageView *sfIconView = [[NSImageView alloc] initWithFrame:imageRect];
            [sfIconView setImage:sfImage];
            NSView *custView = [[NSView alloc] initWithFrame:NSMakeRect(imageRect.origin.x, imageRect.origin.y, imageRect.size.width+10, imageRect.size.height)];
            [custView addSubview:sfIconView];
            returnedAnnotationView.leftCalloutAccessoryView = custView;
        }
        else if ([annotation isKindOfClass:[CustomAnnotation class]])  // for Japanese Tea Garden
        {
            // create/dequeue tea garden annotation
            returnedAnnotationView = [CustomAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
        }
    }
    
    return returnedAnnotationView;
}

@end
