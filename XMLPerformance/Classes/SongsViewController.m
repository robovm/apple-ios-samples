/*
     File: SongsViewController.m
 Abstract: Creates and runs an instance of the parser type chosen by the user, and displays the parsed songs in a table. Selecting a row in the table navigates to a detail view for that song.
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

#import "SongsViewController.h"
#import "DetailController.h"
#import "Song.h"
#import "LibXMLParser.h"
#import "CocoaXMLParser.h"

@interface SongsViewController ()

@property (nonatomic, strong) NSMutableArray *songs;
@property (nonatomic, strong) DetailController *detailController;
@property (nonatomic, strong) iTunesRSSParser *parser;

// When the parsing is finished, the user can return to the ParserChoiceViewController by
// touching the button associated with this action.
//
- (IBAction)returnToParserChoices;

@end

#pragma mark -

@implementation SongsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _detailController = [[DetailController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UIBarButtonItem *doneItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(returnToParserChoices)];
    self.navigationItem.rightBarButtonItem = doneItem;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    NSIndexPath *selectedRowIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedRowIndexPath != nil) {
        [self.tableView deselectRowAtIndexPath:selectedRowIndexPath animated:NO];
    }
}

// This method will be called repeatedly - once each time the user choses to parse.
- (void)parseWithParserType:(XMLParserType)parserType {
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    // Reset the title
    self.title = NSLocalizedString(@"Getting Top Songs...", @"Waiting for first results label");
    // Allocate the array for song storage, or empty the results of previous parses
    if (self.songs == nil) {
        self.songs = [NSMutableArray array];
    } else {
        [self.songs removeAllObjects];
        [self.tableView reloadData];
    }
    // Determine the Class for the parser
    Class parserClass = nil;
    switch (parserType) {
        case XMLParserTypeLibXMLParser: {
            parserClass = [LibXMLParser class];
        } break;
        case XMLParserTypeNSXMLParser: {
            parserClass = [CocoaXMLParser class];
        } break;
        default: {
            NSAssert1(NO, @"Unknown parser type %d", parserType);
        } break;
    }
    // Create the parser, set its delegate, and start it.
    self.parser = [[parserClass alloc] init];      
    self.parser.delegate = self;
    [self.parser start];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.songs count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCellIdentifier = @"MyCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [[self.songs objectAtIndex:indexPath.row] title];
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.detailController.song = [self.songs objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:self.detailController animated:YES];
}

- (IBAction)returnToParserChoices {
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - iTunesRSSParserDelegate

- (void)parserDidEndParsingData:(iTunesRSSParser *)parser {
    
    self.title = [NSString stringWithFormat:NSLocalizedString(@"Top %d Songs", @"Top Songs format"), [self.songs count]];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.parser = nil;
}

- (void)parser:(iTunesRSSParser *)parser didParseSongs:(NSArray *)parsedSongs {
    
    [self.songs addObjectsFromArray:parsedSongs];
    
    // Three scroll view properties are checked to keep the user interface smooth during parse. When new objects are delivered by the parser, the table view is reloaded to display them. If the table is reloaded while the user is scrolling, this can result in eratic behavior. dragging, tracking, and decelerating can be checked for this purpose. When the parser finishes, reloadData will be called in parserDidEndParsingData:, guaranteeing that all data will ultimately be displayed even if reloadData is not called in this method because of user interaction.
    
    if (!self.tableView.dragging && !self.tableView.tracking && !self.tableView.decelerating) {
        self.title = [NSString stringWithFormat:NSLocalizedString(@"Top %d Songs", @"Top Songs format"), [self.songs count]];
        [self.tableView reloadData];
    }
}

- (void)parser:(iTunesRSSParser *)parser didFailWithError:(NSError *)error {
    // handle errors as appropriate to your application...
}

@end
