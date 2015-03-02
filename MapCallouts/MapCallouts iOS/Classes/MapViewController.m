/*
     File: MapViewController.m
 Abstract: n/a
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
#import "DetailViewController.h"

#import "SFAnnotation.h"            // annotation for the city of San Francisco
#import "BridgeAnnotation.h"        // annotation for the Golden Gate bridge
#import "CustomAnnotation.h"        // annotation for the Tea Garden

@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *mapAnnotations;
@property (nonatomic, strong) UIPopoverController *bridgePopoverController;

@end


#pragma mark -

@implementation MapViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // restore the nav bar to translucent
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = @"Back";
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
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
    item.coordinate = CLLocationCoordinate2DMake(37.770, -122.4709);
    
    [self.mapAnnotations addObject:item];

    [self allAction:self];  // initially show all annotations
}


#pragma mark - Button Actions

- (void)gotoByAnnotationClass:(Class)annotationClass
{
    // user tapped "City" button in the bottom toolbar
    for (id annotation in self.mapAnnotations)
    {
        if ([annotation isKindOfClass:annotationClass])
        {
            // remove any annotations that exist
            [self.mapView removeAnnotations:self.mapView.annotations];
            // add just the city annotation
            [self.mapView addAnnotation:annotation];
            
            [self gotoDefaultLocation];
        }
    }
}

- (IBAction)cityAction:(id)sender
{
    [self gotoByAnnotationClass:[SFAnnotation class]];
}

- (IBAction)bridgeAction:(id)sender
{
    // user tapped "Bridge" button in the bottom toolbar
    [self gotoByAnnotationClass:[BridgeAnnotation class]];
}

- (IBAction)teaGardenAction:(id)sender
{
    // user tapped "Tea Gardon" button in the bottom toolbar
    [self gotoByAnnotationClass:[CustomAnnotation class]];
}

- (IBAction)allAction:(id)sender
{
    // user tapped "All" button in the bottom toolbar
    
    // remove any annotations that exist
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    // add all 3 annotations
    [self.mapView addAnnotations:self.mapAnnotations];
    
    [self gotoDefaultLocation];
}


#pragma mark - MKMapViewDelegate

// user tapped the disclosure button in the bridge callout
//
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // here we illustrate how to detect which annotation type was clicked on for its callout
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[BridgeAnnotation class]])
    {
        NSLog(@"clicked Golden Gate Bridge annotation");
        
        DetailViewController *detailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"DetailViewController"];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            // for iPad, we use a popover
            if (self.bridgePopoverController == nil)
            {
                _bridgePopoverController = [[UIPopoverController alloc] initWithContentViewController:detailViewController];
            }
            [self.bridgePopoverController presentPopoverFromRect:control.bounds
                                                          inView:control
                                        permittedArrowDirections:UIPopoverArrowDirectionLeft
                                                        animated:YES];
        }
        else
        {
            // for iPhone we navigate to a detail view controller using UINavigationController
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
    }
}

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
            returnedAnnotationView = [BridgeAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            // add a detail disclosure button to the callout which will open a new view controller page or a popover
            //
            // note: when the detail disclosure button is tapped, we respond to it via:
            //       calloutAccessoryControlTapped delegate method
            //
            // by using "calloutAccessoryControlTapped", it's a convenient way to find out which annotation was tapped
            //
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
            ((MKPinAnnotationView *)returnedAnnotationView).rightCalloutAccessoryView = rightButton;
        }
        else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
        {
            returnedAnnotationView = [SFAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            // provide the annotation view's image
            returnedAnnotationView.image = [UIImage imageNamed:@"flag.png"];

            // provide the left image icon for the annotation
            UIImageView *sfIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SFIcon.png"]];
            returnedAnnotationView.leftCalloutAccessoryView = sfIconView;
        }
        else if ([annotation isKindOfClass:[CustomAnnotation class]])  // for Japanese Tea Garden
        {
            returnedAnnotationView = [CustomAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
        }
    }
    
    return returnedAnnotationView;
}

@end
