/*
     File: SettingsController.m
 Abstract: The view controller for the Settings view.
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

#import "SettingsController.h"
#import <AVFoundation/AVFoundation.h>
#import "FHViewController.h"


NSString *const kFHSettingCameraPositionKey = @"CameraPosition";
NSString *const kFHSettingCaptureSessionPresetKey = @"CaptureSessionPreset";
NSString *const kFHSettingColorMatchKey = @"ColorMatch";
NSString *const kFHSettingDidUpdateNotification = @"kFHSettingDidUpdateNotification";
NSString *const kFHSettingUpdatedKeyNameKey = @"Key";
NSString *const kFHFilterImageAttributeSourceDidChangeNotification = @"FHFilterImageAttributeSourceDidChangeNotification";

static void FCApplyDefaultSettings(BOOL reset)
{
    NSUserDefaults* dftls = [NSUserDefaults standardUserDefaults];
    
    if (reset || ![dftls objectForKey:kFHSettingCameraPositionKey])
    {
        [dftls setObject:[NSNumber numberWithInteger:AVCaptureDevicePositionBack] forKey:kFHSettingCameraPositionKey];
    }
    
    if (reset || ![dftls objectForKey:kFHSettingCaptureSessionPresetKey])
    {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
            [dftls setObject:AVCaptureSessionPresetHigh forKey:kFHSettingCaptureSessionPresetKey];
        else
            [dftls setObject:AVCaptureSessionPreset640x480 forKey:kFHSettingCaptureSessionPresetKey];
    }
}

void FCPopulateDefaultSettings(void)
{
    FCApplyDefaultSettings(NO);
}



enum {
    kSettingsCameraPositionGroup,
    kSettingCapturePresetGroup,
    kSettingColorMatchGroup,
    kSettingGroupCount
};

#define IntObj(x)	([NSNumber numberWithInteger:x])
#define SetData(dict, key, ...) [dict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__] forKey:key]

static NSString *kTitleKey = @"Title";
static NSString *kEnabledKey = @"Enabled";

@interface SettingsController (PrivateMethods)
- (void)_dismissAction;
- (void)_resetAction;
- (void)_handleCaptureSessionDidStart:(NSNotification *)notification;
- (void)_validateSettings;
@end

@implementation SettingsController
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // populate default settings
        FCPopulateDefaultSettings();
        
        _cameraPositions = @[ @(AVCaptureDevicePositionBack), @(AVCaptureDevicePositionFront) ];
        _cameraPositionData = [[NSMutableDictionary alloc] init];
        SetData(_cameraPositionData, @(AVCaptureDevicePositionBack), @"Back", kTitleKey, nil);
        SetData(_cameraPositionData, @(AVCaptureDevicePositionFront), @"Front", kTitleKey, nil);

        _presets = @[ AVCaptureSessionPresetMedium, AVCaptureSessionPresetHigh ];
        _presetsData = [[NSMutableDictionary alloc] init];
        SetData(_presetsData, AVCaptureSessionPresetMedium, @"Medium", kTitleKey, nil);
        SetData(_presetsData, AVCaptureSessionPresetHigh, @"High", kTitleKey, nil);
        
        _colorMatchModes = @[ @NO, @YES ];
        _colorMatchData = [[NSMutableDictionary alloc] init];
        SetData(_colorMatchData, @NO, @"Disabled", kTitleKey, nil);
        SetData(_colorMatchData, @YES, @"Enabled", kTitleKey, nil);
        
        // Disable by default
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFHSettingColorMatchKey];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_handleCaptureSessionDidStart:)
                                                     name:FHViewControllerDidStartCaptureSessionNotification
                                                   object:nil];
        
        [self _validateSettings];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone))
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(_dismissAction)];
    
    self.title = @"Settings";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSettingGroupCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kSettingsCameraPositionGroup: return [_cameraPositions count];
        case kSettingCapturePresetGroup: return [_presets count];
        case kSettingColorMatchGroup: return [_colorMatchData count];
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kSettingsCameraPositionGroup: return @"Camera Position";
        case kSettingCapturePresetGroup: return @"Preset";
        case kSettingColorMatchGroup: return @"Color Management";
        default: return @"(Invalid)";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    // Configure the cell...
    id item;
    NSArray *modes = nil;
    NSDictionary *data;
    NSString *key;
    
    switch (indexPath.section) {
        case kSettingsCameraPositionGroup:
            modes = _cameraPositions;
            data = _cameraPositionData;
            key = kFHSettingCameraPositionKey;
            break;
        case kSettingCapturePresetGroup:
            modes = _presets;
            data = _presetsData;
            key = kFHSettingCaptureSessionPresetKey;
            break;
        case kSettingColorMatchGroup:
            modes = _colorMatchModes;
            data = _colorMatchData;
            key = kFHSettingColorMatchKey;
            break;
        default:
            break;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
        
    if (modes)
    {
        item = [modes objectAtIndex:indexPath.row];
        cell.textLabel.text = [[data objectForKey:item] objectForKey:kTitleKey]; 
        
        BOOL enabled = [[[data objectForKey:item] objectForKey:kEnabledKey] boolValue];
        if (enabled)
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:key] isEqual:item])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;

            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        else
        {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *modes = nil;
    NSDictionary *data;
    
    switch (indexPath.section) {
        case kSettingsCameraPositionGroup:
            modes = _cameraPositions;
            data = _cameraPositionData;
            break;
        case kSettingCapturePresetGroup:
            modes = _presets;
            data = _presetsData;
            break;
        case kSettingColorMatchGroup:
            modes = _colorMatchModes;
            data = _colorMatchData;
            break;
        default:
            break;
    }
    
    BOOL enabled = [[[data objectForKey:[modes objectAtIndex:indexPath.row]] objectForKey:kEnabledKey] boolValue];
    return enabled ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    id item;
    NSUInteger oldRow;
    NSUInteger newRow;
    
    NSString *key;
    NSArray *array;
    
    switch (indexPath.section) {
        case kSettingsCameraPositionGroup:
            key = kFHSettingCameraPositionKey;
            array = _cameraPositions;
            break;
        case kSettingCapturePresetGroup:
            key = kFHSettingCaptureSessionPresetKey;
            array = _presets;
            break;
        case kSettingColorMatchGroup:
            key = kFHSettingColorMatchKey;
            array = _colorMatchModes;
            break;
        default:
            break;
    }

    item = [array objectAtIndex:indexPath.row];
    oldRow = [array indexOfObject:[userDefaults objectForKey:key]];
    newRow = [array indexOfObject:item];
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:oldRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:newRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryCheckmark;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (![[userDefaults objectForKey:key] isEqual:item])
        [userDefaults setObject:item forKey:key];
    else 
        return;
    
    
    if (indexPath.section == kSettingsCameraPositionGroup)
        [self _validateSettings];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:key, kFHSettingUpdatedKeyNameKey, nil];    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFHSettingDidUpdateNotification object:nil userInfo:userInfo];
    
    self.title = @"Applying...";
    self.tableView.userInteractionEnabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

#pragma mark - Private methods

- (void) _dismissAction
{
    [self.delegate settingsDidDismiss];    
}

- (void) _handleCaptureSessionDidStart:(NSNotification *)notification
{
    [self.tableView reloadData];
    
    self.title = @"Settings";
    self.tableView.userInteractionEnabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void) _validateSettings
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    AVCaptureDevicePosition position = [userDefaults integerForKey:kFHSettingCameraPositionKey];
    AVCaptureDevice *videoDevice = nil;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];        
    for (AVCaptureDevice *device in videoDevices)
    {
        [[_cameraPositionData objectForKey:[NSNumber numberWithInteger:device.position]] setObject:@YES forKey:kEnabledKey];
        
        if (device.position == position)
            videoDevice = device;
    }

    if (!videoDevice)
        return;
    
    for (NSString *preset in _presets)
        [[_presetsData objectForKey:preset] setObject:[NSNumber numberWithBool:[videoDevice supportsAVCaptureSessionPreset:preset]]
                                               forKey:kEnabledKey];
    
    for (NSString *key in _colorMatchData)
        [[_colorMatchData objectForKey:key] setObject:@YES
                                               forKey:kEnabledKey];
}

@end
