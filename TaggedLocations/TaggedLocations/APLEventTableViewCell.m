
/*
     File: APLEventTableViewCell.m
 Abstract: Table view cell to display information about an event.
 The cell layout is mainly defined in the storyboard, but some Auto Layout constraints are redefined programmatically.
 
  Version: 2.3
 
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

#import "APLEventTableViewCell.h"
#import "APLEvent.h"
#import "APLTag.h"

@interface APLEventTableViewCell ()

@property (nonatomic, weak, readwrite) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UILabel *creationDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UITextField *tagsField;
@property (nonatomic, weak) IBOutlet UIButton *tagsButton;

@end


@implementation APLEventTableViewCell


- (IBAction)editTags:(id)sender
{
    /*
     Send message to delegate -- the table view controller -- to start editing tags.
     */
    [self.delegate performSegueWithIdentifier:@"EditTags" sender:self];
}


- (void)configureWithEvent:(APLEvent *)event
{
	self.nameField.text = event.name;
	
	self.creationDateLabel.text = [self.dateFormatter stringFromDate:[event creationDate]];
	
	NSString *string = [NSString stringWithFormat:@"%@, %@",
						[self.numberFormatter stringFromNumber:[event latitude]],
						[self.numberFormatter stringFromNumber:[event longitude]]];
    self.locationLabel.text = string;
    
	NSMutableArray *eventTagNames = [NSMutableArray new];
	for (APLTag *tag in event.tags) {
		[eventTagNames addObject:tag.name];
	}
	
	NSString *tagsString = @"";
	if ([eventTagNames count] > 0) {
		tagsString = [eventTagNames componentsJoinedByString:@", "];
	}
	self.tagsField.text = tagsString;
}


- (BOOL)makeNameFieldFirstResponder
{
	return [self.nameField becomeFirstResponder];
}


/*
 When the table view becomes editable, the cell should:
 * Hide the location label (so that the Delete button does not overlap it)
 * Enable the name field (to make it editable)
 * Display the tags button
 * Set a placeholder for the tags field (so the user knows to tap to edit tags)
 * Move the visible views out of the way of the edit icon.
 The inverse applies when the table view has finished editing.
 */
 
- (void)willTransitionToState:(UITableViewCellStateMask)state
{
	[super willTransitionToState:state];
	
	if (state & UITableViewCellStateEditingMask) {
		self.locationLabel.hidden = YES;
		self.nameField.enabled = YES;
		self.tagsButton.hidden = NO;
		self.tagsField.placeholder = NSLocalizedString(@"Tap to edit tags", @"Text for tags field in main table view cell");
	}
}


- (void)didTransitionToState:(UITableViewCellStateMask)state
{
	[super didTransitionToState:state];
	
	if (!(state & UITableViewCellStateEditingMask)) {
		self.locationLabel.hidden = NO;
		self.nameField.enabled = NO;
		self.tagsButton.hidden = YES;
		self.tagsField.placeholder = @"";
	}
}

#pragma mark - Internationalization

/*
 Reset the date and number formatters if the locale changes.
 */

+(void)initialize
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        sDateFormatter = nil;
        sNumberFormatter = nil;
    }];
}


// A date formatter for the creation date.
- (NSDateFormatter *)dateFormatter
{
    return [[self class] dateFormatter];
}


static NSDateFormatter *sDateFormatter = nil;

+ (NSDateFormatter *)dateFormatter
{
	if (sDateFormatter == nil) {
		sDateFormatter = [[NSDateFormatter alloc] init];
		[sDateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[sDateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
    return sDateFormatter;
}

// A number formatter for the latitude and longitude.
- (NSNumberFormatter *)numberFormatter
{
    return [[self class] numberFormatter];
}


static NSNumberFormatter *sNumberFormatter = nil;

+ (NSNumberFormatter *)numberFormatter
{
	if (sNumberFormatter == nil) {
		sNumberFormatter = [[NSNumberFormatter alloc] init];
		[sNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[sNumberFormatter setMaximumFractionDigits:3];
	}
    return sNumberFormatter;
}

#pragma mark - Layout

/*
 Auto Layout workaround:
 
 Constraints made in the storyboard to the superview of views in the content view are made instead to the table view cell itself. This means that when the cell enters the editing state the content is not properly moved out of the way of the editing icons (the content view is shrunk to move content out of the way). A workaround is to remove the inappropriate constraints and recreate them substituting the content view for self.
 */
- (void)awakeFromNib
{
    NSArray *constraints = [self.constraints copy];
    
    for (NSLayoutConstraint *constraint in constraints) {
        
        id firstItem = constraint.firstItem;
        if (firstItem == self) {
            firstItem = self.contentView;
        }
        id secondItem = constraint.secondItem;
        if (secondItem == self) {
            secondItem = self.contentView;
        }
        
        NSLayoutConstraint *fixedConstraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant];
        
        [self removeConstraint:constraint];
        [self.contentView addConstraint:fixedConstraint];
    }
}


@end
