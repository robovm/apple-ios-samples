/*
    File:       SetupViewController.h

    Contains:   Lets the user configure the gallery to view.

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

#import "SetupViewController.h"

#import "NetworkManager.h"

@interface SetupViewController () <UITextFieldDelegate>

// private properties

@property (nonatomic, assign, readonly ) BOOL               canSave;
@property (nonatomic, retain, readonly ) NSMutableArray *   choices;
@property (nonatomic, assign, readwrite) BOOL               choicesDirty;
@property (nonatomic, assign, readwrite) NSUInteger         choiceIndex;
@property (nonatomic, copy,   readwrite) NSString *         otherChoice;
@property (nonatomic, retain, readwrite) UITextField *      activeTextField;

// forward declarations

- (NSString *)smartURLStringForString:(NSString *)str;
- (IBAction)saveAction:(id)sender;

@end

@implementation SetupViewController

+ (void)resetChoices
    // See comment in header.
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"setupChoices"];
}

- (id)initWithGalleryURLString:(NSString *)galleryURLString
{
    // galleryURLString may be nil
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        NSUInteger  choiceIndex;
        NSUInteger  choiceCount;
        
        // Get the current list of choices, or start with the defaults.
        
        self->_choices = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"setupChoices"] mutableCopy];
        if (self->_choices == nil) {
            #if TARGET_IPHONE_SIMULATOR
                #define HOSTNAME "localhost"
            #else
                #define HOSTNAME "worker.local."
            #endif
            self->_choices = [[NSMutableArray alloc] initWithObjects:
                @"http://" HOSTNAME "/TestGallery/index.xml", 
                @"http://" HOSTNAME "/TestGallery/index2.xml", 
                @"http://" HOSTNAME "/TestGallery/index-empty.xml", 
                @"http://" HOSTNAME "/TestGallery/index-big.xml", 
                @"http://" HOSTNAME "/TestGallery/index-giant.xml", 
                @"http://" HOSTNAME "/TestGallery/oddballs.xml", 
                @"http://" HOSTNAME "/TestGallery/changes.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-empty.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-html.html", 
                @"http://" HOSTNAME "/TestGallery/broken-html.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-text.txt", 
                @"http://" HOSTNAME "/TestGallery/broken-text.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-xml.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-attributes.xml", 
                @"http://" HOSTNAME "/TestGallery/broken-images.xml", 
                nil
            ];
        }
        assert(self->_choices != nil);
        
        // Eliminate anything that doesn't look like a URL.
        
        choiceCount = [self->_choices count];
        for (choiceIndex = 0; choiceIndex < choiceCount; choiceIndex++) {
            NSString *  tmp;
            
            tmp = [self->_choices objectAtIndex:choiceIndex];
            if ( ! [tmp isKindOfClass:[NSString class]] ) {
                tmp = nil;
            } else {
                tmp = [self smartURLStringForString:tmp];
            }
            if ( (tmp == nil) || ([tmp length] == 0) ) {
                [self->_choices removeObjectAtIndex:choiceIndex];
                choiceIndex -= 1;
                choiceCount -= 1;
            } else {
                [self->_choices replaceObjectAtIndex:choiceIndex withObject:tmp];
            }
        }

        // Get the current choice.  If there is no current choice, we select the "other" 
        // row.  If there is a current choice, set up choiceIndex to point to it. 
        // If the current choice isn't in the the choices list, add an item in that 
        // list to make it so (and set choicesDirty so that we save back the new 
        // list of the user taps Save).

        if (galleryURLString == nil) {
            self->_choiceIndex = [self->_choices count];
        } else {
            self->_choiceIndex = [self->_choices indexOfObject:galleryURLString];
            if (self->_choiceIndex == NSNotFound) {
                self->_choiceIndex = [self->_choices count];
                [self->_choices addObject:[[galleryURLString copy] autorelease]];
                self->_choicesDirty = YES;
            }
        }
        
        // Add an observer to update the enabled state on the Save button.
        
        [self addObserver:self forKeyPath:@"canSave" options:NSKeyValueObservingOptionInitial context:&self->_choiceIndex];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"canSave"];
    [self->_choices release];
    [self->_otherChoice release];
    [self->_activeTextField release];
    [super dealloc];
}

@synthesize delegate        = _delegate;

@synthesize choices         = _choices;
@synthesize choicesDirty    = _choicesDirty;
@synthesize choiceIndex     = _choiceIndex;
@synthesize otherChoice     = _otherChoice;
@synthesize activeTextField = _activeTextField;

- (NSString *)smartURLStringForString:(NSString *)str
    // Returns a URL string for the specified string, handling all sorts of edge cases. 
    // This can returns one of three different types of result:
    // 
    // o If str is empty (or nil), it returns the empty string (@"").
    // o If str is an invalid URL, it returns nil.
    // o If string is a valid URL, it returns a non-nil, non-empty string.
{
    NSString *  result;
    NSRange     schemeMarkerRange;
    NSString *  scheme;
    
    result = nil;
    
    // Treat nil as empty and then trim any whitespace.
    
    if (str == nil) {
        str = @"";
    }
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ( (str == nil) || ([str length] == 0) ) {
        result = @"";
    } else {
        NSURL *     resultURL;
        
        schemeMarkerRange = [str rangeOfString:@"://"];
        
        resultURL = nil;
        if (schemeMarkerRange.location == NSNotFound) {
            // If the string does not contain "://", add the "http://" prefix.
            resultURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", str]];
        } else {
            // Check the scheme to see if it's one we support.
            scheme = [str substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
            assert(scheme != nil);
            
            if ( ([scheme compare:@"http"  options:NSCaseInsensitiveSearch] == NSOrderedSame)
              || ([scheme compare:@"https" options:NSCaseInsensitiveSearch] == NSOrderedSame) ) {
                resultURL = [NSURL URLWithString:str];
            } else {
                // It looks like this is some unsupported URL scheme.
            }
        }
        
        // If we managed to create a URL, get the result string from that.
        
        if (resultURL != nil) {
            if ( [resultURL host] != nil ) {
                result = [resultURL absoluteString];
            }
        }
    }

    assert( (result == nil) || ([result length] == 0) || ([NSURL URLWithString:result] != nil) );
    
    return result;
}

- (NSString *)effectiveChoice
    // Returns the current choice displayed in the UI, which is either one of the selected 
    // choices or the string from the "other" row.  This has the same post condition as 
    // -smartURLStringForString:.
{
    NSString *  result;
    
    if (self.choiceIndex < [self.choices count]) {
        result = [self.choices objectAtIndex:self.choiceIndex];
        assert( [NSURL URLWithString:result] != nil );
    } else {
        result = [self smartURLStringForString:self.otherChoice];
    }
    assert( (result == nil) || ([result length] == 0) || ([NSURL URLWithString:result] != nil) );
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingCanSave
{
    return [NSSet setWithObjects:@"otherChoice", @"choiceIndex", nil];
}

- (BOOL)canSave
    // Returns YES if the current choice displayed in the UI is valid enough to be saved.
{
    BOOL        result;
    
    result = (self.choiceIndex != [self.choices count]);
    if ( ! result ) {
        result = ([self effectiveChoice] != nil);
    }
    return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_choiceIndex) {
    
        // Called as our canSave property changes.  We respond by enabling or disabling 
        // the Save bar button item.
    
        assert([keyPath isEqual:@"canSave"]);
        assert(object == self);
        self.navigationItem.rightBarButtonItem.enabled = self.canSave;
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark * View controller stuff

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    assert(self.activeTextField == nil);    // We shouldn't disappear with an active text field.
}

#pragma mark * Table view callbacks

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);

    return [self.choices count] + 1;        // +1 to account for "other" row
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    BOOL                otherCell;
    NSString *          cellID;
    UITableViewCell *	cell;
    UITextField *       textField;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < ([self.choices count] + 1));

    // Use one cell identifier for the "other" row, and another for all the normal rows.
    
    otherCell = (indexPath.row == [self.choices count]);
    if (otherCell) {
        cellID = @"otherCell";
    } else {
        cellID = @"cell";
    }

    // Create the cell itself.  Doing this for the "other" row is a little complex (-:
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
        assert(cell != nil);
        
        if (otherCell) {
            CGRect  frame;
            
            frame = CGRectZero;
            frame.size = cell.contentView.frame.size;
            frame.origin.x    += 10.0f;
            frame.size.width  -= 20.0f;
            frame.origin.y     =  6.0f;
            frame.size.height -= 12.0f;
            textField = [[[UITextField alloc] initWithFrame:frame] autorelease];
            assert(textField != nil);
            
            textField.tag = 666;
            textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            textField.placeholder = @"other";
            textField.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeURL;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.delegate = self;
            
            [cell.contentView addSubview:textField];
        } else {
            cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
            cell.textLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        }
    }
    
    // Set up the cell.
    
    if (indexPath.row < [self.choices count]) {

        // A standard cell.  Just set the text label to the corresponding element 
        // of the choices array.

        cell.textLabel.text = [self.choices objectAtIndex:indexPath.row];
    } else {

        // The "other" cell.  Find the text field embedded in the cell and set its 
        // text to the current other choice.

        textField = (UITextField *) [cell.contentView viewWithTag:666];
        assert([textField isKindOfClass:[UITextField class]]);
        
        textField.text = self.otherChoice;
    }
    cell.accessoryType = indexPath.row == self.choiceIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (void)chooseRow:(NSUInteger)row
    // Choose the specified row.  This updates both the UI (that is, the checkmark 
    // accessory view) and our choiceIndex property.
{
    UITableViewCell *   cell;

    if (row != self.choiceIndex) {

        // If we're leaving the "other" row, take the keyboard focus away from it.
        
        if ( (row < [self.choices count]) && (self.activeTextField != nil) ) {
            [self.activeTextField resignFirstResponder];
        }
    
        // Uncheck the currently checked cell, change the choice, and then recheck the newly checked cell.
    
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.choiceIndex inSection:0]];
        if (cell != nil) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        self.choiceIndex = row;
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.choiceIndex inSection:0]];
        if (cell != nil) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < ([self.choices count] + 1));

    [self chooseRow:indexPath.row];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
    // While there's no way to put the table view in edit mode, we still support 
    // "swipe to delete" for everything except the "other" row.
{
    #pragma unused(tv)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < ([self.choices count] + 1));

    return (indexPath.row < [self.choices count]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
    // Implement the mechanics of "swipe to delete".
{
    #pragma unused(tv)
    #pragma unused(editingStyle)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(editingStyle == UITableViewCellEditingStyleDelete);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < [self.choices count]);
    
    // If the user is deleting the currently chosen row, choose another one.  There 
    // are three cases:
    // 
    // o If this is the last remaining normal choice, choose the "other" row.
    // o If this is the last normal choice, choose the row before this.
    // o Otherwise, choose the row after this row.
    
    if (indexPath.row == self.choiceIndex) {
        assert([self.choices count] != 0);          // because the user has swiped to delete, and that's only possible for normal choices
        if ( [self.choices count] == 1 ) {
            [self chooseRow:1];                     // We're about to delete the last remaining normal choice; switch to the "other" choice.
        } else if (indexPath.row == ([self.choices count] - 1)) { 
            [self chooseRow:indexPath.row - 1];     // We're about to delete the last normal choice; switch to the previous choice.
        } else {
            [self chooseRow:indexPath.row + 1];     // We're about to delete some common-or-garden normal chocie; switch to the next choice.
        }
    }
    
    [self.choices removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

    // If the choice index is after the row we just deleted, step it back by one.
    
    assert(indexPath.row != self.choiceIndex);      // because we moved away from it in the previous code
    if (indexPath.row < self.choiceIndex) {
        self.choiceIndex -= 1;
    }
    
    self.choicesDirty = YES;
}

#pragma mark * Text field callbacks

- (void)textFieldDidBeginEditing:(UITextField *)textField
    // There are there things to do here:
    //
    // o record the active text field so that we have a reference to it for 
    //   other purposes (like tell it to resignFirstResponder if the user 
    //   taps on another row)
    // o choose the "other" row so that the UI and chosenIndex reflect that
    // o add an observer for the UITextFieldTextDidChangeNotification so that 
    //   we can track the content of the text field in order to enable and 
    //   disable our Save button
{
    self.activeTextField = textField;
    [self chooseRow:[self.choices count]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.activeTextField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *  finalString;
    NSString *  urlStr;
    
    assert(textField == self.activeTextField);
    #pragma unused(textField)

    // Push the text field value back to our property.  In the process, 
    // if it's a valid URL, put the full URL string back into the text field. 
    // This allows the user to type "foo.com" and, when they're done, see 
    // "http://foo.com".
    
    finalString = self.activeTextField.text;
    urlStr = [self smartURLStringForString:finalString];
    if (urlStr != nil) {
        finalString = urlStr;
        self.activeTextField.text = finalString;
    }
    self.otherChoice = finalString;

    // Undo two of the three things done in -textFieldDidBeginEditing:.  It's not 
    // necessary to undo the last one; whether we choose a row other than the "other" 
    // row is determined by other factors.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.activeTextField];
    self.activeTextField = nil;
}

- (void)textFieldDidChange:(NSNotification *)note
    // As the text field in the "other" row changes, reflect that change to our 
    // otherChoice property, which updates the Save button state via KVO.
{
    assert([note object] == self.activeTextField);
    #pragma unused(note)
    self.otherChoice = self.activeTextField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self saveAction:textField];
    return NO;
}

#pragma mark * Actions

- (IBAction)saveAction:(id)sender
    // Called when the user taps the Save button.
{
    #pragma unused(sender)
    NSString *          value;
    NSMutableArray *    newChoices;
    
    // The following is necessary to flush the final URL string out to self.otherChoice.
    
    if (self.activeTextField != nil) {
        [self.activeTextField resignFirstResponder];
    }
    
    // Get the value we're going to save.
    
    value = [self effectiveChoice];
    assert(value != nil);               // Save should be disabled in this case.
    
    // If the value is from the "other" field, add it to the choices array 
    // (if appropriate).
    
    newChoices = [[self.choices mutableCopy] autorelease];
    assert(newChoices != nil);
    
    if (self.choiceIndex == [self.choices count]) {
        if ([value length] != 0) {                          // don't add the empty string
            if ( ! [self.choices containsObject:value] ) {  // don't repeat an existing value
                [newChoices addObject:value];
                self.choicesDirty = YES;
            }
        }
    }
    
    // If the choices list is dirty, save it back to the user defaults.
    
    if (self.choicesDirty) {
        [[NSUserDefaults standardUserDefaults] setObject:newChoices forKey:@"setupChoices"];
        self.choicesDirty = NO;
    }

    // Commit the choice of gallery to the network manager.  This triggers a world 
    // of reconfiguration via KVO.
    
    [self.delegate setupViewController:self didChooseString:value];
}

- (IBAction)cancelAction:(id)sender
    // Called when the user taps the Cancel button.  We just tell our delegate about it.
{
    #pragma unused(sender)
    [self.delegate setupViewControllerDidCancel:self];
}

- (void)presentModallyOn:(UIViewController *)parent animated:(BOOL)animated
{
    UINavigationController *    navController;
    
    navController = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    assert(navController != nil);

    self.navigationItem.title = @"Setup";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave   target:self action:@selector(saveAction:)  ] autorelease];
    self.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)] autorelease];

    [parent presentModalViewController:navController animated:animated];
}

@end
