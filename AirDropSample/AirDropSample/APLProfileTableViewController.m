/*
 
     File: APLProfileTableViewController.m
 Abstract: View controller to handle listing all instances of the custom APLProfile class.
  Version: 1.0
 
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

#import "APLAppDelegate.h"
#import "APLProfileTableViewController.h"
#import "APLProfileViewController.h"
#import "APLProfile.h"
#import "APLUtilities.h"

NSString * const kProfileTableViewCellIdentifier = @"Cell";

NSString * const kTemplateImageName = @"Image_Template.png";
NSString * const kSampleProfileImageName = @"Zebra.png";
NSString * const kProfileDetailSegueIdentifier = @"ProfileDetailSegue";

@interface APLProfileTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *tableContents;    //Stores the profiles

@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (strong, nonatomic) UIBarButtonItem *addButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

@end

@implementation APLProfileTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Profiles";
    
    //Set up buttons to allow editing of tableview rows.
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProfile:)];
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editTable:)];
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTable:)];
    [self.navigationItem setRightBarButtonItem:self.editButton];
    
    //Set up sample profile.
    UIImage *image = [UIImage imageNamed:kSampleProfileImageName];
    APLProfile *profile = [[APLProfile alloc] initWithName:@"Zebra" image:image];
    
    //Initialize tableContents array with the sample profile and any profiles stored by the app.
    self.tableContents = [[NSMutableArray alloc] initWithArray:@[profile]];
    [self.tableContents addObjectsFromArray:[APLUtilities loadProfiles]];
    
    //Register to be notified when new profiles are received.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profilesSaved:) name:SavedReceivedProfilesNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SavedReceivedProfilesNotification object:nil];
}


#pragma mark - UITableViewDataSource and UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Return the number of profiles stored.
    return [self.tableContents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileTableViewCellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSInteger row = [indexPath row];
    
    if (row >= 0 && row < [self.tableContents count]){
        //Cell shows the profile image and name.
        cell.imageView.image = [(APLProfile *)self.tableContents[row] thumbnailImage];
        cell.textLabel.text = [(APLProfile *)self.tableContents[row] name];
    }
    else {
        NSLog(@"ERROR: indexPath out of range");
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) { //Do not let the sample profile (index 0) be deleted.
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row > 0 && indexPath.row < self.tableContents.count) {
            
            APLProfile *profile = [self.tableContents objectAtIndex:indexPath.row];
            [self.tableContents removeObjectAtIndex:indexPath.row];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            //Delete the persisted profile file.
            [APLUtilities deleteProfile:profile];
        }
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = [segue identifier];
    
    if ([identifier isEqualToString:kProfileDetailSegueIdentifier]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        APLProfileViewController *profileViewController = [segue destinationViewController];
        
        profileViewController.profile = (APLProfile *)[self.tableContents objectAtIndex:indexPath.row];

        //The tableview will monitor when the profile updates.
        profileViewController.delegate = self;
        
        //The profiles should be editable/sharable.
        profileViewController.interactive = YES;
    }
}
     
#pragma mark - Actions

- (void)editTable:(id)sender
{
    //Update navigation items when editing buttons (Edit or Done) are pressed.
    if (self.tableView.isEditing) {
        [self.tableView setEditing:NO animated:YES];
        [self.navigationItem setRightBarButtonItem:self.editButton];
        [self.navigationItem setLeftBarButtonItem:nil];
    }
    else
    {
        [self.tableView setEditing:YES animated:YES];
        [self.navigationItem setRightBarButtonItem:self.doneButton];
        [self.navigationItem setLeftBarButtonItem:self.addButton];
    }
}

- (void)addProfile:(id)sender
{
    //Create a template profile.
    UIImage *image = [UIImage imageNamed:kSampleProfileImageName];
    APLProfile *profile = [[APLProfile alloc] initWithName:@"Zebra" image:image];
    
    //Manually load the view controller.
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kMainStoryboardName bundle:nil];
    APLProfileViewController *profileViewController = [sb instantiateViewControllerWithIdentifier:kProfileViewControllerIdentifier];
    
    //Set up view controller to be editable and delagate to this table view controller.
    profileViewController.delegate = self;
    profileViewController.profile = profile;
    profileViewController.interactive = YES;
    
    //Push the new view controller onto the stack.
    [self.navigationController pushViewController:profileViewController animated:YES];
    
    //Turn off table view editing.
    if (self.tableView.isEditing) {
        [self editTable:self];
    }
    
    //Add the profile to the table.
    [self.tableContents addObject:profile];
    [self.tableView reloadData];
    
    //Save new profile to persistent file.
    [APLUtilities saveProfile:profile];
}

- (void)profilesSaved:(NSNotification *)notification
{
    NSArray *filenames = [[notification userInfo] objectForKey:kSavedReceivedProfilesFileNamesKey];
    
    for (NSString *filename in filenames) {
        APLProfile *profile = [APLUtilities loadProfileForFilename:filename];
        
        if (profile) {
            [self.tableContents addObject:profile];
        }
    }
    
    [self.tableView reloadData];
}


#pragma mark - ProfileViewControllerDelgate

- (void)profileViewController:(APLProfileViewController *)profileViewController profileDidChange:(APLProfile *)profile
{
    [APLUtilities saveProfile:profile];
    [self.tableView reloadData];
}

@end
