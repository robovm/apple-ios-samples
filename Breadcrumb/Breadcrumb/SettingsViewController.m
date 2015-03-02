/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "SettingsViewController.h"

@import MapKit;

NSString * const TrackLocationInBackgroundPrefsKey  = @"TrackLocationInBackgroundPrefsKey"; // BOOL
NSString * const LocationTrackingAccuracyPrefsKey   = @"LocationTrackingAccuracyPrefsKey";  // CLLocationAccuracy (double)
NSString * const PlaySoundOnLocationUpdatePrefsKey  = @"PlaySoundOnLocationUpdatePrefsKey"; // BOOL

// table cell identifiers
NSString * const SwitchOptionCellID = @"SwitchOptionTableViewCell"; // generic switch cell
NSString * const PickerOptionCellID = @"PickerOptionTableViewCell"; // generic picker cell


#pragma mark -

@interface AccuracyPickerOption : NSObject

@property (nonatomic, copy) NSString *headline;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *defaultsKey;

@end

@implementation AccuracyPickerOption

+ (instancetype)withHeadline:(NSString *)description details:(NSString *)details defaultsKey:(NSString *)defaultsKey
{
    NSParameterAssert(description != nil);
    NSParameterAssert(defaultsKey != nil);
    
    AccuracyPickerOption *option = [AccuracyPickerOption new];
    option.headline = description;
    option.details = details;
    option.defaultsKey = defaultsKey;
    
    return option;
}

@end


#pragma mark -

@interface SwitchOption : NSObject

@property (nonatomic, copy) NSString *headline;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *defaultsKey;

@end

@implementation SwitchOption

+ (instancetype)withHeadline:(NSString *)description details:(NSString *)details defaultsKey:(NSString *)defaultsKey
{
    NSParameterAssert(description != nil);
    NSParameterAssert(details != nil);
    NSParameterAssert(defaultsKey != nil);
    
    SwitchOption *option = [SwitchOption new];
    option.headline = description;
    option.details = details;
    option.defaultsKey = defaultsKey;
    
    return option;
}

@end


#pragma mark -

@interface SwitchOptionTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UISwitch *switchControl;
@property (nonatomic, copy) NSString *defaultsKey;

@end


#pragma mark -

@implementation SwitchOptionTableViewCell

- (void)configureWithOptions:(SwitchOption *)options
{
    self.titleLabel.text = options.headline;
    self.defaultsKey = options.defaultsKey;
    self.detailsLabel.text = options.details;
    self.switchControl.on = (BOOL)[[NSUserDefaults standardUserDefaults] boolForKey:self.defaultsKey];
}

// called from "toggleSwitch" - user changes a setting that uses UISwitch to change its settings
//
- (IBAction)updatePreferencesFromView:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:self.switchControl.isOn forKey:self.defaultsKey];
}

- (IBAction)toggleSwitch:(id)sender
{
    // one of the UISwitch-based preference has changed
    UISwitch *aSwitch = self.switchControl;
    BOOL newState = aSwitch.isOn;
    [aSwitch setOn:newState animated:YES];
    [self updatePreferencesFromView:aSwitch];
}

@end


#pragma mark -

@interface PickerOptionTableViewCell : UITableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, copy) NSString *defaultsKey;

@end


#pragma mark -

@implementation PickerOptionTableViewCell

- (void)configureWithOptions:(AccuracyPickerOption *)options
{
    self.titleLabel.text = options.headline;
    self.defaultsKey = options.defaultsKey;
    self.detailsLabel.text = options.details;
    
    // set the picker to match the value of the default CLLocationAccuracy
    NSNumber *accuracyNum = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:self.defaultsKey];
    CLLocationAccuracy accuracy = [accuracyNum doubleValue];
    
    NSInteger row = 0;
    if (accuracy == kCLLocationAccuracyBestForNavigation)
    {
        row = 0;
    }
    else if (accuracy == kCLLocationAccuracyBest)
    {
        row = 1;
    }
    else if (accuracy == kCLLocationAccuracyNearestTenMeters)
    {
        row = 2;
    }
    else if (accuracy == kCLLocationAccuracyHundredMeters)
    {
        row = 3;
    }
    else if (accuracy == kCLLocationAccuracyKilometer)
    {
        row = 4;
    }
    else if (accuracy == kCLLocationAccuracyThreeKilometers)
    {
        row = 5;
    }

    [self.pickerView selectRow:row inComponent:0 animated:NO];
}

// returns the number of 'columns' to display on the picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the number of rows in the first component of the picker
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 6;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 18.0;
}

// keys to describe the NSDictionary returned from accuracyTitleAndValueForRow
#define kAccuracyTitleKey @"accuracyTitle"
#define kAccuracyValueKey @"accuracyValue"

- (NSDictionary *)accuracyTitleAndValueForRow:(NSInteger)row
{
    NSString *title = @"";
    CLLocationAccuracy accuracyValue = -1;
    
    switch (row)
    {
        case 0:
            title = @"kCLLocationAccuracyBestForNavigation";
            accuracyValue = kCLLocationAccuracyBestForNavigation;
            break;
        case 1:
            title = @"kCLLocationAccuracyBest";
            accuracyValue = kCLLocationAccuracyBest;
            break;
        case 2:
            title = @"kCLLocationAccuracyNearestTenMeters";
            accuracyValue = kCLLocationAccuracyNearestTenMeters;
            break;
        case 3:
            title = @"kCLLocationAccuracyHundredMeters";
            accuracyValue = kCLLocationAccuracyHundredMeters;
            break;
        case 4:
            title = @"kCLLocationAccuracyKilometer";
            accuracyValue = kCLLocationAccuracyKilometer;
            break;
        case 5:
            title = @"kCLLocationAccuracyThreeKilometers";
            accuracyValue = kCLLocationAccuracyThreeKilometers;
            break;
    }
    
    return @{kAccuracyTitleKey: title, kAccuracyValueKey: [NSNumber numberWithDouble:accuracyValue]};
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *customView = (UILabel *)view;
    if (customView == nil)
    {
        customView = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    
    // find the accuracy title for the given row
    NSDictionary *resultDict = [self accuracyTitleAndValueForRow:row];
    NSString *title = resultDict[kAccuracyTitleKey];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:title];
    UIFont *font = [UIFont systemFontOfSize:12];
    [attrString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, title.length)];

    customView.attributedText = attrString;
    customView.textAlignment = NSTextAlignmentCenter;
    
    return customView;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // find the accuracy value from the selected row
    NSDictionary *resultDict = [self accuracyTitleAndValueForRow:row];
    CLLocationAccuracy accuracy = [resultDict[kAccuracyValueKey] doubleValue];
    
    // this will cause an NSNotification to occur (NSUserDefaultsDidChangeNotification)
    // ultimately calling BreadcrumbViewController - (void)settingsDidChange:(NSNotification *)notification
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:accuracy forKey:LocationTrackingAccuracyPrefsKey];
}

@end


#pragma mark -

@interface SettingsViewController ()

@property (nonatomic, copy) NSArray *settings;

@end


@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settings = @[
                      [SwitchOption withHeadline:NSLocalizedString(@"Background Updates:", @"Label for switch that enables and disables background updates")
                                         details:NSLocalizedString(@"Turn on/off tracking current location while suspended.", @"Description for switch that enables and disables background updates")
                                     defaultsKey:TrackLocationInBackgroundPrefsKey],
                      
                      [AccuracyPickerOption withHeadline:@"Accuracy:"
                                         details:NSLocalizedString(@"Set level of accuracy when tracking your location.", @"Description for accuracy")
                                     defaultsKey:LocationTrackingAccuracyPrefsKey],
                      
                      [SwitchOption withHeadline:@"Audio Feedback:"
                                         details:@"Play a sound when a new location update is received."
                                     defaultsKey:PlaySoundOnLocationUpdatePrefsKey],
                      ];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 0.0;
    
    id option = self.settings[indexPath.row];
    
    if ([option isKindOfClass:[AccuracyPickerOption class]])
    {
        cellHeight = 213.00;    // cell height for the accuracy cell (with UIPickerView)
    }
    if ([option isKindOfClass:[SwitchOption class]])
    {
        cellHeight = 105.0;     // cell height for the switch cell
    }
    return cellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.settings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id option = self.settings[indexPath.row];
    
    UITableViewCell *cell = nil;
    
    if ([option isKindOfClass:[AccuracyPickerOption class]])
    {
        PickerOptionTableViewCell *pickerCell = (PickerOptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:PickerOptionCellID];
        
        AccuracyPickerOption *pickerOption = option;
        [pickerCell configureWithOptions:pickerOption];
        cell = pickerCell;
    }
    if ([option isKindOfClass:[SwitchOption class]])
    {
        SwitchOptionTableViewCell *switchCell = (SwitchOptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SwitchOptionCellID];
        
        SwitchOption *switchOption = option;
        [switchCell configureWithOptions:switchOption];
        cell = switchCell;
    }
    
    return cell;
}

@end
