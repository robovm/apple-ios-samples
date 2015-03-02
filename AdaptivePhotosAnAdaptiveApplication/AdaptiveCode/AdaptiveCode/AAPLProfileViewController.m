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

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *conversationsLabel;
@property (strong, nonatomic) UILabel *photosLabel;

// Holds the current constraints used to position the subviews.
@property (copy, nonatomic) NSArray *constraints;

@end

@implementation AAPLProfileViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Profile", @"Profile");
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.imageView];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.nameLabel];
    
    self.conversationsLabel = [[UILabel alloc] init];
    self.conversationsLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.conversationsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.conversationsLabel];
    
    self.photosLabel = [[UILabel alloc] init];
    self.conversationsLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.photosLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.photosLabel];
    
    self.view = view;
    [self updateUser];
    [self updateConstraintsForTraitCollection:self.traitCollection];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        [self updateConstraintsForTraitCollection:newCollection];
        [self.view setNeedsLayout];
    } completion:nil];
}

// Applies the proper constraints to the subviews for the size class of the given trait collection.
- (void)updateConstraintsForTraitCollection:(UITraitCollection *)collection
{
    NSDictionary *views = @{
        @"topLayoutGuide": self.topLayoutGuide,
        @"imageView": self.imageView,
        @"nameLabel": self.nameLabel,
        @"conversationsLabel": self.conversationsLabel,
        @"photosLabel": self.photosLabel
    };
    
    NSMutableArray *newConstraints = [NSMutableArray array];
    
    if (collection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"|[imageView]-[nameLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints1];
        
        NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"[imageView]-[conversationsLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints2];
        
        NSArray *constraints3 = [NSLayoutConstraint constraintsWithVisualFormat:@"[imageView]-[photosLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints3];
        
        NSArray *constraints4 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide]-[nameLabel]-[conversationsLabel]-[photosLabel]" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints4];
        
        NSArray *constraints5 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][imageView]|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints5];

        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0.0];
        [newConstraints addObject:constraint];
    } else {
        NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"|[imageView]|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints1];

        NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[nameLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints2];
        
        NSArray *constraints3 = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[conversationsLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints3];

        NSArray *constraints4 = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[photosLabel]-|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints4];

        NSArray *constraints5 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-[nameLabel]-[conversationsLabel]-[photosLabel]-20-[imageView]|" options:0 metrics:nil views:views];
        [newConstraints addObjectsFromArray:constraints5];
    }
    if (self.constraints) {
        [NSLayoutConstraint deactivateConstraints:self.constraints];
    }

    // Remember the current constraints. This allows us to remove the existing constraints before creating new ones appropriate for the current vertical size class.
    self.constraints = newConstraints;
    [NSLayoutConstraint activateConstraints:self.constraints];
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
