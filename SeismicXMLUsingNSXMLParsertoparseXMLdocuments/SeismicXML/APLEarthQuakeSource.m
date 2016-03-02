/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Data source object responsible for initiating the download of the XML data and parses the Earthquake objects at view load time.
 */

#import "APLEarthQuakeSource.h"
#import "APLParseOperation.h"

static NSString *feedURLString = @"http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.quakeml";

@interface APLEarthQuakeSource ()

@property (nonatomic, strong) NSMutableArray *earthquakes;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@property (assign) id addEarthQuakesObserver;
@property (assign) id earthQuakesErrorObserver;

// queue that manages our NSOperation for parsing earthquake data
@property (nonatomic, strong) NSOperationQueue *parseQueue;

@end


#pragma mark -

@implementation APLEarthQuakeSource

- (instancetype)init {
    
    self = [super init];
    if (self != nil) {
        _earthquakes = [NSMutableArray array];
        
        // Our NSNotification callback from the running NSOperation to add the earthquakes
        _addEarthQuakesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:APLParseOperation.AddEarthQuakesNotificationName
                                                                                    object:nil
                                                                                     queue:nil
                                                                                usingBlock:^(NSNotification *notification) {
            /**
             The NSOperation "ParseOperation" calls this observer with batches of parsed objects.
             The batch size is set via the kSizeOfEarthquakeBatch constant. Use KVO to notify our client.
             */
            NSArray *incomingEarthquakes = [notification.userInfo valueForKey:APLParseOperation.EarthquakeResultsKey];
            
            [self willChangeValueForKey:@"earthquakes"];
            [self.earthquakes addObjectsFromArray:incomingEarthquakes];
            [self didChangeValueForKey:@"earthquakes"];
        }];
        
        // Our NSNotification callback from the running NSOperation when a parsing error has occurred
        _earthQuakesErrorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:APLParseOperation.EarthquakesErrorNotificationName
                                                                                      object:nil
                                                                                       queue:nil
                                                                                  usingBlock:^(NSNotification *notification) {
            // The NSOperation "ParseOperation" calls this observer with an error, use KVO to notify our client
            [self willChangeValueForKey:@"error"];
            self.error = [notification.userInfo valueForKey:APLParseOperation.EarthquakesMessageErrorKey];
            [self didChangeValueForKey:@"error"];
        }];
        
        _parseQueue = [NSOperationQueue new];
    }
    
    return self;
}

- (void)startEarthQuakeLookup {
    /*
     Use NSURLSession to asynchronously download the data.
     This means the main thread will not be blocked - the application will remain responsive to the user.
     
     IMPORTANT! The main thread of the application should never be blocked!
     Also, avoid synchronous network access on any thread.
     */
    
    NSURLRequest *earthquakeURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
    
    // create an session data task to obtain and download the app icon
    _sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:earthquakeURLRequest
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                       
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{

            // back on the main thread, check for errors, if no errors start the parsing
            //
            if (error != nil && response == nil) {
                if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
                   
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    NSAssert(NO, @"NSURLErrorAppTransportSecurityRequiresSecureConnection");
                }
                else {
                    // use KVO to notify our client of this error
                    [self willChangeValueForKey:@"error"];
                    self.error = error;
                    [self didChangeValueForKey:@"error"];
                }
            }

            // here we check for any returned NSError from the server,
            // "and" we also check for any http response errors check for any response errors
            if (response != nil) {
               
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (((httpResponse.statusCode/100) == 2) && [response.MIMEType isEqual:@"application/xml"]) {
                   
                    /* Update the UI and start parsing the data,
                        Spawn an NSOperation to parse the earthquake data so that the UI is not
                        blocked while the application parses the XML data.
                     */
                    APLParseOperation *parseOperation = [[APLParseOperation alloc] initWithData:data];
                    [self.parseQueue addOperation:parseOperation];
                }
                else {
                    NSString *errorString =
                        NSLocalizedString(@"HTTP Error", @"Error message displayed when receiving an error from the server.");
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};

                    // use KVO to notify our client of this error
                    [self willChangeValueForKey:@"error"];
                    self.error = [NSError errorWithDomain:@"HTTP"
                                                    code:httpResponse.statusCode
                                                userInfo:userInfo];
                    [self didChangeValueForKey:@"error"];
                }
            }
        }];
    }];
    
    [self.sessionTask resume];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.addEarthQuakesObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.earthQuakesErrorObserver];
}

@end