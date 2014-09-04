/*
     File: APLViewController.m
 Abstract: View controller for displaying the earthquake list; initiates the download of the XML data and parses the Earthquake objects at view load time.
  Version: 3.5
 
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

#import "APLViewController.h"
#import "APLParseOperation.h"

#import "APLEarthquake.h"
#import "APLEarthquakeTableViewCell.h"

// this framework is imported so we can use the kCFURLErrorNotConnectedToInternet error code
#import <CFNetwork/CFNetwork.h>
#import <MapKit/MapKit.h>

@interface APLViewController ()

@property (nonatomic) NSMutableArray *earthquakeList;

// queue that manages our NSOperation for parsing earthquake data
@property (nonatomic) NSOperationQueue *parseQueue;

@end


#pragma mark -

@implementation APLViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.earthquakeList = [NSMutableArray array];

    /*
     Use NSURLConnection to asynchronously download the data. This means the main thread will not be blocked - the application will remain responsive to the user.

     IMPORTANT! The main thread of the application should never be blocked!
     Also, avoid synchronous network access on any thread.
     */
    static NSString *feedURLString = @"http://earthquake.usgs.gov/eqcenter/catalogs/7day-M2.5.xml";
    NSURLRequest *earthquakeURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];

    // send the async request (note that the completion block will be called on the main thread)
    //
    // note: using the block-based "sendAsynchronousRequest" is preferred, and useful for
    // small data transfers that are likely to succeed. If you doing large data transfers,
    // consider using the NSURLConnectionDelegate-based APIs.
    //
    [NSURLConnection sendAsynchronousRequest:earthquakeURLRequest
                                       // the NSOperationQueue upon which the handler block will be dispatched:
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

         // back on the main thread, check for errors, if no errors start the parsing
         //
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         
         // here we check for any returned NSError from the server, "and" we also check for any http response errors
         if (error != nil) {
             [self handleError:error];
         }
         else {
             // check for any response errors
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             if ((([httpResponse statusCode]/100) == 2) && [[response MIMEType] isEqual:@"application/atom+xml"]) {
                 
                 // Update the UI and start parsing the data,
                 // Spawn an NSOperation to parse the earthquake data so that the UI is not
                 // blocked while the application parses the XML data.
                 //
                 APLParseOperation *parseOperation = [[APLParseOperation alloc] initWithData:data];
                 [self.parseQueue addOperation:parseOperation];
             }
             else {
                NSString *errorString =
                    NSLocalizedString(@"HTTP Error", @"Error message displayed when receving a connection error.");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [self handleError:reportError];
             }
         }
     }];
    
    // Start the status bar network activity indicator.
    // We'll turn it off when the connection finishes or experiences an error.
    //
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    self.parseQueue = [NSOperationQueue new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addEarthquakes:)
                                                 name:kAddEarthquakesNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(earthquakesError:)
                                                 name:kEarthquakesErrorNotificationName object:nil];
    
    // if the locale changes behind our back, we need to be notified so we can update the date
    // format in the table view cells
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localeChanged:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAddEarthquakesNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kEarthquakesErrorNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
}

/**
 Handle errors in the download by showing an alert to the user. This is a very simple way of handling the error, partly because this application does not have any offline functionality for the user. Most real applications should handle the error in a less obtrusive way and provide offline functionality to the user.
 */
- (void)handleError:(NSError *)error {

    NSString *errorMessage = [error localizedDescription];
    NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
    NSString *okTitle = NSLocalizedString(@"OK ", @"OK Title for alert displayed when download or parse error occurs.");

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:errorMessage delegate:nil cancelButtonTitle:okTitle otherButtonTitles:nil];
    [alertView show];
}

/**
 Our NSNotification callback from the running NSOperation to add the earthquakes
 */
- (void)addEarthquakes:(NSNotification *)notif {

    assert([NSThread isMainThread]);
    [self addEarthquakesToList:[[notif userInfo] valueForKey:kEarthquakeResultsKey]];
}

/**
 Our NSNotification callback from the running NSOperation when a parsing error has occurred
 */
- (void)earthquakesError:(NSNotification *)notif {

    assert([NSThread isMainThread]);
    [self handleError:[[notif userInfo] valueForKey:kEarthquakesMessageErrorKey]];
}

/**
 The NSOperation "ParseOperation" calls addEarthquakes: via NSNotification, on the main thread which in turn calls this method, with batches of parsed objects. The batch size is set via the kSizeOfEarthquakeBatch constant.
 */
- (void)addEarthquakesToList:(NSArray *)earthquakes {

    NSInteger startingRow = [self.earthquakeList count];
    NSInteger earthquakeCount = [earthquakes count];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:earthquakeCount];

    for (NSInteger row = startingRow; row < (startingRow + earthquakeCount); row++) {

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [indexPaths addObject:indexPath];
    }

    [self.earthquakeList addObjectsFromArray:earthquakes];

    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - UITableViewDelegate

// The number of rows is equal to the number of earthquakes in the array.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.earthquakeList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *kEarthquakeCellID = @"EarthquakeCellID";
  	APLEarthquakeTableViewCell *cell = (APLEarthquakeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kEarthquakeCellID];

    // Get the specific earthquake for this row.
	APLEarthquake *earthquake = (self.earthquakeList)[indexPath.row];

    [cell configureWithEarthquake:earthquake];
	return cell;
}

/**
 * When the user taps a row in the table, display the USGS web page that displays details of the earthquake they selected.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *buttonTitle = NSLocalizedString(@"Cancel", @"Cancel");
    NSString *buttonTitle1 = NSLocalizedString(@"Show USGS Site in Safari", @"Show USGS Site in Safari");
    NSString *buttonTitle2 = NSLocalizedString(@"Show Location in Maps", @"Show Location in Maps");

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:buttonTitle destructiveButtonTitle:nil
                                              otherButtonTitles:buttonTitle1, buttonTitle2, nil];
    [sheet showInView:self.view];
}


#pragma mark -

/**
 * Called when the user selects an option in the sheet. The sheet will automatically be dismissed.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    APLEarthquake *earthquake = (APLEarthquake *)(self.earthquakeList)[selectedIndexPath.row];

    switch (buttonIndex) {
        case 0: {
            // open the earthquake info in Safari
            //
            [[UIApplication sharedApplication] openURL:earthquake.USGSWebLink];
        }
            break;
        case 1: {
            // open the earthquake info in Maps

            // create a map region pointing to the earthquake location
            CLLocationCoordinate2D location = (CLLocationCoordinate2D) { earthquake.latitude, earthquake.longitude };
            NSValue *locationValue = [NSValue valueWithMKCoordinate:location];

            MKCoordinateSpan span = (MKCoordinateSpan) { 2.0, 2.0 };
            NSValue *spanValue = [NSValue valueWithMKCoordinateSpan:span];

            NSDictionary *launchOptions = @{ MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),
                                            MKLaunchOptionsMapCenterKey : locationValue,
                                            MKLaunchOptionsMapSpanKey : spanValue,
                                            MKLaunchOptionsShowsTrafficKey : @(NO),
                                             MKLaunchOptionsDirectionsModeDriving : @(NO) };

            // make sure the map item has a pin placed on it with the title as the earthquake location
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:location
                                                           addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:earthquake.location];
            [mapItem openInMapsWithLaunchOptions:launchOptions];
                        
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}


#pragma mark - Locale changes

- (void)localeChanged:(NSNotification *)notif
{
    // the user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    [self.tableView reloadData];
}

@end

