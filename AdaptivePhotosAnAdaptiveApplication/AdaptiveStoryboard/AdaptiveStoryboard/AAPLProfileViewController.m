/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a user's profile.
 */

#import "AAPLProfileViewController.h"
#import "AAPLConversation.h"
#import "AAPLPhoto.h"
#import "AAPLUser.h"

@interface AAPLProfileViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *conversationsLabel;
@property (strong, nonatomic) IBOutlet UILabel *photosLabel;

@end

@implementation AAPLProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUser];
}

- (IBAction)closeProfile:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Custom implementation of the setter for the user property. Updates the labels and image view with the data from the new user.
- (void)setUser:(AAPLUser *)user
{
    if (_user != user) {
        _user = user;
        if ([self isViewLoaded]) {
            [self updateUser];
        }
    }
}

// Updates the user interface with the data from the current user object.
- (void)updateUser
{
    self.nameLabel.text = self.nameText;
    self.conversationsLabel.text = self.conversationsText;
    self.photosLabel.text = self.photosText;
    self.imageView.image = self.user.lastPhoto.image;
}

- (NSString *)nameText
{
    return self.user.name;
}

- (NSString *)conversationsText
{
    return [NSString stringWithFormat:NSLocalizedString(@"%ld conversations", @"%ld conversations"), self.user.conversations.count];
}

- (NSString *)photosText
{
    NSNumber *photoCount = [self.user valueForKeyPath:@"conversations.photos.@sum.@count"];
    return [NSString stringWithFormat:NSLocalizedString(@"%ld photos", @"%ld photos"), photoCount.integerValue];
}

@end
