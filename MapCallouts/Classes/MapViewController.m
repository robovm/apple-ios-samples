/*
     File: MapViewController.m 
 Abstract: The primary view controller containing the MKMapView, adding and removing both MKPinAnnotationViews through its toolbar. 
  Version: 1.4 
  
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

#import "MapViewController.h"
#import "DetailViewController.h"

#import "SFAnnotation.h"        // annotation for the city of San Francisco
#import "BridgeAnnotation.h"    // annotation for the Golden Gate bridge

#import "CustomMapItem.h"
#import "CustomAnnotationView.h"

typedef enum AnnotationIndex : NSUInteger
{
    kCityAnnotationIndex = 0,
    kBridgeAnnotationIndex,
    kTeaGardenAnnotationIndex
} AnnotationIndex;

@interface MapViewController ()

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet DetailViewController *detailViewController;

@property (nonatomic, strong) NSMutableArray *mapAnnotations;

@end


#pragma mark -

@implementation MapViewController

+ (CGFloat)annotationPadding;
{
    return 10.0f;
}

+ (CGFloat)calloutHeight;
{
    return 40.0f;
}

- (void)gotoLocation
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
    // restore the nav bar to translucent
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = @"Back";
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    // create out annotations array (in this example only 3)
    self.mapAnnotations = [[NSMutableArray alloc] initWithCapacity:2];
    
    // annotation for the City of San Francisco
    SFAnnotation *sfAnnotation = [[SFAnnotation alloc] init];
    [self.mapAnnotations insertObject:sfAnnotation atIndex:kCityAnnotationIndex];
    
    // annotation for Golden Gate Bridge
    BridgeAnnotation *bridgeAnnotation = [[BridgeAnnotation alloc] init];
    [self.mapAnnotations insertObject:bridgeAnnotation atIndex:kBridgeAnnotationIndex];
    
    // annotation for Japanese Tea Garden
    CustomMapItem *item = [[CustomMapItem alloc] init];
    item.place = @"Tea Garden";
    item.imageName = @"teagarden";
    item.latitude = [NSNumber numberWithDouble:37.7700];
    item.longitude = [NSNumber numberWithDouble:-122.4701];
    [self.mapAnnotations insertObject:item atIndex:kTeaGardenAnnotationIndex];
    
    [self gotoLocation];    // finally goto San Francisco
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}
#endif

#pragma mark - ButtonActions

- (void)gotoAnnotationIndex:(AnnotationIndex)annotationIndex
{
    [self gotoLocation];
    
    [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
    
    [self.mapView addAnnotation:[self.mapAnnotations objectAtIndex:annotationIndex]];
}

- (IBAction)cityAction:(id)sender
{
    [self gotoAnnotationIndex:kCityAnnotationIndex];
}

- (IBAction)bridgeAction:(id)sender
{
    [self gotoAnnotationIndex:kBridgeAnnotationIndex];
}

- (IBAction)teaGardenAction:(id)sender
{
    [self gotoAnnotationIndex:kTeaGardenAnnotationIndex];
}

- (IBAction)allAction:(id)sender
{
    [self gotoLocation];
    
    [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
    
    [self.mapView addAnnotations:self.mapAnnotations];
}


#pragma mark - MKMapViewDelegate

// user tapped the disclosure button in the callout
//
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // here we illustrate how to detect which annotation type was clicked on for its callout
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[BridgeAnnotation class]])
    {
        NSLog(@"clicked Golden Gate Bridge annotation");
    }
    
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // in case it's the user location, we already have an annotation, so just return nil
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    
    // handle our three custom annotations
    //
    if ([annotation isKindOfClass:[BridgeAnnotation class]]) // for Golden Gate Bridge
    {
        // try to dequeue an existing pin view first
        static NSString *BridgeAnnotationIdentifier = @"bridgeAnnotationIdentifier";
        
        MKPinAnnotationView *pinView =
            (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:BridgeAnnotationIdentifier];
        if (pinView == nil)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc]
                                             initWithAnnotation:annotation reuseIdentifier:BridgeAnnotationIdentifier];
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: when the detail disclosure button is tapped, we respond to it via:
            //       calloutAccessoryControlTapped delegate method
            //
            // by using "calloutAccessoryControlTapped", it's a convenient way to find out which annotation was tapped
            //
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
            customPinView.rightCalloutAccessoryView = rightButton;

            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
    {
        static NSString *SFAnnotationIdentifier = @"SFAnnotationIdentifier";
        
        MKAnnotationView *flagAnnotationView =
            [self.mapView dequeueReusableAnnotationViewWithIdentifier:SFAnnotationIdentifier];
        if (flagAnnotationView == nil)
        {
            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                             reuseIdentifier:SFAnnotationIdentifier];
            annotationView.canShowCallout = YES;
           
            UIImage *flagImage = [UIImage imageNamed:@"flag.png"];
            
            // size the flag down to the appropriate size
            CGRect resizeRect;
            resizeRect.size = flagImage.size;
            CGSize maxSize = CGRectInset(self.view.bounds,
                                         [MapViewController annotationPadding],
                                         [MapViewController annotationPadding]).size;
            maxSize.height -= self.navigationController.navigationBar.frame.size.height + [MapViewController calloutHeight];
            if (resizeRect.size.width > maxSize.width)
                resizeRect.size = CGSizeMake(maxSize.width, resizeRect.size.height / resizeRect.size.width * maxSize.width);
            if (resizeRect.size.height > maxSize.height)
                resizeRect.size = CGSizeMake(resizeRect.size.width / resizeRect.size.height * maxSize.height, maxSize.height);
            
            resizeRect.origin = CGPointMake(0.0, 0.0);
            UIGraphicsBeginImageContext(resizeRect.size);
            [flagImage drawInRect:resizeRect];
            UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            annotationView.image = resizedImage;
            annotationView.opaque = NO;
             
            UIImageView *sfIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SFIcon.png"]];
            annotationView.leftCalloutAccessoryView = sfIconView;
            
            // offset the flag annotation so that the flag pole rests on the map coordinate
            annotationView.centerOffset = CGPointMake( annotationView.centerOffset.x + annotationView.image.size.width/2, annotationView.centerOffset.y - annotationView.image.size.height/2 );
            
            return annotationView;
        }
        else
        {
            flagAnnotationView.annotation = annotation;
        }
        return flagAnnotationView;
    }
    else if ([annotation isKindOfClass:[CustomMapItem class]])  // for Japanese Tea Garden
    {
        static NSString *TeaGardenAnnotationIdentifier = @"TeaGardenAnnotationIdentifier";
        
        CustomAnnotationView *annotationView =
        (CustomAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:TeaGardenAnnotationIdentifier];
        if (annotationView == nil)
        {
            annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:TeaGardenAnnotationIdentifier];
        }
        return annotationView;
    }
    
    return nil;
}

@end
