/*
     File: MapViewController.m 
 Abstract: n/a 
  Version: 1.2 
  
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
*/

#import "AssetsDataIsInaccessibleViewController.h"
#import "AssetViewController.h"
#import "CrumbPath.h"
#import "CrumbPathView.h"
#import "FavoriteAssets.h"
#import "MapAnnotation.h"
#import "MapViewController.h"

#import <QuartzCore/QuartzCore.h>


static UIEdgeInsets pinPadding = { 64.f, 64.f, 64.f, 64.f };

@interface MapViewController()
- (void)dropPins;
@end

@implementation MapViewController

@synthesize assetsList;
@synthesize favoriteAssets;
@synthesize map;

- (void)viewDidLoad {
    loadPinsData = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.title = assetsList.title;

    [map setDelegate:self];

    if (!loadPinsData) {
        return;
    }
    
    if (!annotations) {
        annotations = [[NSMutableArray alloc] init];
    } else {
        [annotations removeAllObjects];
    }
    
    ALAssetsGroupEnumerationResultsBlock enumerationBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        
        if (!asset) {
            loadPinsData = NO;
            [self performSelectorOnMainThread:@selector(dropPins) withObject:nil waitUntilDone:NO];
        } else {
            CLLocation *assetLocation = [asset valueForProperty:ALAssetPropertyLocation];
            if (CLLocationCoordinate2DIsValid([assetLocation coordinate])) {
                MapAnnotation *mapAnnotation = [[MapAnnotation alloc] initWithAsset:asset];
                [annotations addObject:mapAnnotation];
                [mapAnnotation release];
            }
        }
    };

    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        
        AssetsDataIsInaccessibleViewController *assetsDataInaccessibleViewController = [[AssetsDataIsInaccessibleViewController alloc] initWithNibName:@"AssetsDataIsInaccessibleViewController" bundle:nil];
        
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"The user has declined access to it.";
                break;
            default:
                errorMessage = @"Reason unknown.";
                break;
        }
        
        assetsDataInaccessibleViewController.explanation = errorMessage;
        [self presentViewController:assetsDataInaccessibleViewController animated:NO completion:nil];
        [assetsDataInaccessibleViewController release];
    };

    [assetsList loadAssets:enumerationBlock failureBlock:failureBlock];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoriteAssetsChanged:) name:kFavoriteAssetsChanged object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFavoriteAssetsChanged object:nil];
    [self.map setDelegate:nil];
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark MapViewDelegate implementation

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"mapAnnotation"];
    
    if (pinAnnotationView) {
        [pinAnnotationView prepareForReuse];
    } else {
        pinAnnotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"mapAnnotation"] autorelease];
    }
    
    pinAnnotationView.canShowCallout = YES;
    
    CGImageRef thumbnailImageRef = [[(MapAnnotation *)annotation annotationAsset] thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];

    UIImageView *thumbnailImageView = [[UIImageView alloc] initWithImage:thumbnail];
    CGRect newBounds = CGRectMake(0.0, 0.0, 32.0, 32.0);
    [thumbnailImageView setBounds:newBounds];
    pinAnnotationView.leftCalloutAccessoryView = thumbnailImageView;
    [thumbnailImageView release];
    
    UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    pinAnnotationView.rightCalloutAccessoryView = disclosureButton;
    [disclosureButton addTarget:self action:@selector(showFullSizeImage:) forControlEvents:UIControlEventTouchUpInside];

    
    return pinAnnotationView;
}

- (void)showFullSizeImage:(id)sender {

    MapAnnotation *annotation = [[map selectedAnnotations] objectAtIndex:0];
    
    
    AssetViewController *assetViewController = [[AssetViewController alloc] initWithNibName:@"AssetViewController" bundle:nil];
    assetViewController.asset = annotation.annotationAsset;
    assetViewController.favoriteAssets = favoriteAssets;
    
    [[self navigationController] pushViewController:assetViewController animated:YES];
    [assetViewController release];
}

#pragma mark -
#pragma mark Map Animations

- (void)dropPins {
    
    [map removeAnnotations:[map annotations]];
    [map removeOverlays:[map overlays]];
    
    [crumbPath release];
    crumbPath = nil;
    [crumbPathView release];
    crumbPathView = nil;
    
    [annotations sortUsingSelector:@selector(compareByDate:)];
    
    MKMapRect boundingRect = MKMapRectNull;
    NSUInteger i = 0;
    for (MKPointAnnotation *point in annotations) {
        MKMapPoint mp = MKMapPointForCoordinate(point.coordinate);
        MKMapRect pRect = MKMapRectMake(mp.x, mp.y, 0, 0);
        if (i == 0) {
            boundingRect = pRect;
        } else {
            boundingRect = MKMapRectUnion(boundingRect, pRect);
        }        
        i++;
    }
    
    [map setVisibleMapRect:boundingRect edgePadding:pinPadding animated:NO];
    [map addAnnotations:annotations];
}

- (void)bringToFrontAnnotationAtIndex:(NSUInteger)annotationIndex {
    
    MKPinAnnotationView *previousAnnotation = (id)( annotationIndex > 0 ? [map viewForAnnotation:[annotations objectAtIndex:annotationIndex - 1]] : nil);
    MKPinAnnotationView *currentAnnotation = (id)[map viewForAnnotation:[annotations objectAtIndex:annotationIndex]];
    
    previousAnnotation.layer.zPosition = 0;
    currentAnnotation.layer.zPosition = 1;
}

- (void)goToFirstPin {
    
    if (![annotations count])
        return;
    
    currentPointIndex = 0;
    MKPointAnnotation *first = [annotations objectAtIndex:0];
    [self bringToFrontAnnotationAtIndex:0];
    
    crumbPath = [[CrumbPath alloc] initWithCenterCoordinate:first.coordinate];
    [map addOverlay:crumbPath];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(first.coordinate, 2000, 2000);
    goingToPoint = YES;
    [map setRegion:region animated:YES];
}

- (void)goToNextPin {
    currentPointIndex++;
    
    if (currentPointIndex == [annotations count]) {
        return;
    }
    
    MapAnnotation *point = [annotations objectAtIndex:currentPointIndex];
    [self bringToFrontAnnotationAtIndex:currentPointIndex];
    
    MKMapRect updateRect = [crumbPath addCoordinate:point.coordinate];
    if (!MKMapRectIsNull(updateRect)) {
        MKMapRect currentRect = map.visibleMapRect;
        MKMapRect currentCenterRect = MKMapRectMake(MKMapRectGetMidX(currentRect), MKMapRectGetMidY(currentRect), 0, 0);
        MKMapPoint newCenterPoint = MKMapPointForCoordinate(point.coordinate);
        MKMapRect newCenterRect = MKMapRectMake(newCenterPoint.x, newCenterPoint.y, 0, 0);
        
        MKMapRect newRect = MKMapRectUnion(currentCenterRect, newCenterRect);
        
        goingToPoint = YES;
        [crumbPathView setNeedsDisplay];
        [map setVisibleMapRect:newRect edgePadding:pinPadding animated:YES];
    } else {
        // no coordinate change, go straight to the next point
        [self goToNextPin];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (goingToPoint) {
        goingToPoint = NO;
        
        [self performSelector:@selector(goToNextPin) withObject:nil afterDelay:0.3];
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    if (!crumbPathView)
        crumbPathView = [[CrumbPathView alloc] initWithOverlay:overlay];
    return crumbPathView;
}

- (void)drawAnimatedPathBetweenPins:(id)sender {
    [self performSelector:@selector(goToFirstPin) withObject:nil afterDelay:0.0];
}


#pragma mark -
#pragma mark Notification handlers
- (void)favoriteAssetsChanged:(NSNotification *)notification {
    loadPinsData = YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.assetsList = nil;
    self.favoriteAssets = nil;
    [crumbPathView release];
    [crumbPath release];
    [annotations release];
    
    [super dealloc];
}

@end
