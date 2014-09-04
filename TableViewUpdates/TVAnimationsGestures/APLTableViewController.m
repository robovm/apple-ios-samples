/*
     File: APLTableViewController.m
 Abstract: Table view controller to manage display of quotations from various plays.
 The controller supports opening and closing of sections. To do this it maintains information about each section using an array of SectionInfo objects.
 
  Version: 3.2
 
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

#import "APLTableViewController.h"
#import "APLQuoteCell.h"
#import "APLSectionInfo.h"
#import "APLSectionHeaderView.h"

#import "APLPlay.h"
#import "APLQuotation.h"

@interface APLEmailMenuItem : UIMenuItem
@property (nonatomic) NSIndexPath *indexPath;
@end

@implementation APLEmailMenuItem
@end


#pragma mark - APLTableViewController

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";

@interface APLTableViewController ()

@property (nonatomic) NSMutableArray *sectionInfoArray;
@property (nonatomic) NSIndexPath *pinchedIndexPath;
@property (nonatomic) NSInteger openSectionIndex;
@property (nonatomic) CGFloat initialPinchHeight;

@property (nonatomic) IBOutlet APLSectionHeaderView *sectionHeaderView;

// use the uniformRowHeight property if the pinch gesture should change all row heights simultaneously
@property (nonatomic) NSInteger uniformRowHeight;

@end


#pragma mark -

#define DEFAULT_ROW_HEIGHT 88
#define HEADER_HEIGHT 48


@implementation APLTableViewController

- (BOOL)canBecomeFirstResponder {

    return YES;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    // Add a pinch gesture recognizer to the table view.
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	[self.tableView addGestureRecognizer:pinchRecognizer];

    // Set up default values.
    self.tableView.sectionHeaderHeight = HEADER_HEIGHT;
	/*
     The section info array is thrown away in viewWillUnload, so it's OK to set the default values here. If you keep the section information etc. then set the default values in the designated initializer.
     */
    self.uniformRowHeight = DEFAULT_ROW_HEIGHT;
    self.openSectionIndex = NSNotFound;

    UINib *sectionHeaderNib = [UINib nibWithNibName:@"SectionHeaderView" bundle:nil];
    [self.tableView registerNib:sectionHeaderNib forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

    /*
     Check whether the section info array has been created, and if so whether the section count still matches the current section count. In general, you need to keep the section info synchronized with the rows and section. If you support editing in the table view, you need to appropriately update the section info during editing operations.
     */
	if ((self.sectionInfoArray == nil) ||
        ([self.sectionInfoArray count] != [self numberOfSectionsInTableView:self.tableView])) {

        // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];

		for (APLPlay *play in self.plays) {

			APLSectionInfo *sectionInfo = [[APLSectionInfo alloc] init];
			sectionInfo.play = play;
			sectionInfo.open = NO;

            NSNumber *defaultRowHeight = @(DEFAULT_ROW_HEIGHT);
			NSInteger countOfQuotations = [[sectionInfo.play quotations] count];
			for (NSInteger i = 0; i < countOfQuotations; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}

			[infoArray addObject:sectionInfo];
		}

		self.sectionInfoArray = infoArray;
	}
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return [self.plays count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	APLSectionInfo *sectionInfo = (self.sectionInfoArray)[section];
	NSInteger numStoriesInSection = [[sectionInfo.play quotations] count];

    return sectionInfo.open ? numStoriesInSection : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *QuoteCellIdentifier = @"QuoteCellIdentifier";

    APLQuoteCell *cell = (APLQuoteCell*)[tableView dequeueReusableCellWithIdentifier:QuoteCellIdentifier];

    if ([MFMailComposeViewController canSendMail]) {

        if (cell.longPressRecognizer == nil) {
            UILongPressGestureRecognizer *longPressRecognizer =
                [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
            cell.longPressRecognizer = longPressRecognizer;
        }
    }
    else {
        cell.longPressRecognizer = nil;
    }

    APLPlay *play = (APLPlay *)[(self.sectionInfoArray)[indexPath.section] play];
    cell.quotation = (play.quotations)[indexPath.row];

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    APLSectionHeaderView *sectionHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];

    APLSectionInfo *sectionInfo = (self.sectionInfoArray)[section];
    sectionInfo.headerView = sectionHeaderView;
    
    sectionHeaderView.titleLabel.text = sectionInfo.play.name;
    sectionHeaderView.section = section;
    sectionHeaderView.delegate = self;
    
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	APLSectionInfo *sectionInfo = (self.sectionInfoArray)[indexPath.section];
    return [[sectionInfo objectInRowHeightsAtIndex:indexPath.row] floatValue];
    // Alternatively, return rowHeight.
}


#pragma mark - SectionHeaderViewDelegate

- (void)sectionHeaderView:(APLSectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {

	APLSectionInfo *sectionInfo = (self.sectionInfoArray)[sectionOpened];

	sectionInfo.open = YES;

    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [sectionInfo.play.quotations count];
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }

    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];

    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {

		APLSectionInfo *previousOpenSection = (self.sectionInfoArray)[previousOpenSectionIndex];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        NSInteger countOfRowsToDelete = [previousOpenSection.play.quotations count];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }

    // style the animation so that there's a smooth flow in either direction
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }

    // apply the updates
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    
    self.openSectionIndex = sectionOpened;
}

- (void)sectionHeaderView:(APLSectionHeaderView *)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {

    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	APLSectionInfo *sectionInfo = (self.sectionInfoArray)[sectionClosed];

    sectionInfo.open = NO;
    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];

    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    self.openSectionIndex = NSNotFound;
}


#pragma mark - Handling pinches

- (void)handlePinch:(UIPinchGestureRecognizer *)pinchRecognizer {

    /*
     There are different actions to take for the different states of the gesture recognizer.
     * In the Began state, use the pinch location to find the index path of the row with which the pinch is associated, and keep a reference to that in pinchedIndexPath. Then get the current height of that row, and store as the initial pinch height. Finally, update the scale for the pinched row.
     * In the Changed state, update the scale for the pinched row (identified by pinchedIndexPath).
     * In the Ended or Canceled state, set the pinchedIndexPath property to nil.
     */

    if (pinchRecognizer.state == UIGestureRecognizerStateBegan) {

        CGPoint pinchLocation = [pinchRecognizer locationInView:self.tableView];
        NSIndexPath *newPinchedIndexPath = [self.tableView indexPathForRowAtPoint:pinchLocation];
		self.pinchedIndexPath = newPinchedIndexPath;

		APLSectionInfo *sectionInfo = (self.sectionInfoArray)[newPinchedIndexPath.section];
        self.initialPinchHeight = [[sectionInfo objectInRowHeightsAtIndex:newPinchedIndexPath.row] floatValue];
        // Alternatively, set initialPinchHeight = uniformRowHeight.

        [self updateForPinchScale:pinchRecognizer.scale atIndexPath:newPinchedIndexPath];
    }
    else {
        if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
            [self updateForPinchScale:pinchRecognizer.scale atIndexPath:self.pinchedIndexPath];
        }
        else if ((pinchRecognizer.state == UIGestureRecognizerStateCancelled) || (pinchRecognizer.state == UIGestureRecognizerStateEnded)) {
            self.pinchedIndexPath = nil;
        }
    }
}

- (void)updateForPinchScale:(CGFloat)scale atIndexPath:(NSIndexPath *)indexPath {

    if (indexPath && (indexPath.section != NSNotFound) && (indexPath.row != NSNotFound)) {

		CGFloat newHeight = round(MAX(self.initialPinchHeight * scale, DEFAULT_ROW_HEIGHT));

		APLSectionInfo *sectionInfo = (self.sectionInfoArray)[indexPath.section];
        [sectionInfo replaceObjectInRowHeightsAtIndex:indexPath.row withObject:@(newHeight)];
        // Alternatively, set uniformRowHeight = newHeight.

        /*
         Switch off animations during the row height resize, otherwise there is a lag before the user's action is seen.
         */
        BOOL animationsEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        [UIView setAnimationsEnabled:animationsEnabled];
    }
}


#pragma mark - Handling long presses

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer {

    /*
     For the long press, the only state of interest is Began.
     When the long press is detected, find the index path of the row (if there is one) at press location.
     If there is a row at the location, create a suitable menu controller and display it.
     */
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {

        NSIndexPath *pressedIndexPath =
            [self.tableView indexPathForRowAtPoint:[longPressRecognizer locationInView:self.tableView]];

        if (pressedIndexPath && (pressedIndexPath.row != NSNotFound) && (pressedIndexPath.section != NSNotFound)) {
            
            [self becomeFirstResponder];
            NSString *title = NSLocalizedString(@"Email", @"Email menu title");            
            APLEmailMenuItem *menuItem =
                [[APLEmailMenuItem alloc] initWithTitle:title action:@selector(emailMenuButtonPressed:)];
            menuItem.indexPath = pressedIndexPath;

            UIMenuController *menuController = [UIMenuController sharedMenuController];
            menuController.menuItems = @[menuItem];
            
            CGRect cellRect = [self.tableView rectForRowAtIndexPath:pressedIndexPath];
            // lower the target rect a bit (so not to show too far above the cell's bounds)
            cellRect.origin.y += 40.0;
            [menuController setTargetRect:cellRect inView:self.tableView];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

- (void)emailMenuButtonPressed:(UIMenuController *)menuController {

    APLEmailMenuItem *menuItem = [[UIMenuController sharedMenuController] menuItems][0];
    if (menuItem.indexPath) {
        [self resignFirstResponder];
        [self sendEmailForEntryAtIndexPath:menuItem.indexPath];
    }
}

- (void)sendEmailForEntryAtIndexPath:(NSIndexPath *)indexPath {

	APLPlay *play = self.plays[indexPath.section];
    APLQuotation *quotation = play.quotations[indexPath.row];
    
    // In production, send the appropriate message.
    NSLog(@"Send email using quotation:\n%@", quotation.quotation);
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

    [self dismissViewControllerAnimated:YES completion:NULL];
    if (result == MFMailComposeResultFailed) {
        // In production, display an appropriate message to the user.
        NSLog(@"Mail send failed with error: %@", error);
    }
}

@end
