/*
    File:       ListAdderViewController.m

    Contains:   Main view controller.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "ListAdderViewController.h"

#import "NumberPickerController.h"
#import "OptionsController.h"

#import "AdderOperation.h"

@interface ListAdderViewController () <NumberPickerControllerDelegate, OptionsControllerDelegate>

// private properties

@property (nonatomic, retain, readonly ) NSMutableArray *   numbers;
@property (nonatomic, retain, readonly ) NSOperationQueue * queue;
@property (nonatomic, assign, readwrite) BOOL               recalculating;
@property (nonatomic, retain, readwrite) AdderOperation *   inProgressAdder;
@property (nonatomic, copy,   readwrite) NSString *         formattedTotal;

// forward declarations

- (void)presentNumberPickerModally;
- (void)recalculateTotal;
- (void)recalculateTotalUsingThread;
- (void)recalculateTotalUsingOperation;
- (void)adderOperationDone:(AdderOperation *)op;

@end

static char CharForCurrentThread(void)
    // Returns 'M' if we're running on the main thread, or 'S' otherwies.
{
    return [NSThread isMainThread] ? 'M' : 'S';
}

@implementation ListAdderViewController

+ (NSArray *)defaultNumbers
    // Returns the default numbers that we initialise the view with.
{
    return [NSArray arrayWithObjects:
        [NSNumber numberWithInt:7], 
        [NSNumber numberWithInt:5], 
        [NSNumber numberWithInt:8], 
        [NSNumber numberWithInt:9], 
        [NSNumber numberWithInt:7], 
        [NSNumber numberWithInt:6], 
        nil
    ];
}

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil) {
        // Set up some private properties.
        
        self->_numbers = [[[self class] defaultNumbers] mutableCopy];
        assert(self->_numbers != nil);

        self->_queue = [[NSOperationQueue alloc] init];
        assert(self->_queue != nil);
        
        // Set up our navigation bar.
        
        self.title = @"ListAdder";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStyleBordered target:self action:@selector(optionsAction:)        ] autorelease];
        self.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithTitle:@"Minimum" style:UIBarButtonItemStyleBordered target:self action:@selector(defaultsMinimumAction:)] autorelease];
        self.navigationItem.leftBarButtonItem.possibleTitles = [NSSet setWithObjects:@"Defaults", @"Minimum", nil];
    }
    return self;
}

- (void)dealloc
{
    // This is the root view controller of our application, so it can never be 
    // deallocated.  Supporting -dealloc in the presence of threading, even highly 
    // constrained threading as used by this example, is tricky.  My recommended 
    // technique for doing this is the QWatchedOperationQueue class in the 
    // LinkedImageFetcher sample code.
    //
    // <http://developer.apple.com/mac/library/samplecode/LinkedImageFetcher/>
    // 
    // However, I didn't want to drag parts of that sample into this sample (especially 
    // given that -dealloc can never be called in this sample and thus I can't test it), 
    // nor did I want to demonstrate an ad hoc, and potentially buggy, version of 
    // -dealloc.  So, for the moment, we just don't support -dealloc.

    assert(NO);

    // Despite the above, I've left in the following just as an example of how you 
    // manage self observation in a view controller. 

    // If we got -dealloc'd without ever releasing our observer, do that now.
    
    if (self.isViewLoaded) {
        [self removeObserver:self forKeyPath:@"recalculating"];
    }

    [super dealloc];
}

- (void)syncLeftBarButtonTitle
{
    if ([self.numbers count] <= 1) {
        self.navigationItem.leftBarButtonItem.title = @"Defaults";
    } else {
        self.navigationItem.leftBarButtonItem.title = @"Minimum";
    }
}

#pragma mark * Properties

@synthesize numbers         = _numbers;
@synthesize formattedTotal  = _formattedTotal;
@synthesize queue           = _queue;
@synthesize recalculating   = _recalculating;
@synthesize inProgressAdder = _inProgressAdder;

#pragma mark * View controller stuff

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure our table view.
    
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    // Observe recalculating to trigger reloads of the cell in the first 
    // section (kListAdderSectionIndexTotal).
    
    [self addObserver:self forKeyPath:@"recalculating" options:0 context:&self->_inProgressAdder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self removeObserver:self forKeyPath:@"recalculating"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // When we come on screen, if we don't have a current value and we're not 
    // already calculating a value, kick off an operation to calculate the initial 
    // value of the total.
    
    if ( (self.formattedTotal == nil) && ! self.recalculating ) {
        [self recalculateTotal];
    }
}

#pragma mark * Table view callbacks

enum {
    kListAdderSectionIndexTotal = 0,
    kListAdderSectionIndexAddNumber,
    kListAdderSectionIndexNumbers,
    kListAdderSectionIndexCount
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    #pragma unused(tv)
    assert(tv == self.tableView);
    return kListAdderSectionIndexCount;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section < kListAdderSectionIndexCount);

    return (section == kListAdderSectionIndexNumbers) ? [self.numbers count] : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *	cell;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section < kListAdderSectionIndexCount);
    assert(indexPath.row < ((indexPath.section == kListAdderSectionIndexNumbers) ? [self.numbers count] : 1));

    // Get a cell to work with.
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);
    }
    
    // Reset it to default values.
    
    cell.editingAccessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Set it up based on the section and row.
    
    switch (indexPath.section) {
        default:
            assert(NO);
            // fall through
        case kListAdderSectionIndexTotal: {
            cell.textLabel.text = @"Total";
            if (self.recalculating) {
                UIActivityIndicatorView *   activityView;
                
                activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
                assert(activityView != nil);

                [activityView startAnimating];
                
                cell.editingAccessoryView = activityView;
            } else {
                cell.detailTextLabel.text = self.formattedTotal;
            }
        } break;
        case kListAdderSectionIndexAddNumber: {
            cell.textLabel.text = @"Add Number…";
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        } break;
        case kListAdderSectionIndexNumbers: {
            cell.textLabel.text = [[self.numbers objectAtIndex:indexPath.row] description];
        } break;
    }

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle result;

    #pragma unused(tv)
    assert(tv == self.tableView);
    assert(indexPath.section < kListAdderSectionIndexCount);
    assert(indexPath.row < ((indexPath.section == kListAdderSectionIndexNumbers) ? [self.numbers count] : 1));
    
    switch (indexPath.section) {
        default:
            assert(NO);
            // fall through
        case kListAdderSectionIndexTotal: {
            result = UITableViewCellEditingStyleNone;
        } break;
        case kListAdderSectionIndexAddNumber: {
            result = UITableViewCellEditingStyleInsert;
        } break;
        case kListAdderSectionIndexNumbers: {
            // We don't allow the user to delete the last cell.
            if ([self.numbers count] == 1) {
                result = UITableViewCellEditingStyleNone;
            } else {
                result = UITableViewCellEditingStyleDelete;
            }
        } break;
    }
    return result;
}

// I would like to suppress the delete confirmation button but I don't think there's a 
// supported way to do this.

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    assert(tv == self.tableView);
    assert(indexPath.section < kListAdderSectionIndexCount);
    assert(indexPath.row < ((indexPath.section == kListAdderSectionIndexNumbers) ? [self.numbers count] : 1));

    switch (indexPath.section) {
        default:
            assert(NO);
            // fall through
        case kListAdderSectionIndexTotal: {
            assert(NO);
        } break;
        case kListAdderSectionIndexAddNumber: {
            #pragma unused(editingStyle)
            assert(editingStyle == UITableViewCellEditingStyleInsert);
            
            // The user has tapped on the plus button.  Bring up the number picker.
            
            [self presentNumberPickerModally];
        } break;
        case kListAdderSectionIndexNumbers: {
            #pragma unused(editingStyle)
            assert(editingStyle == UITableViewCellEditingStyleDelete);
            assert([self.numbers count] != 0);      // because otherwise we'd have no delete button

            // Remove the row from our model and the table view.
            
            [self.numbers removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            // If we've transitioned from 2 rows to 1 row, remove the delete button for the 
            // remaining row; we don't want folks deleting that now, do we?  Also, set the 
            // title of the left bar button to "Defaults" to reflect its updated function.
            
            if ([self.numbers count] == 1) {
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:kListAdderSectionIndexNumbers]] withRowAnimation:UITableViewRowAnimationNone];
                
                [self syncLeftBarButtonTitle];
            }
            
            // We've modified numbers, so kick off a recalculation.
            
            [self recalculateTotal];
        } break;
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section < kListAdderSectionIndexCount);
    assert(indexPath.row < ((indexPath.section == kListAdderSectionIndexNumbers) ? [self.numbers count] : 1));

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        default:
            assert(NO);
            // fall through
        case kListAdderSectionIndexTotal: {
            // do nothing
        } break;
        case kListAdderSectionIndexAddNumber: {

            // The user has tapped on the body of the cell associated with plus button.  
            // Bring up the number picker.

            [self presentNumberPickerModally];
        } break;
        case kListAdderSectionIndexNumbers: {
            // do nothing
        } break;
    }
}

#pragma mark * Number picker management

- (void)presentNumberPickerModally
    // Displays the number picker so that the user can add a new number to the 
    // list of numbers to add up.
{
    NumberPickerController *    vc;
    
    vc = [[[NumberPickerController alloc] init] autorelease];
    assert(vc != nil);
    
    vc.delegate = self;
    
    [vc presentModallyOn:self];
}

- (void)numberPicker:(NumberPickerController *)controller didChooseNumber:(NSNumber *)number
    // Called by the number picker when the user chooses a number or taps cancel.
{
    #pragma unused(controller)
    assert(controller != nil);
    
    // If it wasn't cancelled...
    
    if (number != nil) {
    
        // Add the number to our model and the table view.
        
        [self.numbers addObject:number];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.numbers count] - 1 inSection:kListAdderSectionIndexNumbers]] withRowAnimation:UITableViewRowAnimationFade];

        // If we've transitioned from 1 row to 2 rows, add the delete button back for 
        // the first row.  Also change the left bar button item back to "Minimum".
        
        if ([self.numbers count] == 2) {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:kListAdderSectionIndexNumbers]] withRowAnimation:UITableViewRowAnimationNone];
            
            [self syncLeftBarButtonTitle];
        }

        // We've modified numbers, so kick off a recalculation.
        
        [self recalculateTotal];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark * Options management

- (void)presentOptionsModally
    // Displays the options view so that the user can add a new number to the 
    // list of numbers to add up.
{
    OptionsController * vc;
    
    vc = [[[OptionsController alloc] init] autorelease];
    assert(vc != nil);
    
    vc.delegate = self;
    
    [vc presentModallyOn:self];
}

- (void)didSaveOptions:(OptionsController *)controller
    // Called when the user taps Save in the options view.  The options 
    // view has already saved the options, so we have nothing to do other 
    // than to tear down the view.
{
    #pragma unused(controller)
    assert(controller != nil);
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didCancelOptions:(OptionsController *)controller
    // Called when the user taps Cancel in the options view.
{
    #pragma unused(controller)
    assert(controller != nil);
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark * Async recalculation

- (void)recalculateTotal
    // Starts a recalculation using either the thread- or NSOperation-based code.
{
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"useThreadsDirectly"] ) {
        [self recalculateTotalUsingThread];
    } else {
        [self recalculateTotalUsingOperation];
    }
}

#pragma mark - NSThread

- (void)recalculateTotalUsingThread
    // Starts a recalculation using a thread.
{
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"retainNotCopy"] ) {
        self.recalculating = YES;

        [self performSelectorInBackground:@selector(threadRecalculateNumbers:) withObject:self.numbers];
    } else {
        NSArray *       immutableNumbers;

        self.recalculating = YES;
        
        immutableNumbers = [[self.numbers copy] autorelease];
        assert(immutableNumbers != nil);
        [self performSelectorInBackground:@selector(threadRecalculateNumbers:) withObject:immutableNumbers];
    }
}

- (void)threadRecalculateNumbers:(NSArray *)immutableNumbers
    // Does the actual recalculation when we're in threaded mode.  Always 
    // called on a secondary thread.
{
    NSAutoreleasePool *     pool;
    NSInteger               total;
    NSUInteger              numberCount;
    NSUInteger              numberIndex;
    NSString *              totalStr;

    assert( ! [NSThread isMainThread] );

    pool = [[NSAutoreleasePool alloc] init];
    assert(pool != nil);
    
    total = 0;
    numberCount = [immutableNumbers count];
    for (numberIndex = 0; numberIndex < numberCount; numberIndex++) {
        NSNumber *  numberObj;
        
        // Sleep for a while.  This makes it easiest to test various problematic cases.
        
        [NSThread sleepForTimeInterval:1.0];
        
        // Do the maths.
        
        numberObj = [immutableNumbers objectAtIndex:numberIndex];
        assert([numberObj isKindOfClass:[NSNumber class]]);
        
        total += [numberObj integerValue];
    }
    
    totalStr = [NSString stringWithFormat:@"%ld", (long) total];
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"applyResultsFromThread"] ) {
        self.formattedTotal = totalStr;
        self.recalculating = NO;
    } else {
        [self performSelectorOnMainThread:@selector(threadRecalculateDone:) withObject:totalStr waitUntilDone:NO];
    }
    
    [pool drain];
}

- (void)threadRecalculateDone:(NSString *)result
    // In threaded mode, called on the main thread to apply the results to the UI.
{
    assert([NSThread isMainThread]);

    // The user interface is adjusted by a KVO observer on recalculating.

    self.formattedTotal = result;
    self.recalculating = NO;
}

- (void)threadRecalculateNumbers
{
    NSAutoreleasePool *     pool;
    NSInteger               total;
    NSUInteger              numberCount;
    NSUInteger              numberIndex;
    NSString *              totalStr;

    // IMPORTANT: This method is not actually used.  It is here because it's a code 
    // snippet in the technote, and i wanted to make sure it compiles.
    
    assert(NO);
    
    pool = [[NSAutoreleasePool alloc] init];
    assert(pool != nil);
    
    total = 0;
    numberCount = [self.numbers count];
    for (numberIndex = 0; numberIndex < numberCount; numberIndex++) {
        NSNumber *  numberObj;
        
        // Sleep for a while.  This makes it easiest to test various problematic cases.
        
        [NSThread sleepForTimeInterval:1.0];
        
        // Do the maths.
        
        numberObj = [self.numbers objectAtIndex:numberIndex];
        assert([numberObj isKindOfClass:[NSNumber class]]);
        
        total += [numberObj integerValue];
    }
    
    // The user interface is adjusted by a KVO observer on recalculating.

    totalStr = [NSString stringWithFormat:@"%ld", (long) total];
    self.formattedTotal = totalStr;
    self.recalculating = NO;
    
    [pool drain];
}

- (void)threadRecalculateNumbers2
{
    NSAutoreleasePool *     pool;
    NSInteger               total;
    NSUInteger              numberCount;
    NSUInteger              numberIndex;
    NSString *              totalStr;

    // IMPORTANT: This method is not actually used.  It is here because it's a code 
    // snippet in the technote, and i wanted to make sure it compiles.
    
    assert(NO);
    
    pool = [[NSAutoreleasePool alloc] init];
    assert(pool != nil);
    
    total = 0;
    numberCount = [self.numbers count];
    for (numberIndex = 0; numberIndex < numberCount; numberIndex++) {
        NSNumber *  numberObj;
        
        // Sleep for a while.  This makes it easiest to test various problematic cases.
        
        [NSThread sleepForTimeInterval:1.0];
        
        // Do the maths.
        
        numberObj = [self.numbers objectAtIndex:numberIndex];
        assert([numberObj isKindOfClass:[NSNumber class]]);
        
        total += [numberObj integerValue];
    }
    
    // Update the user interface on the main thread.

    totalStr = [NSString stringWithFormat:@"%ld", (long) total];
    [self performSelectorOnMainThread:@selector(threadRecalculateDone:) withObject:totalStr waitUntilDone:NO];
    
    [pool drain];
}

#pragma mark - NSOperation

- (void)recalculateTotalUsingOperation
    // Starts a recalculation using an NSOperation.
{
    // If we're already calculating, cancel that operation.  It's going to 
    // yield stale results.  We don't remove the observer here, but rather 
    // remove the observer when it completes.  Also, we don't nil out 
    // inProgressAdder because it'll just get replaced in the next line 
    // and changing the value triggers an unnecessary KVO notification of 
    // recalculating.
    
    if (self.inProgressAdder != nil) {
        fprintf(stderr, "%c %3lu cancelled\n", CharForCurrentThread(), (unsigned long) self.inProgressAdder.sequenceNumber);
        [self.inProgressAdder cancel];
    }

    // Start up a replacement operation.
    
    self.inProgressAdder = [[[AdderOperation alloc] initWithNumbers:self.numbers] autorelease];
    assert(self.inProgressAdder != nil);
    
    [self.inProgressAdder addObserver:self forKeyPath:@"isFinished"  options:0 context:&self->_formattedTotal];
    [self.inProgressAdder addObserver:self forKeyPath:@"isExecuting" options:0 context:&self->_queue];
    
    fprintf(stderr, "%c %3lu queuing\n", CharForCurrentThread(), (unsigned long) self.inProgressAdder.sequenceNumber);
    [self.queue addOperation:self.inProgressAdder];

    // The user interface is adjusted by a KVO observer on recalculating.
    
    self.recalculating = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_formattedTotal) {
        AdderOperation *    op;

        // If the operation has finished, call -adderOperationDone: on the main thread to deal 
        // with the results.

        // can be running on any thread
        assert([keyPath isEqual:@"isFinished"]);
        op = (AdderOperation *) object;
        assert([op isKindOfClass:[AdderOperation class]]);
        assert([op isFinished]);

        fprintf(stderr, "%c %3lu finished\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"applyResultsFromThread"]) {
            [self adderOperationDone:op];
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"allowStale"]) {
                [self performSelectorOnMainThread:@selector(adderOperationDoneWrong:) withObject:op waitUntilDone:NO];
            } else {
                [self performSelectorOnMainThread:@selector(adderOperationDone:)      withObject:op waitUntilDone:NO];
            }
        }
    } else if (context == &self->_queue) {
        AdderOperation *    op;
        
        // We observe -isExecuting purely for logging purposes.
        
        // can be running on any thread
        assert([keyPath isEqual:@"isExecuting"]);
        op = (AdderOperation *) object;
        assert([op isKindOfClass:[AdderOperation class]]);
        if ([op isExecuting]) {
            fprintf(stderr, "%c %3lu executing\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
        } else {
            fprintf(stderr, "%c %3lu stopped\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
        }
    } else if (context == &self->_inProgressAdder) {
    
        // If recalculating changes, reload the first section (kListAdderSectionIndexTotal) 
        // which causes the activity indicator to come or go.
        
        assert([NSThread isMainThread]);
        assert([keyPath isEqual:@"recalculating"]);
        assert(object == self);
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:kListAdderSectionIndexTotal]] withRowAnimation:UITableViewRowAnimationNone];
    }
    if (NO) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)adderOperationDone:(AdderOperation *)op
{
    assert([NSThread isMainThread]);
    assert([op isKindOfClass:[AdderOperation class]]);
    
    assert(self.recalculating);
    
    // Always remove our observer, regardless of whether we care about 
    // the results of this operation.
    
    fprintf(stderr, "%c %3lu done\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
    [op removeObserver:self forKeyPath:@"isFinished"];
    [op removeObserver:self forKeyPath:@"isExecuting"];

    // Check to see whether these are the results we're looking for. 
    // If not, we just discard the results; later on we'll be notified 
    // of the latest add operation completing.
    
    if (op == self.inProgressAdder) {
        assert( ! [op isCancelled] );

        // Commit the value to our model.

        fprintf(stderr, "%c %3lu commit\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);

        self.formattedTotal = op.formattedTotal;

        // Clear out our record of the operation.  The user interface is adjusted 
        // by a KVO observer on recalculating.
        
        self.inProgressAdder = nil;
        self.recalculating = NO;
    } else {
        fprintf(stderr, "%c %3lu discard\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
    }
}

- (void)adderOperationDoneWrong:(AdderOperation *)op
{
    assert([NSThread isMainThread]);
    assert([op isKindOfClass:[AdderOperation class]]);
    
    // Because we're ignoring stale operations, the following assert will 
    // trips.
    //
    // assert(self.recalculating);
    
    // Always remove our observer, regardless of whether we care about 
    // the results of this operation.
    
    fprintf(stderr, "%c %3lu done\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);
    [op removeObserver:self forKeyPath:@"isFinished"];
    [op removeObserver:self forKeyPath:@"isExecuting"];

    // Check to see whether these are the results we're looking for. 
    // If not, we just discard the results; later on we'll be notified 
    // of the latest add operation completing.
    
    // Because we're ignoring stale operations, the following assert will 
    // trips.
    // 
    // assert( ! [op isCancelled] );

    // Commit the value to our model.

    fprintf(stderr, "%c %3lu commit\n", CharForCurrentThread(), (unsigned long) op.sequenceNumber);

    self.formattedTotal = op.formattedTotal;

    // Clear out our record of the operation.  The user interface is adjusted 
    // by a KVO observer on recalculating.
    
    self.inProgressAdder = nil;
    self.recalculating = NO;
}

#pragma mark * UI actions

- (void)defaultsMinimumAction:(id)sender
    // Called when the user taps the left bar button ("Defaults" or "Minimum").  
    // If we have lots of numbers, set the list to contain a sigle entry.  If we have 
    // just one number, reset the list back to the defaults.  This allows us to easily 
    // test cancellation and the discard of stale results.
{
    #pragma unused(sender)
    if ([self.numbers count] > 1) {
        [self.numbers removeAllObjects];
        [self.numbers addObject:[NSNumber numberWithInteger:41]];
    } else {
        [self.numbers replaceObjectsInRange:NSMakeRange(0, [self.numbers count]) withObjectsFromArray:[[self class] defaultNumbers]];
    }
    [self syncLeftBarButtonTitle];
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
    [self recalculateTotal];
}

- (void)optionsAction:(id)sender
    // Called when the user taps the option button.  We just bring up the 
    // options view.
{
    #pragma unused(sender)
    [self presentOptionsModally];
}

@end
