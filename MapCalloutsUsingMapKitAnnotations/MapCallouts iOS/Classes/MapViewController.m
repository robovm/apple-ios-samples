/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "MapViewController.h"
#import "DetailViewController.h"

#import "SFAnnotation.h"            // annotation for the city of San Francisco
#import "BridgeAnnotation.h"        // annotation for the Golden Gate bridge
#import "CustomAnnotation.h"        // annotation for the Tea Garden

@interface MapViewController () <MKMapViewDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *mapAnnotations;

@end


#pragma mark -

@implementation MapViewController

- (void)gotoDefaultLocation
{
    // start off by default in San Francisco
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = 37.786996;
    newRegion.center.longitude = -122.440100;
    newRegion.span.latitudeDelta = 0.2;
    newRegion.span.longitudeDelta = 0.2;
    
    [self.mapView setRegion:newRegion animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // restore the nav bar to translucent
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = @"Back";
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    // create out annotations array (in this example only 3)
    self.mapAnnotations = [[NSMutableArray alloc] initWithCapacity:3];
    
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

// dismissing the bridge detail view controller
- (void)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //.. done
    }];
}

// For iPhone/compact:
// present/wrap the detail view controller in a navigation controller,
// If this method is not implemented, or returns nil, then the originally presented view controller is used
//
- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
    
    // for the detail view controller we want a black style nav bar
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    UIViewController *presentedViewController = controller.presentedViewController;
    if (presentedViewController != nil)
    {
        presentedViewController.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneAction:)];
    }
    
    return navController;
}

- (void)buttonAction:(id)sender
{
    NSLog(@"clicked Golden Gate Bridge annotation");
    
    DetailViewController *detailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"DetailViewController"];
    detailViewController.edgesForExtendedLayout = UIRectEdgeNone;
    detailViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *presentationController = detailViewController.popoverPresentationController;
    
    // display popover from the UIButton (sender) as the anchor
    presentationController.sourceRect = [sender frame];
    UIButton *button = (UIButton *)sender;
    presentationController.sourceView = button.superview;
    
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    // not required, but useful for presenting "contentVC" in a compact screen so that it
    // can be dismissed as a full screen view controller)
    //
    presentationController.delegate = self;
    
    [self presentViewController:detailViewController animated:YES completion:^{
        //.. done
    }];
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
        // user tapped the Golden Gate Bridge annotation
        //
        // note, we handle the accessory button press in "buttonAction"
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
            [rightButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
            returnedAnnotationView.rightCalloutAccessoryView = rightButton;
        }
        else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
        {
            returnedAnnotationView = [SFAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            // provide the annotation view's image
            returnedAnnotationView.image = [UIImage imageNamed:@"flag"];

            // provide the left image icon for the annotation
            UIImageView *sfIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SFIcon"]];
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
