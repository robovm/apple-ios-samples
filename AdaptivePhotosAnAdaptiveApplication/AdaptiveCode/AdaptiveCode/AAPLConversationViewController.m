/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows the contents of a conversation.
 */

#import "AAPLConversationViewController.h"
#import "AAPLConversation.h"
#import "AAPLPhoto.h"
#import "AAPLPhotoViewController.h"
#import "UIViewController+AAPLPhotoContents.h"
#import "UIViewController+AAPLViewControllerShowing.h"

NSString *const AAPLConversationViewControllerCellIdentifier = @"PhotoCell";

@implementation AAPLConversationViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.clearsSelectionOnViewWillAppear = NO;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [self init];
    
    if (self) {
        // No need to customize here...
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewControllerShowDetailTargetDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:AAPLConversationViewControllerCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDetailTargetDidChange:) name:UIViewControllerShowDetailTargetDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        BOOL indexPathPushes = [self aapl_willShowingDetailViewControllerPushWithSender:self];
        if (indexPathPushes) {
            // If we're pushing for this indexPath, deselect it when we appear.
            [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
        }
    }
    
    AAPLPhoto *visiblePhoto = [self aapl_currentVisibleDetailPhotoWithSender:self];
    if (visiblePhoto) {
        for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
            AAPLPhoto *photo = [self photoForIndexPath:indexPath];
            if (photo == visiblePhoto) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}
    
// This method is originally declared in the AAPLPhotoContents category on UIViewController.
- (BOOL)aapl_containsPhoto:(AAPLPhoto *)photo
{
    return [self.conversation.photos containsObject:photo];
}

- (void)showDetailTargetDidChange:(NSNotification *)notification
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self tableView:self.tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

#pragma mark - Table view

- (AAPLPhoto *)photoForIndexPath:(NSIndexPath *)indexPath
{
    return self.conversation.photos[indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.conversation.photos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:AAPLConversationViewControllerCellIdentifier forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL pushes = [self aapl_willShowingDetailViewControllerPushWithSender:self];
    
    // Only show a disclosure indicator if we're pushing.
    if (pushes) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    AAPLPhoto *photo = [self photoForIndexPath:indexPath];
    cell.textLabel.text = photo.comment;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLPhoto *photo = [self photoForIndexPath:indexPath];
    AAPLPhotoViewController *controller = [[AAPLPhotoViewController alloc] init];
    controller.photo = photo;
    NSUInteger photoNumber = indexPath.row + 1;
    NSUInteger photoCount = self.conversation.photos.count;
    controller.title = [NSString stringWithFormat:NSLocalizedString(@"%ld of %ld", @"%ld of %ld"), photoNumber, photoCount];
    
    // Show the photo as the detail (if possible).
    [self showDetailViewController:controller sender:self];
}

@end
