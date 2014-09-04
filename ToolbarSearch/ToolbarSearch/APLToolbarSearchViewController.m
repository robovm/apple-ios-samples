/*
     File: APLToolbarSearchViewController.m 
 Abstract: A view controller that manages a search bar and a recent searches controller.
 When the user commences a search, a recent searches controller is displayed in a popover. 
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

#import "APLToolbarSearchViewController.h"
#import "APLRecentSearchesController.h"

@interface APLToolbarSearchViewController ()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;

@property (nonatomic) APLRecentSearchesController *recentSearchesController;
@property (nonatomic) UIPopoverController *recentSearchesPopoverController;

@end


#pragma mark -

@implementation APLToolbarSearchViewController


#pragma mark - RecentSearchesDelegate

- (void)recentSearchesController:(APLRecentSearchesController *)controller didSelectString:(NSString *)searchString {
    
    // The user selected a row in the recent searches list (UITableView).
    // Set the text in the search bar to the search string, and conduct the search.
    self.searchBar.text = searchString;
    [self finishSearchWithString:searchString];
}


#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
    
    // Create the popover if it is not already open.
    if (self.recentSearchesPopoverController == nil) {

        // Use the storyboard to instantiate a navigation controller that contains a recent searches controller.
        UINavigationController *navigationController = [[self storyboard] instantiateViewControllerWithIdentifier:@"PopoverNavigationController"];

        self.recentSearchesController = (APLRecentSearchesController *)[navigationController topViewController];
        self.recentSearchesController.delegate = self;
        
        // Create the popover controller to contain the navigation controller.
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        popover.delegate = self;
        
        // Ensure the popover is not dismissed if the user taps in the search bar by adding
        // the search bar to the popover's list of pass-through views.
        popover.passthroughViews = @[self.searchBar];
        
        self.recentSearchesPopoverController = popover;
    }
    
    // Display the popover.
    [self.recentSearchesPopoverController presentPopoverFromRect:[self.searchBar bounds] inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar {
    
    // If the user finishes editing text in the search bar by, for example: tapping away
    // rather than selecting from the recents list, then just dismiss the popover,
    // but only if its confirm UIActionSheet is not open (UIActionSheets can take away
    // first responder from the search bar when first opened).
    //
    if (self.recentSearchesPopoverController != nil) {
        
        if (self.recentSearchesController.confirmSheet == nil) {
            [self.recentSearchesPopoverController dismissPopoverAnimated:YES];
            self.recentSearchesPopoverController = nil;
        }
    }    
    [aSearchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    // When the search string changes, filter the recents list accordingly.
    [self.recentSearchesController filterResultsUsingString:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    
    // When the search button is tapped, add the search term to recents and conduct the search.
    NSString *searchString = [self.searchBar text];
    [self.recentSearchesController addToRecentSearches:searchString];
    [self finishSearchWithString:searchString];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    // Remove focus from the search bar without committing the search.
    self.progressLabel.text = NSLocalizedString(@"Canceled a search.", @"canceled search string for the progress label");
    self.recentSearchesPopoverController = nil;
    [self.searchBar resignFirstResponder];
}


#pragma mark - Finish the search

- (void)finishSearchWithString:(NSString *)searchString {
    
    // Conduct the search. In this case, simply report the search term used.
    [self.recentSearchesPopoverController dismissPopoverAnimated:YES];
    self.recentSearchesPopoverController = nil;
    NSString *formatString = NSLocalizedString(@"Performed a search using \"%@\".", @"format string for reporting search performed");
    self.progressLabel.text = [NSString stringWithFormat:formatString, searchString];
    [self.searchBar resignFirstResponder];
}

@end
