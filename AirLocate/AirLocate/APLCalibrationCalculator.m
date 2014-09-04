/*
     File: APLCalibrationCalculator.m
 Abstract: Illustrates how to calibrate the measured power of a beacon.
 
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

#import "APLCalibrationCalculator.h"
#import "APLDefaults.h"

@import CoreLocation;


static const NSTimeInterval ALCalibrationDwell = 20.0f;

NSString *AppErrorDomain = @"com.example.apple-samplecode.AirLocate";



@interface APLCalibrationCalculator()

@property CLLocationManager *locationManager;
@property CLBeaconRegion *region;
@property (getter=isCalibrating) BOOL calibrating;
@property NSMutableArray *rangedBeacons;
@property NSTimer *timer;

@property (strong) APLCalibrationProgressHandler progressHandler;
@property (strong) APLCalibrationCompletionHandler completionHandler;

@property float percentComplete;

@end



@implementation APLCalibrationCalculator


- (id)initWithRegion:(CLBeaconRegion *)region completionHandler:(APLCalibrationCompletionHandler)handler
{
    self = [super init];
    if(self)
    {
        // This location manager will be used to collect RSSI samples from the targeted beacon.
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _region = region;
        _completionHandler = [handler copy];
        _rangedBeacons = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    @synchronized(self)
    {
        [_rangedBeacons addObject:beacons];
        
        if(_progressHandler)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Bump the progress callback back to the UI thread as we'll be updating the UI.
                _percentComplete += 1.0f / ALCalibrationDwell;
                _progressHandler(_percentComplete);
            });
        }
    }
}

- (void)performCalibrationWithProgressHandler:(APLCalibrationProgressHandler)handler
{
    @synchronized(self)
    {
        if(!self.calibrating)
        {
            // Calibration consists of collecting RSSI samples for 20 seconds.
            // Once we have all the samples we will average the mid-80th percentile in timerElapsed:.
            self.calibrating = YES;
            [self.rangedBeacons removeAllObjects];
            
            self.percentComplete = 0.0f;
            self.progressHandler = [handler copy];
            
            [self.locationManager startRangingBeaconsInRegion:self.region];
            
            self.timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:ALCalibrationDwell] interval:0 target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.timer  forMode:NSDefaultRunLoopMode];
        }
        else
        {
            // Send back an error if calibration is already in progress.
            NSString *localizedErrorString = NSLocalizedString(@"Calibration is already in progress", @"Error string");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedErrorString };
            NSError *error = [NSError errorWithDomain:AppErrorDomain code:4 userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                _completionHandler(0, error);
            });
        }
    }
}

- (void)cancelCalibration
{
    @synchronized(self)
    {
        // Fire the timer early if calibration is being cancelled.
        // timerElapsed: will handle reporting the cancellation.
        if(self.calibrating)
        {
            self.calibrating = NO;
            [self.timer fire];
        }
    }
}

- (void)timerElapsed:(id)sender
{
    @synchronized(self)
    {
        // We can stop ranging at this point as we've either been cancelled or
        // collected all of the RSSI samples we need.
        [_locationManager stopRangingBeaconsInRegion:_region];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized(self) {                
                __block NSError *error = nil;
                NSMutableArray *allBeacons = [[NSMutableArray alloc] init];
                NSInteger measuredPower = 0;
                if(!self.calibrating)
                {
                    NSString *localizedErrorString = NSLocalizedString(@"Calibration was cancelled", @"Error string");
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedErrorString };
                    error = [NSError errorWithDomain:AppErrorDomain code:2 userInfo:userInfo];
                }
                else
                {
                    [self.rangedBeacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSArray *beacons = (NSArray *)obj;
                        if(beacons.count > 1)
                        {
                            NSString *localizedErrorString = NSLocalizedString(@"More than one beacon of the specified type was found", @"Error string");
                            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedErrorString };
                            error = [NSError errorWithDomain:AppErrorDomain code:1 userInfo:userInfo];
                            *stop = YES;
                        }
                        else
                        {
                            [allBeacons addObjectsFromArray:beacons];
                        }
                    }];
                    
                    if(allBeacons.count <= 0)
                    {
                        NSString *localizedErrorString = NSLocalizedString(@"No beacon of the specified type was found", @"Error string");
                        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedErrorString };
                        error = [NSError errorWithDomain:AppErrorDomain code:3 userInfo:userInfo];
                    }
                    else
                    {
                        // Measured power is an average of the mid-80th percentile of RSSI samples.
                        NSUInteger outlierPadding = allBeacons.count * 0.1f;                    
                        [allBeacons sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"rssi" ascending:YES]]];
                        NSArray *sample = [allBeacons subarrayWithRange:NSMakeRange(outlierPadding, allBeacons.count - (outlierPadding * 2))];
                        measuredPower = [[sample valueForKeyPath:@"@avg.rssi"] integerValue];
                    }
                }
                
                // Bump the completion callback to the UI thread as we'll be updating the UI.
                dispatch_async(dispatch_get_main_queue(), ^{
                    _completionHandler(measuredPower, error);
                });
                
                self.calibrating = NO;
                [self.rangedBeacons removeAllObjects];
                
                self.progressHandler = nil;
            }
        });
    }
}

@end
