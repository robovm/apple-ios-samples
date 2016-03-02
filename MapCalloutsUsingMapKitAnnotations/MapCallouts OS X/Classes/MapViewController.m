/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Header file for this sample's main NSViewController.
 */

#import "MapViewController.h"
#import <MapKit/MapKit.h>

#import "SFAnnotation.h"            // annotation for the city of San Francisco
#import "BridgeAnnotation.h"        // annotation for the Golden Gate bridge
#import "WharfAnnotation.h"         // annotation for Fisherman's Wharf

#import "CustomAnnotation.h"        // annotation for the Tea Garden
#import "CustomAnnotationView.h"    // annotation view for the Tea Carbon

#import "BridgeViewController.h"    // custom NSViewController used for the popover


@interface MapViewController () <MKMapViewDelegate>

@property (strong) IBOutlet MKMapView *mapView;

@property (strong) IBOutlet NSMatrix *annotationStates; // series of check boxes to hide/show annotations
@property (strong) IBOutlet NSButtonCell *toggleAllCheckBox;
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
	// create our annotations array
    self.mapAnnotations = [[NSMutableArray alloc] init];
    
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
    
    // annotation for Fisherman's Wharf
    WharfAnnotation *wharfAnnotation = [[WharfAnnotation alloc] init];
    [self.mapAnnotations addObject:wharfAnnotation];
    
    [self gotoDefaultLocation];    // go to San Francisco
    
    // default by showing all annotations
    [self.annotationStates selectAll:self]; // select all the annotation checkboxes
    [self.mapView addAnnotations:self.mapAnnotations];
    
    [self.mapView setShowsZoomControls:YES];
}


#pragma mark - Action methods

- (IBAction)annotationsAction:(id)sender
{
    NSInteger colIdx = [self.annotationStates selectedColumn];
    NSInteger rowIdx = [self.annotationStates selectedRow];
    NSButtonCell *selectedCheckBox = [self.annotationStates cellAtRow:rowIdx column:colIdx];
    
    [self gotoDefaultLocation];
    
    if (selectedCheckBox == self.toggleAllCheckBox)
    {
        // user chose "All" checkbox
        [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
        
        NSButtonCell *allCheckbox = [self.annotationStates cellAtRow:rowIdx column:colIdx];
        if ([allCheckbox state])
        {
            [self.annotationStates selectAll:self];
            [self.mapView addAnnotations:self.mapAnnotations];
        }
        else
        {
            [self.annotationStates deselectAllCells];
        }
    }
    else
    {
        // user chose an individual checkbox
        //
        // uncheck "All" checkbox
        [self.toggleAllCheckBox setState: NSOffState];
        
        if ([selectedCheckBox state])
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
    NSRectEdge prefEdge = NSRectEdgeMaxY;
    
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
        // handle our custom annotations
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
        else if ([annotation isKindOfClass:[WharfAnnotation class]]) // for Fisherman's Wharf
        {
            returnedAnnotationView = [WharfAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            // provide an image view to use as the accessory view's detail view.
            NSImage *image = [NSImage imageNamed:@"wharf"];
            NSRect imageRect = NSMakeRect(0.0, 0.0, image.size.width, image.size.height);
            
            NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageRect];
            [imageView setImage:image];
            NSView *custView = [[NSView alloc] initWithFrame:imageRect];
            [custView addSubview:imageView];

            returnedAnnotationView.detailCalloutAccessoryView = custView;
        }
        else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
        {
            // create/dequeue the city annotation
            //
            returnedAnnotationView = [SFAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            returnedAnnotationView.image = [NSImage imageNamed:@"flag"];
            
            // provide the left image icon for the annotation
            NSImage *sfImage = [NSImage imageNamed:@"SFIcon"];
            NSRect imageRect = NSMakeRect(0.0, 0.0, sfImage.size.width, sfImage.size.height);
            
            NSImageView *sfIconView = [[NSImageView alloc] initWithFrame:imageRect];
            [sfIconView setImage:sfImage];
            NSView *custView = [[NSView alloc] initWithFrame:imageRect];
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
