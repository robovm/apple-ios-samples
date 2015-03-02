/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a list of conversations that can be viewed.
 */

#import "AAPLListTableViewController.h"
#import "AAPLConversation.h"
#import "AAPLConversationViewController.h"
#import "AAPLPhotoViewController.h"
#import "AAPLProfileViewController.h"
#import "AAPLUser.h"
#import "UIViewController+AAPLViewControllerShowing.h"

@implementation AAPLListTableViewController

#pragma mark - View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDetailTargetDidChange:) name:UIViewControllerShowDetailTargetDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        BOOL pushes;
        if ([self shouldShowConversationViewForIndexPath:indexPath]) {
            pushes = [self aapl_willShowingViewControllerPushWithSender:self];
        } else {
            pushes = [self aapl_willShowingDetailViewControllerPushWithSender:self];
        }
        if (pushes) {
            // If we're pushing for this indexPath, deselect it when we appear.
            [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
        }
    }
}

#pragma mark - Properties

- (void)showDetailTargetDidChange:(NSNotification *)notification
{
    // Whenever the target for showDetailViewController: changes, update all of our cells (to ensure they have the right accessory type).
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self tableView:self.tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

// This method is originally declared in the AAPLPhotoContents category on UIViewController.
- (BOOL)aapl_containsPhoto:(AAPLPhoto *)photo
{
    return YES;
}

// Custom implementation of the setter for the user property. When this property is set, the tableView will be reloaded with the conversations for the new user.
- (void)setUser:(AAPLUser *)user
{
    if (_user != user) {
        _user = user;
        
        if ([self isViewLoaded]) {
            [self.tableView reloadData];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AAPLConversation *conversation = [self conversationForIndexPath:self.tableView.indexPathForSelectedRow];
    
    if ([segue.identifier isEqualToString:@"ShowConversation"]) {
        AAPLConversationViewController *destination = segue.destinationViewController;
        destination.conversation = conversation;
        destination.title = conversation.name;
    } else if ([segue.identifier isEqualToString:@"ShowPhoto"]) {
        AAPLPhotoViewController *destination = segue.destinationViewController;
        AAPLPhoto *photo = [conversation.photos lastObject];
        destination.photo = photo;
        destination.title = conversation.name;
    } else if ([segue.identifier isEqualToString:@"ShowProfile"]) {
        AAPLProfileViewController *destination = (AAPLProfileViewController*)[segue.destinationViewController topViewController];
        destination.user = self.user;
    }
}

#pragma mark - Table view

- (AAPLConversation *)conversationForIndexPath:(NSIndexPath *)indexPath
{
    return self.user.conversations[indexPath.row];
}

// Returns whether the conversation at indexPath contains more than one photo.
- (BOOL)shouldShowConversationViewForIndexPath:(NSIndexPath *)indexPath
{
    AAPLConversation *conversation = [self conversationForIndexPath:indexPath];
    return conversation.photos.count > 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.user.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldShowConversationViewForIndexPath:indexPath]) {
        return [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
    } else {
        return [tableView dequeueReusableCellWithIdentifier:@"PhotoCell" forIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Whether to show the disclosure indicator for this cell.
    BOOL pushes;
    if ([self shouldShowConversationViewForIndexPath:indexPath]) {
        // If the conversation corresponding to this row has multiple photos.
        pushes = [self aapl_willShowingViewControllerPushWithSender:self];
    } else {
        // If the conversation corresponding to this row has a single photo.
        pushes = [self aapl_willShowingDetailViewControllerPushWithSender:self];
    }
    
    // Only show a disclosure indicator if selecting this cell will trigger a push in the master view controller (the navigation controller above ourself).
    if (pushes) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    AAPLConversation *conversation = [self conversationForIndexPath:indexPath];
    cell.textLabel.text = conversation.name;
}

@end
