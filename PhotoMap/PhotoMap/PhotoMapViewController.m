/*
     File: PhotoMapViewController.m
 Abstract: Primary map view controller.
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

#import "PhotoMapViewController.h"
#import <ImageIO/ImageIO.h>

#import "PhotoAnnotation.h"
#import "PhotosViewController.h"
#import "LoadingStatus.h"

@interface PhotoMapViewController ()

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) MKMapView *allAnnotationsMapView;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@end


#pragma mark -

@implementation PhotoMapViewController

- (NSArray *)photoSetFromPath:(NSString *)path {
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    // The bulk of our work here is going to be loading the files and looking up metadata
    // Thus, we see a major speed improvement by loading multiple photos simultaneously
    //
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount: 8];
    
    NSArray *photoPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:path];
    for (NSString *photoPath in photoPaths) {
        [queue addOperationWithBlock:^{
            NSData *imageData = [NSData dataWithContentsOfFile:photoPath];
            CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
            CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(dataProvider, NULL);
            NSDictionary *imageProperties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource,0, NULL));
            
            // check if the image is geotagged
            NSDictionary *gpsInfo = imageProperties[(NSString *)kCGImagePropertyGPSDictionary];
            if (gpsInfo) {
                CLLocationCoordinate2D coord;
                coord.latitude = [gpsInfo[(NSString *)kCGImagePropertyGPSLatitude] doubleValue];
                coord.longitude = [gpsInfo[(NSString *)kCGImagePropertyGPSLongitude] doubleValue];
                if ([gpsInfo[(NSString *)kCGImagePropertyGPSLatitudeRef] isEqualToString:@"S"])
                    coord.latitude = coord.latitude * -1;
                if ([gpsInfo[(NSString *)kCGImagePropertyGPSLongitudeRef] isEqualToString:@"W"])
                    coord.longitude = coord.longitude * -1;
                
                NSString *fileName = [[photoPath lastPathComponent] stringByDeletingPathExtension];
                PhotoAnnotation *photo = [[PhotoAnnotation alloc] initWithImagePath:photoPath title:fileName coordinate:coord];
                
                @synchronized(photos) {
                    [photos addObject:photo];
                }
            }
            
            if (imageSource)
                CFRelease(imageSource);

            if (imageProperties)
                CFRelease(CFBridgingRetain(imageProperties));
            
            if (dataProvider)
                CFRelease(dataProvider);
        }];
    }
    
    [queue waitUntilAllOperationsAreFinished];

    return photos;
}

- (void)populateWorldWithAllPhotoAnnotations {
    
    // add a temporary loading view
    LoadingStatus *loadingStatus = [LoadingStatus defaultLoadingStatusWithWidth:CGRectGetWidth(self.view.frame)];
    [self.view addSubview:loadingStatus];
    
    // loading/processing photos might take a while -- do it asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *photos = [self photoSetFromPath:@"PhotoSet"];
        NSAssert(photos != nil, @"No photos found");
        
        _photos = photos;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_allAnnotationsMapView addAnnotations:_photos];
            [self updateVisibleAnnotations];
            
            [loadingStatus removeFromSuperviewWithFade];
        });
    });
}

- (id<MKAnnotation>)annotationInGrid:(MKMapRect)gridMapRect usingAnnotations:(NSSet *)annotations {
    
    // first, see if one of the annotations we were already showing is in this mapRect
    NSSet *visibleAnnotationsInBucket = [self.mapView annotationsInMapRect:gridMapRect];
    NSSet *annotationsForGridSet = [annotations objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        BOOL returnValue = ([visibleAnnotationsInBucket containsObject:obj]);
        if (returnValue)
        {
            *stop = YES;
        }
        return returnValue;
    }];
    
    if (annotationsForGridSet.count != 0) { 
        return [annotationsForGridSet anyObject];
    }
    
    // otherwise, sort the annotations based on their distance from the center of the grid square,
    // then choose the one closest to the center to show
    MKMapPoint centerMapPoint = MKMapPointMake(MKMapRectGetMidX(gridMapRect), MKMapRectGetMidY(gridMapRect));
    NSArray *sortedAnnotations = [[annotations allObjects] sortedArrayUsingComparator:^(id obj1, id obj2) {
        MKMapPoint mapPoint1 = MKMapPointForCoordinate(((id<MKAnnotation>)obj1).coordinate);
        MKMapPoint mapPoint2 = MKMapPointForCoordinate(((id<MKAnnotation>)obj2).coordinate);
        
        CLLocationDistance distance1 = MKMetersBetweenMapPoints(mapPoint1, centerMapPoint);
        CLLocationDistance distance2 = MKMetersBetweenMapPoints(mapPoint2, centerMapPoint);
        
        if (distance1 < distance2) {
            return NSOrderedAscending;
        } else if (distance1 > distance2) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];
    
    return sortedAnnotations[0];
}

- (void)updateVisibleAnnotations {
    
    // This value to controls the number of off screen annotations are displayed.
    // A bigger number means more annotations, less chance of seeing annotation views pop in but decreased performance.
    // A smaller number means fewer annotations, more chance of seeing annotation views pop in but better performance.
    static float marginFactor = 2.0;
    
    // Adjust this roughly based on the dimensions of your annotations views.
    // Bigger numbers more aggressively coalesce annotations (fewer annotations displayed but better performance).
    // Numbers too small result in overlapping annotations views and too many annotations on screen.
    static float bucketSize = 60.0;
    
    // find all the annotations in the visible area + a wide margin to avoid popping annotation views in and out while panning the map.
    MKMapRect visibleMapRect = [self.mapView visibleMapRect];
    MKMapRect adjustedVisibleMapRect = MKMapRectInset(visibleMapRect, -marginFactor * visibleMapRect.size.width, -marginFactor * visibleMapRect.size.height);
    
    // determine how wide each bucket will be, as a MKMapRect square
    CLLocationCoordinate2D leftCoordinate = [self.mapView convertPoint:CGPointZero toCoordinateFromView:self.view];
    CLLocationCoordinate2D rightCoordinate = [self.mapView convertPoint:CGPointMake(bucketSize, 0) toCoordinateFromView:self.view];
    double gridSize = MKMapPointForCoordinate(rightCoordinate).x - MKMapPointForCoordinate(leftCoordinate).x;
    MKMapRect gridMapRect = MKMapRectMake(0, 0, gridSize, gridSize);
    
    // condense annotations, with a padding of two squares, around the visibleMapRect
    double startX = floor(MKMapRectGetMinX(adjustedVisibleMapRect) / gridSize) * gridSize;
    double startY = floor(MKMapRectGetMinY(adjustedVisibleMapRect) / gridSize) * gridSize;
    double endX = floor(MKMapRectGetMaxX(adjustedVisibleMapRect) / gridSize) * gridSize;
    double endY = floor(MKMapRectGetMaxY(adjustedVisibleMapRect) / gridSize) * gridSize;

    // for each square in our grid, pick one annotation to show
    gridMapRect.origin.y = startY;
    while (MKMapRectGetMinY(gridMapRect) <= endY) {
        gridMapRect.origin.x = startX;
        
        while (MKMapRectGetMinX(gridMapRect) <= endX) {
            NSSet *allAnnotationsInBucket = [self.allAnnotationsMapView annotationsInMapRect:gridMapRect];
            NSSet *visibleAnnotationsInBucket = [self.mapView annotationsInMapRect:gridMapRect];
            
            // we only care about PhotoAnnotations
            NSMutableSet *filteredAnnotationsInBucket = [[allAnnotationsInBucket objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                return ([obj isKindOfClass:[PhotoAnnotation class]]);
            }] mutableCopy];
            
            if (filteredAnnotationsInBucket.count > 0) {
                PhotoAnnotation *annotationForGrid = (PhotoAnnotation *)[self annotationInGrid:gridMapRect usingAnnotations:filteredAnnotationsInBucket];
                
                [filteredAnnotationsInBucket removeObject:annotationForGrid];
                
                // give the annotationForGrid a reference to all the annotations it will represent
                annotationForGrid.containedAnnotations = [filteredAnnotationsInBucket allObjects];
                
                [self.mapView addAnnotation:annotationForGrid];
                
                for (PhotoAnnotation *annotation in filteredAnnotationsInBucket) {
                    // give all the other annotations a reference to the one which is representing them
                    annotation.clusterAnnotation = annotationForGrid;
                    annotation.containedAnnotations = nil;
                    
                    // remove annotations which we've decided to cluster
                    if ([visibleAnnotationsInBucket containsObject:annotation]) {
                        CLLocationCoordinate2D actualCoordinate = annotation.coordinate;
                        [UIView animateWithDuration:0.3 animations:^{
                            annotation.coordinate = annotation.clusterAnnotation.coordinate;
                        } completion:^(BOOL finished) {
                            annotation.coordinate = actualCoordinate;
                            [self.mapView removeAnnotation:annotation];
                        }];
                    }
                }
            }
            
            gridMapRect.origin.x += gridSize;
        }
        
        gridMapRect.origin.y += gridSize;
    }
}


#pragma mark - UIViewController

static const CLLocationCoordinate2D CherryLakeLocation = {38.002493, -119.9078987};

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // center to Cherry Lake, but zoomed outward
    MKCoordinateRegion newRegion;
    newRegion.center = CherryLakeLocation;
    newRegion.span.latitudeDelta = 5.0;
    newRegion.span.longitudeDelta = 5.0;
    self.mapView.region = newRegion;

    _allAnnotationsMapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    
    // now load all photos from Resources and add them as annotations to the mapview
    [self populateWorldWithAllPhotoAnnotations];
}

- (IBAction)zoomToCherryLake:(id)sender {
    
    // clear any annotations in preparation for zooming
    [self.mapView removeAnnotations:[self.mapView annotations]];
    
    // center to Cherry Lake to see the rest of the annotations
    MKCoordinateRegion newRegion;
    newRegion.center = CherryLakeLocation;
    newRegion.span.latitudeDelta = 0.05;
    newRegion.span.longitudeDelta = 0.05;
    
    [self.mapView setRegion:newRegion animated:YES];
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated {
    
    [self updateVisibleAnnotations];
}

- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
    
    for (MKAnnotationView *annotationView in views) {
        if (![annotationView.annotation isKindOfClass:[PhotoAnnotation class]]) {
            continue;
        }
        
        PhotoAnnotation *annotation = (PhotoAnnotation *)annotationView.annotation;
        
        if (annotation.clusterAnnotation != nil) {
            // animate the annotation from it's old container's coordinate, to its actual coordinate
            CLLocationCoordinate2D actualCoordinate = annotation.coordinate;
            CLLocationCoordinate2D containerCoordinate = annotation.clusterAnnotation.coordinate;
            
            // since it's displayed on the map, it is no longer contained by another annotation,
            // (We couldn't reset this in -updateVisibleAnnotations because we needed the reference to it here
            // to get the containerCoordinate)
            annotation.clusterAnnotation = nil;
            
            annotation.coordinate = containerCoordinate;
            
            [UIView animateWithDuration:0.3 animations:^{
                annotation.coordinate = actualCoordinate;
            }];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString *annotationIdentifier = @"Photo";
    
    if (aMapView != self.mapView)
        return nil;
    
    if ([annotation isKindOfClass:[PhotoAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (annotationView == nil)
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        
        annotationView.canShowCallout = YES;
        
        UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.rightCalloutAccessoryView = disclosureButton;
        
        return annotationView;
    }
    
    return nil;
}

// user tapped the call out accessory 'i' button
- (void)mapView:(MKMapView *)aMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    PhotoAnnotation *annotation = (PhotoAnnotation *)view.annotation;
    
    NSMutableArray *photosToShow = [NSMutableArray arrayWithObject:annotation];
    [photosToShow addObjectsFromArray:annotation.containedAnnotations];
    
    PhotosViewController *viewController = [[PhotosViewController alloc] init];
    viewController.edgesForExtendedLayout = UIRectEdgeNone;
    viewController.photosToShow = photosToShow;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if ([view.annotation isKindOfClass:[PhotoAnnotation class]])
    {
        PhotoAnnotation *annotation = (PhotoAnnotation *)view.annotation;
        [annotation updateSubtitleIfNeeded];
    }
}

@end
