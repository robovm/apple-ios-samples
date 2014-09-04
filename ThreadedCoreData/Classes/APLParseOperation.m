/*
     File: APLParseOperation.m
 Abstract: The NSOperation class used to perform the XML parsing of earthquake data.
  Version: 1.3
 
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

#import "APLParseOperation.h"
#import "APLAppDelegate.h"
#import "Earthquake.h"

// NSNotification name for reporting errors
NSString *kEarthquakesErrorNotificationName = @"EarthquakeErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kEarthquakesMessageErrorKey = @"EarthquakesMsgErrorKey";


@interface APLParseOperation () <NSXMLParserDelegate>

@property (nonatomic, strong) Earthquake *currentEarthquakeObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableString *currentParsedCharacterData;
@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) NSPersistentStoreCoordinator *sharedPSC;

@end


#pragma mark -

@implementation APLParseOperation
{
    NSDateFormatter *_dateFormatter;

    BOOL _accumulatingParsedCharacterData;
    BOOL _didAbortParsing;
    NSUInteger _parsedEarthquakesCounter;
}

- (id)initWithData:(NSData *)parseData sharedPSC:(NSPersistentStoreCoordinator *)psc {
    
    self = [super init];
    if (self) {
        _earthquakeData = [parseData copy];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        
        self.currentParseBatch = [[NSMutableArray alloc] init];
        self.currentParsedCharacterData = [[NSMutableString alloc] init];
        
        // keep the shared psc for creating context later in main
        self.sharedPSC = psc;
    }
    return self;
}

- (void)addEarthquakesToList:(NSArray *)earthquakes {
    
    // a batch of earthquakes are ready to be added
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *ent = [NSEntityDescription entityForName:@"Earthquake" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = ent;
    
    // narrow the fetch to these two properties
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:@"location", @"date", nil];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    // before adding the earthquake, first check if there's a duplicate in the backing store
    NSError *error = nil;
    Earthquake *earthquake = nil;
    for (earthquake in earthquakes) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"location = %@ AND date = %@", earthquake.location, earthquake.date];
        
        NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedItems.count == 0) {
            // we found no duplicate earthquakes, so insert this new one
            [self.managedObjectContext insertObject:earthquake];
        }
    }
    
    // keep our number of earthquakes to a manageable level, remove earthquakes older than 2 weeks
    // compute the date two weeks ago from today, used later when dumping older earthquakes
    //
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:-14];  // 14 days back from today
    NSDate *twoWeeksAgo = [gregorian dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];
    
    // use the same fetchrequest instance but switch back to NSManagedObjectResultType
    fetchRequest.resultType = NSManagedObjectResultType;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", twoWeeksAgo];
    NSArray *olderEarthquakes = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (earthquake in olderEarthquakes) {
        [self.managedObjectContext deleteObject:earthquake];
    }
    
    if ([self.managedObjectContext hasChanges]) {
        
        if (![self.managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful
            // during development. If it is not possible to recover from the error, display an alert
            // panel that instructs the user to quit the application by pressing the Home button.
            //
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    // note since APLViewController is observing save changes, so it will receive the new earthquakes on its own
}

// The main function for this NSOperation, to start the parsing.
- (void)main {
    
    // Creating context in main function here make sure the context is tied to current thread.
    // init: use thread confine model to make things simpler.
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    self.managedObjectContext.persistentStoreCoordinator = self.sharedPSC;
    
    /*
     It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable because it gives less control over the network, particularly in responding to connection errors.
     */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.earthquakeData];
    [parser setDelegate:self];
    [parser parse];
    
    /*
     Depending on the total number of earthquakes parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
     */
    if ([self.currentParseBatch count] > 0) {
        [self addEarthquakesToList:self.currentParseBatch];
    }
}


#pragma mark - Parser constants

/*
 Limit the number of parsed earthquakes to 50 (a given day may have more than 50 earthquakes around the world, so we only take the first 50).
 */
static const NSUInteger kMaximumNumberOfEarthquakesToParse = 50;

/*
 When an Earthquake object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every Earthquake object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. In your application, the optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfEarthquakeBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kEntryElementName = @"entry";
static NSString * const kLinkElementName = @"link";
static NSString * const kTitleElementName = @"title";
static NSString * const kUpdatedElementName = @"updated";
static NSString * const kGeoRSSPointElementName = @"georss:point";


#pragma mark - NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    /*
     If the number of parsed earthquakes is greater than kMaximumNumberOfEarthquakesToParse, abort the parse.
     */
    if (_parsedEarthquakesCounter >= kMaximumNumberOfEarthquakesToParse) {
        /*
         Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
         */
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kEntryElementName]) {
        NSEntityDescription *ent = [NSEntityDescription entityForName:@"Earthquake" inManagedObjectContext:self.managedObjectContext];
        // create an earthquake managed object, but don't insert it in our moc yet
        Earthquake *earthquake = [[Earthquake alloc] initWithEntity:ent insertIntoManagedObjectContext:nil];
        self.currentEarthquakeObject = earthquake;
        
    } else if ([elementName isEqualToString:kLinkElementName]) {
        NSString *relAttribute = [attributeDict valueForKey:@"rel"];
        if ([relAttribute isEqualToString:@"alternate"]) {
            NSString *USGSWebLink = [attributeDict valueForKey:@"href"];
            self.currentEarthquakeObject.USGSWebLink = USGSWebLink;
        }
    } else if ([elementName isEqualToString:kTitleElementName] ||
               [elementName isEqualToString:kUpdatedElementName] ||
               [elementName isEqualToString:kGeoRSSPointElementName]) {
        // For the 'title', 'updated', or 'georss:point' element begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
        _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        [self.currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:kEntryElementName]) {
    
        [self.currentParseBatch addObject:self.currentEarthquakeObject];
        _parsedEarthquakesCounter++;
        if ([self.currentParseBatch count] >= kSizeOfEarthquakeBatch) {
            [self addEarthquakesToList:self.currentParseBatch];
            self.currentParseBatch = [NSMutableArray array];
        }
    } else if ([elementName isEqualToString:kTitleElementName]) {
        /*
         The title element contains the magnitude and location in the following format:
         <title>M 3.6, Virgin Islands region<title/>
         Extract the magnitude and the location using a scanner:
        */
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        if ([scanner scanString:@"M " intoString:NULL]) {
            float magnitude;
            if ([scanner scanFloat:&magnitude]) {
                self.currentEarthquakeObject.magnitude = [NSNumber numberWithFloat:magnitude];
                // Scan past the ", " before the title.
                if ([scanner scanString:@", " intoString:NULL]) {
                    NSString *location = nil;
                    // Scan the remainer of the string.
                    if ([scanner scanUpToCharactersFromSet:
                         [NSCharacterSet illegalCharacterSet] intoString:&location]) {
                        self.currentEarthquakeObject.location = location;
                    }
                }
            }
        }
    } else if ([elementName isEqualToString:kUpdatedElementName]) {
        if (self.currentEarthquakeObject != nil) {
            self.currentEarthquakeObject.date = [_dateFormatter dateFromString:self.currentParsedCharacterData];
        }
        else {
            // kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
            // so don't process it here.
        }
    } else if ([elementName isEqualToString:kGeoRSSPointElementName]) {
        // The georss:point element contains the latitude and longitude of the earthquake epicenter.
        // 18.6477 -66.7452
        //
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double latitude, longitude;
        if ([scanner scanDouble:&latitude]) {
            if ([scanner scanDouble:&longitude]) {
                self.currentEarthquakeObject.latitude = [NSNumber numberWithDouble:latitude];
                self.currentEarthquakeObject.longitude = [NSNumber numberWithDouble:longitude];
            }
        }
    }
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;
}

/**
 This method is called by the parser when it find parsed character data ("PCDATA") in an element. The parser is not guaranteed to deliver all of the parsed character data for an element in a single invocation, so it is necessary to accumulate character data until the end of the element is reached.
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

/** 
 An error occurred while parsing the earthquake data: post the error as an NSNotification to our app delegate.
 */ 
- (void)handleEarthquakesError:(NSError *)parseError {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kEarthquakesErrorNotificationName object:self userInfo:@{kEarthquakesMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the earthquake data, pass the error to the main thread for handling.
 (Note: don't report an error if we aborted the parse due to a max limit of earthquakes.)
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
     
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !_didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handleEarthquakesError:) withObject:parseError waitUntilDone:NO];
    }
}

@end
