/*
     File: ListController.m
 Abstract: Manages the List tab.
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

#import "ListController.h"

#import "NetworkManager.h"

#include <sys/socket.h>
#include <sys/dirent.h>

#include <CFNetwork/CFNetwork.h>

#pragma mark * ListController

@interface ListController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NSStreamDelegate>

// thinsg for IB

@property (nonatomic, strong, readwrite) IBOutlet UITextField *               urlText;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *   activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UITableView *               tableView;
@property (nonatomic, strong, readwrite) IBOutlet UIBarButtonItem *           listOrCancelButton;

- (IBAction)listOrCancelAction:(id)sender;

// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, strong, readwrite) NSInputStream *   networkStream;
@property (nonatomic, strong, readwrite) NSMutableData *   listData;
@property (nonatomic, strong, readwrite) NSMutableArray *  listEntries;
@property (nonatomic, copy,   readwrite) NSString *        status;

- (void)updateStatus:(NSString *)statusString;

@end

@implementation ListController

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)receiveDidStart
{
    // Clear the current image so that we get a nice visual cue if the receive fails.
    [self.listEntries removeAllObjects];
    [self.tableView reloadData];
    [self updateStatus:@"Receiving"];
    self.listOrCancelButton.title = @"Cancel";
    [self.activityIndicator startAnimating];
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.status = statusString;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)addListEntries:(NSArray *)newEntries
{
    assert(self.listEntries != nil);
    
    [self.listEntries addObjectsFromArray:newEntries];
    [self.tableView reloadData];
}

- (void)receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = @"List succeeded";
    }
    [self updateStatus:statusString];
    self.listOrCancelButton.title = @"List";
    [self.activityIndicator stopAnimating];
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isReceiving
{
    return (self.networkStream != nil);
}

- (void)startReceive
    // Starts a connection to download the current URL.
{
    BOOL                success;
    NSURL *             url;
    
    assert(self.networkStream == nil);      // don't tap receive twice in a row!

    // First get and check the URL.
    
    url = [[NetworkManager sharedInstance] smartURLForString:self.urlText.text];
    success = (url != nil);

    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        [self updateStatus:@"Invalid URL"];
    } else {

        // Create the mutable data into which we will receive the listing.

        self.listData = [NSMutableData data];
        assert(self.listData != nil);

        // Open a CFFTPStream for the URL.

        self.networkStream = CFBridgingRelease(
            CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
        );
        assert(self.networkStream != nil);
        
        self.networkStream.delegate = self;
        [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream open];
        
        // Tell the UI we're receiving.
        
        [self receiveDidStart];
    }
}

- (void)stopReceiveWithStatus:(NSString *)statusString
    // Shuts down the connection and displays the result (statusString == nil) 
    // or the error status (otherwise).
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    [self receiveDidStopWithStatus:statusString];
    self.listData = nil;
}

- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding
    // CFFTPCreateParsedResourceListing always interprets the file name as MacRoman, 
    // which is clearly bogus <rdar://problem/7420589>.  This code attempts to fix 
    // that by converting the Unicode name back to MacRoman (to get the original bytes; 
    // this works because there's a lossless round trip between MacRoman and Unicode) 
    // and then reconverting those bytes to Unicode using the encoding provided. 
{
    NSDictionary *  result;
    NSString *      name;
    NSData *        nameData;
    NSString *      newName;
    
    newName = nil;
    
    // Try to get the name, convert it back to MacRoman, and then reconvert it 
    // with the preferred encoding.
    
    name = [entry objectForKey:(id) kCFFTPResourceName];
    if (name != nil) {
        assert([name isKindOfClass:[NSString class]]);
        
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil) {
            newName = [[NSString alloc] initWithData:nameData encoding:newEncoding];
        }
    }
    
    // If the above failed, just return the entry unmodified.  If it succeeded, 
    // make a copy of the entry and replace the name with the new name that we 
    // calculated.
    
    if (newName == nil) {
        assert(NO);                 // in the debug builds, if this fails, we should investigate why
        result = (NSDictionary *) entry;
    } else {
        NSMutableDictionary *   newEntry;
        
        newEntry = [entry mutableCopy];
        assert(newEntry != nil);
        
        [newEntry setObject:newName forKey:(id) kCFFTPResourceName];
        
        result = newEntry;
    }
    
    return result;
}

- (void)parseListData
{
    NSMutableArray *    newEntries;
    NSUInteger          offset;
    
    // We accumulate the new entries into an array to avoid a) adding items to the 
    // table one-by-one, and b) repeatedly shuffling the listData buffer around.
    
    newEntries = [NSMutableArray array];
    assert(newEntries != nil);
    
    offset = 0;
    do {
        CFIndex         bytesConsumed;
        CFDictionaryRef thisEntry;
        
        thisEntry = NULL;
        
        assert(offset <= [self.listData length]);
        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], (CFIndex) ([self.listData length] - offset), &thisEntry);
        if (bytesConsumed > 0) {

            // It is possible for CFFTPCreateParsedResourceListing to return a 
            // positive number but not create a parse dictionary.  For example, 
            // if the end of the listing text contains stuff that can't be parsed, 
            // CFFTPCreateParsedResourceListing returns a positive number (to tell 
            // the caller that it has consumed the data), but doesn't create a parse 
            // dictionary (because it couldn't make sense of the data).  So, it's 
            // important that we check for NULL.

            if (thisEntry != NULL) {
                NSDictionary *  entryToAdd;
                
                // Try to interpret the name as UTF-8, which makes things work properly 
                // with many UNIX-like systems, including the Mac OS X built-in FTP 
                // server.  If you have some idea what type of text your target system 
                // is going to return, you could tweak this encoding.  For example, 
                // if you know that the target system is running Windows, then 
                // NSWindowsCP1252StringEncoding would be a good choice here.
                // 
                // Alternatively you could let the user choose the encoding up 
                // front, or reencode the listing after they've seen it and decided 
                // it's wrong.
                //
                // Ain't FTP a wonderful protocol!

                entryToAdd = [self entryByReencodingNameInEntry:(__bridge NSDictionary *) thisEntry encoding:NSUTF8StringEncoding];
                
                [newEntries addObject:entryToAdd];
            }
            
            // We consume the bytes regardless of whether we get an entry.
            
            offset += (NSUInteger) bytesConsumed;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry.  Wait for more data 
            // to arrive.
            break;
        } else if (bytesConsumed < 0) {
            // We totally failed to parse the listing.  Fail.
            [self stopReceiveWithStatus:@"Listing parse failed"];
            break;
        }
    } while (YES);

    if ([newEntries count] != 0) {
        [self addListEntries:newEntries];
    }
    if (offset != 0) {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // An NSStream delegate callback that's called when events happen on our 
    // network stream.
{
    #pragma unused(aStream)
    assert(aStream == self.networkStream);

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];

            [self updateStatus:@"Receiving"];
            
            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead < 0) {
                [self stopReceiveWithStatus:@"Network read error"];
            } else if (bytesRead == 0) {
                [self stopReceiveWithStatus:nil];
            } else {
                assert(self.listData != nil);
                
                // Append the data to our listing buffer.
                
                [self.listData appendBytes:buffer length:(NSUInteger) bytesRead];
                
                // Check the listing buffer for any complete entries and update 
                // the UI if we find any.
                
                [self parseListData];
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopReceiveWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

#pragma mark * UI actions

- (IBAction)listOrCancelAction:(id)sender
{
    #pragma unused(sender)
    if (self.isReceiving) {
        [self stopReceiveWithStatus:@"Cancelled"];
    } else {
        [self startReceive];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
    // A delegate method called by the URL text field when the editing is complete. 
    // We save the current value of the field in our settings.
{
    #pragma unused(textField)
    NSString *  newValue;
    NSString *  oldValue;
    
    assert(textField == self.urlText);

    newValue = self.urlText.text;
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ListURLText"];

    // Save the URL text if it's changed.
    
    assert(newValue != nil);        // what is UITextField thinking!?!
    assert(oldValue != nil);        // because we registered a default
    
    if ( ! [newValue isEqual:oldValue] ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"ListURLText"];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
    // A delegate method called by the URL text field when the user taps the Return 
    // key.  We just dismiss the keyboard.
{
    #pragma unused(textField)
    assert(textField == self.urlText);
    [self.urlText resignFirstResponder];
    return NO;
}

#pragma mark * Table view data source and delegate

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);
    return (NSInteger) ([self.listEntries count] + 1);
}

- (NSString *)stringForNumber:(double)num asUnits:(NSString *)units
{
    NSString *  result;
    double      fractional;
    double      integral;
    
    fractional = modf(num, &integral);
    if ( (fractional < 0.1) || (fractional > 0.9) ) {
        result = [NSString stringWithFormat:@"%.0f %@", round(num), units];
    } else {
        result = [NSString stringWithFormat:@"%.1f %@", num, units];
    }
    return result;
}

- (NSString *)stringForFileSize:(unsigned long long)fileSizeExact
{
    double  fileSize;
    NSString *  result;
    
    fileSize = (double) fileSizeExact;
    if (fileSizeExact == 1) {
        result = @"1 byte";
    } else if (fileSizeExact < 1024) {
        result = [NSString stringWithFormat:@"%llu bytes", fileSizeExact];
    } else if (fileSize < (1024.0 * 1024.0 * 0.1)) {
        result = [self stringForNumber:fileSize / 1024.0 asUnits:@"KB"];
    } else if (fileSize < (1024.0 * 1024.0 * 1024.0 * 0.1)) {
        result = [self stringForNumber:fileSize / (1024.0 * 1024.0) asUnits:@"MB"];
    } else {
        result = [self stringForNumber:fileSize / (1024.0 * 1024.0 * 1024.0) asUnits:@"MB"];
    }
    return result;
}

static NSDateFormatter *    sDateFormatter;

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *   cell;
    NSDictionary *      listEntry;
    NSNumber *          typeNum;
    int                 type;
    NSNumber *          sizeNum;
    NSString *          sizeStr;
    NSNumber *          modeNum;
    char                modeCStr[12];
    NSDate *            date;
    NSString *          dateStr;
    
    #pragma unused(tv)
    assert(tv == self.tableView);
    assert(indexPath != nil);
    assert(indexPath.section == 0);
    assert(indexPath.row >= 0);
    assert( (NSUInteger) indexPath.row < ([self.listEntries count] + 1));
    
    if (indexPath.row == 0) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StatusCell"];
        }
        assert(cell != nil);
        
        cell.textLabel.text = self.status;
        cell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ListCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ListCell"];
        }
        assert(cell != nil);

        listEntry = [self.listEntries objectAtIndex:((NSUInteger) indexPath.row) - 1];
        assert([listEntry isKindOfClass:[NSDictionary class]]);
        
        // The first line of the cell is the item name.
        
        cell.textLabel.text = [listEntry objectForKey:(id) kCFFTPResourceName];
        
        // Use the second line of the cell to show various attributes.
        
        typeNum = [listEntry objectForKey:(id) kCFFTPResourceType];
        if (typeNum != nil) {
            assert([typeNum isKindOfClass:[NSNumber class]]);
            type = [typeNum intValue];
        } else {
            type = 0;
        }
        
        modeNum = [listEntry objectForKey:(id) kCFFTPResourceMode];
        if (modeNum != nil) {
            assert([modeNum isKindOfClass:[NSNumber class]]);
            
            strmode([modeNum intValue] + DTTOIF(type), modeCStr);
        } else {
            strlcat(modeCStr, "???????????", sizeof(modeCStr));
        }
        
        sizeNum = [listEntry objectForKey:(id) kCFFTPResourceSize];
        if (sizeNum != nil) {
            if (type == DT_REG) {
                assert([sizeNum isKindOfClass:[NSNumber class]]);
                sizeStr = [self stringForFileSize:[sizeNum unsignedLongLongValue]];
            } else {
                sizeStr = @"-";
            }
        } else {
            sizeStr = @"?";
        }
        
        date = [listEntry objectForKey:(id) kCFFTPResourceModDate];
        if (date != nil) {
            if (sDateFormatter == nil) {
                sDateFormatter = [[NSDateFormatter alloc] init];
                assert(sDateFormatter != nil);
                
                sDateFormatter.dateStyle = NSDateFormatterShortStyle;
                sDateFormatter.timeStyle = NSDateFormatterShortStyle;
            }
            dateStr = [sDateFormatter stringFromDate:date];
        } else {
            dateStr = @"";
        }
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%s %@ %@", modeCStr, sizeStr, dateStr];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark * View controller boilerplate

- (void)viewDidLoad
{    
    [super viewDidLoad];
    assert(self.urlText != nil);
    assert(self.activityIndicator != nil);
    assert(self.tableView != nil);
    assert(self.listOrCancelButton != nil);
    
    self.listOrCancelButton.possibleTitles = [NSSet setWithObjects:@"List", @"Cancel", nil];

    if (self.listEntries == nil) {
        self.listEntries = [NSMutableArray array];
        assert(self.listEntries != nil);
    }

    self.urlText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"ListURLText"];
    
    self.activityIndicator.hidden = YES;
    [self updateStatus:@"Tap List to start listing"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.urlText = nil;
    self.activityIndicator = nil;
    self.tableView = nil;
    self.listOrCancelButton = nil;
}

- (void)dealloc
{
    [self stopReceiveWithStatus:@"Stopped"];
}

@end
