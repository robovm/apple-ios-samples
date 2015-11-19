/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller allows you to enter the title, proximity, and geofence's radius for a new location-based reminder.
 */

#import "EKRSConstants.h"
#import "AddLocationReminder.h"

@interface AddLocationReminder ()
@property (weak, nonatomic) IBOutlet UITextField *radiusLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *proximitySegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressName;

@end

@implementation AddLocationReminder

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Display the name and address of the location associated with this new reminder
    self.nameLabel.text = [ NSString stringWithFormat:@"Location: %@", self.name];
    self.addressName.text = self.address;
}


#pragma mark - Handle User Text Input

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // When the user presses return, take focus away from the text field so
    // that the keyboard is dismissed.
    [textField resignFirstResponder];
    if (((self.titleTextField.text).length > 0) && ((self.radiusLabel.text).length > 0))
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    return YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"unwindToMapViewController"])
    {
        // Fetch the proximity value, which is either Arriving (EKAlarmProximityEnter) or Leaving (EKAlarmProximityLeave)
        NSString *proximity = [self.proximitySegmentControl titleForSegmentAtIndex:(self.proximitySegmentControl).selectedSegmentIndex];
        // Return the entered title, proximity, and radius
        self.userInput = @{EKRSTitle: self.titleTextField.text, EKRSLocationProximity:proximity, EKRSLocationRadius:@((self.radiusLabel.text).doubleValue)};
    }
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
