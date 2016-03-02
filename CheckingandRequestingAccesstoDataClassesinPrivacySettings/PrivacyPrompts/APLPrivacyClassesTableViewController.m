/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Tableview controller that displays all the privacy data classes in the system.
 */

@import EventKit;
@import Contacts;
@import Accounts;
@import AdSupport;
@import Photos;
@import AVFoundation;
@import CoreMotion;
@import UIKit;
@import HealthKit;
@import HomeKit;


#import "APLPrivacyClassesTableViewController.h"
#import "APLPrivacyDetailViewController.h"

@interface APLPrivacyClassesTableViewController ()

@property (nonatomic, strong) NSArray *serviceArray;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) CBCentralManager *cbManager;
@property (nonatomic, strong) CMMotionActivityManager *cmManager;
@property (nonatomic, strong) NSOperationQueue *motionActivityQueue;
@property (nonatomic, strong) CNContactStore *contactStore;
@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) HMHomeManager *homeManager;

@end


@implementation APLPrivacyClassesTableViewController

#pragma mark - View lifecycle management

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
     Create an array with all our services.
     */
    self.serviceArray = @[kDataClassLocation, kDataClassCalendars, kDataClassContacts, kDataClassPhotosImagePicker, kDataClassPhotosLibrary, kDataClassReminders, kDataClassMicrophone, kDataClassMotion, kDataClassBluetooth, kDataClassFacebook, kDataClassTwitter, kDataClassSinaWeibo, kDataClassTencentWeibo, kDataClassAdvertising, kDataClassHealth, kDataClassHome];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    APLPrivacyDetailViewController *viewController = ((APLPrivacyDetailViewController *)segue.destinationViewController);
    
    NSString *serviceString = self.serviceArray[self.tableView.indexPathForSelectedRow.row];
    
    [viewController setTitle:serviceString];
    
    if([serviceString isEqualToString:kDataClassLocation]) {
        [viewController setCheckBlock:^ {
            [self checkLocationServicesAuthorizationStatus];
        }];
        [viewController setRequestBlock:^{
            [self requestLocationServicesAuthorization];
        }];
    }
    else if([serviceString isEqualToString:kDataClassContacts]) {
        [viewController setCheckBlock:^ {
            [self checkContactStoreAccess];
        }];
        [viewController setRequestBlock:^{
            [self requestContactStoreAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassCalendars]) {
        [viewController setCheckBlock:^ {
            [self checkEventStoreAccessForType:EKEntityTypeEvent];
        }];
        [viewController setRequestBlock:^{
            [self requestEventStoreAccessWithType:EKEntityTypeEvent];
        }];
    }
    else if([serviceString isEqualToString:kDataClassReminders]) {
        [viewController setCheckBlock:^ {
            [self checkEventStoreAccessForType:EKEntityTypeReminder];
        }];
        [viewController setRequestBlock:^{
            [self requestEventStoreAccessWithType:EKEntityTypeReminder];
        }];
    }
    else if([serviceString isEqualToString:kDataClassPhotosImagePicker]) {
        [viewController setCheckBlock:^ {
            [self reportPhotosAuthorizationStatus];
        }];
        [viewController setRequestBlock:^{
            [self requestPhotosAccessUsingImagePicker];
        }];
    }
    else if([serviceString isEqualToString:kDataClassPhotosLibrary]) {
        [viewController setCheckBlock:^ {
            [self reportPhotosAuthorizationStatus];
        }];
        [viewController setRequestBlock:^{
            [self requestPhotosAccessUsingPhotoLibrary];
        }];
    }
    else if([serviceString isEqualToString:kDataClassMicrophone]) {
        [viewController setCheckBlock:nil];
        [viewController setRequestBlock:^{
            [self requestMicrophoneAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassMotion]) {
        [viewController setCheckBlock:nil];
        [viewController setRequestBlock:^{
            
            [self requestMotionAccessData];
        }];
    }
    else if([serviceString isEqualToString:kDataClassBluetooth]) {
        [viewController setCheckBlock:^{
            [self checkBluetoothAccess];
        }];
        [viewController setRequestBlock:^{
            [self requestBluetoothAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassFacebook]) {
        [viewController setCheckBlock:^{
            [self checkSocialAccountAuthorizationStatus:ACAccountTypeIdentifierFacebook];
        }];
        [viewController setRequestBlock:^{
            [self requestFacebookAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassTwitter]) {
        [viewController setCheckBlock:^{
            [self checkSocialAccountAuthorizationStatus:ACAccountTypeIdentifierTwitter];
        }];
        [viewController setRequestBlock:^{
            [self requestTwitterAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassSinaWeibo]) {
        [viewController setCheckBlock:^{
            [self checkSocialAccountAuthorizationStatus:ACAccountTypeIdentifierSinaWeibo];
        }];
        [viewController setRequestBlock:^{
            [self requestSinaWeiboAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassTencentWeibo]) {
        [viewController setCheckBlock:^{
            [self checkSocialAccountAuthorizationStatus:ACAccountTypeIdentifierTencentWeibo];
        }];
        [viewController setRequestBlock:^{
            [self requestTencentWeiboAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassAdvertising]) {
        [viewController setCheckBlock:^{
            [self advertisingIdentifierStatus];
        }];
        [viewController setRequestBlock:nil];
    }
    else if([serviceString isEqualToString:kDataClassHealth]) {
        [viewController setCheckBlock:^{
            [self checkHealthAccess];
        }];
        [viewController setRequestBlock:^{
            [self requestHealthAccess];
        }];
    }
    else if([serviceString isEqualToString:kDataClassHome]) {
        [viewController setRequestBlock:^{
            [self requestHomeAccess];
        }];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSString *serviceString = self.serviceArray[self.tableView.indexPathForSelectedRow.row];
    if([serviceString isEqualToString:kDataClassMotion] && ![CMMotionActivityManager isActivityAvailable]) {
        [self alertViewWithDataClass:Motion status:NSLocalizedString(@"UNAVAILABLE", @"")];
        return NO;
    }
    
    return YES;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.serviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    cell.textLabel.text = self.serviceArray[indexPath.row];
    return cell;
}

#pragma mark - Location methods

- (void)checkLocationServicesAuthorizationStatus {
    /*
     We can ask the location services manager ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    [self reportLocationServicesAuthorizationStatus:[CLLocationManager authorizationStatus]];
}

- (void)reportLocationServicesAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *statusText = nil;
    if(status == kCLAuthorizationStatusNotDetermined) {
        statusText = NSLocalizedString(@"UNDETERMINED", @"");
    }
    else if(status == kCLAuthorizationStatusRestricted) {
        statusText = NSLocalizedString(@"RESTRICTED", @"");
    }
    else if(status == kCLAuthorizationStatusDenied) {
        statusText = NSLocalizedString(@"DENIED", @"");
    }
    else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        statusText = NSLocalizedString(@"LOCATION_WHEN_IN_USE", @"");
    }
    else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        statusText = NSLocalizedString(@"LOCATION_ALWAYS", @"");
    }
    
    [self alertViewWithDataClass:Location status:statusText];
}

- (void)requestLocationServicesAuthorization {
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    /*
     Gets user permission to get their location while the app is in the foreground.
     
     To monitor the user's location even when the app is in the background:
     1. Replace [self.locationManager requestWhenInUseAuthorization] with [self.locationManager requestAlwaysAuthorization]
     2. Change NSLocationWhenInUseUsageDescription to NSLocationAlwaysUsageDescription in InfoPlist.strings
     */
    [self.locationManager requestWhenInUseAuthorization];
    
    /*
     Requests a single location after the user is presented with a consent dialog.
     */
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationMangerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    /*
     Handle the failure...
     */
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    /*
     Do something with the new location the application just received...
     */
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    /*
     The delegate function will be called when the permission status changes the application should then attempt to handle the change appropriately by changing UI or setting up or tearing down data structures.
     */
    [self reportLocationServicesAuthorizationStatus:status];
}

#pragma mark - Contacts methods

- (void)checkContactStoreAccess {
    /*
     We can ask the contact store ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if(status == CNAuthorizationStatusNotDetermined) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"UNDETERMINED", @"")];
    }
    else if(status == CNAuthorizationStatusRestricted) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"RESTRICTED", @"")];
    }
    else if(status == CNAuthorizationStatusDenied) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"DENIED", @"")];
    }
    else if(status == CNAuthorizationStatusAuthorized) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"GRANTED", @"")];
    }
}

- (void)requestContactStoreAccess {
    if(!self.contactStore) {
        self.contactStore = [[CNContactStore alloc] init];
    }
    
    [self.contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:Contacts status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            
            /*
             Do something with the access to the contact store...
             */
        });
    }];    
}

#pragma mark - EventStore methods

- (void)checkEventStoreAccessForType:(EKEntityType)type {
    /*
     We can ask the event store ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:type];
    if(status == EKAuthorizationStatusNotDetermined) {
        [self alertViewWithDataClass:((type == EKEntityTypeEvent) ? Calendars : Reminders) status:NSLocalizedString(@"UNDETERMINED", @"")];
    }
    else if(status == EKAuthorizationStatusRestricted) {
        [self alertViewWithDataClass:((type == EKEntityTypeEvent) ? Calendars : Reminders) status:NSLocalizedString(@"RESTRICTED", @"")];
    }
    else if(status == EKAuthorizationStatusDenied) {
        [self alertViewWithDataClass:((type == EKEntityTypeEvent) ? Calendars : Reminders) status:NSLocalizedString(@"DENIED", @"")];
    }
    else if(status == EKAuthorizationStatusAuthorized) {
        [self alertViewWithDataClass:((type == EKEntityTypeEvent) ? Calendars : Reminders) status:NSLocalizedString(@"GRANTED", @"")];
    }
}

- (void)requestEventStoreAccessWithType:(EKEntityType)type {
    if(!self.eventStore) {
        self.eventStore = [[EKEventStore alloc] init];
    }
    
    /*
     When the application requests to receive event store data that is when the user is presented with a consent dialog.
     */
    [self.eventStore requestAccessToEntityType:type completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:((type == EKEntityTypeEvent) ? Calendars : Reminders) status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            
            /*
             Do something with the access to eventstore...
             */
        });
    }];
}

#pragma mark - Photos methods

- (void)reportPhotosAuthorizationStatus {
    /*
     We can ask the photo library ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    NSString *statusText = nil;
    if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
       statusText = NSLocalizedString(@"UNDETERMINED", @"");
    }
    else if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
        statusText = NSLocalizedString(@"RESTRICTED", @"");
    }
    else if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied) {
        statusText = NSLocalizedString(@"DENIED", @"");
    }
    else if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        statusText = NSLocalizedString(@"GRANTED", @"");
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"PHOTOS_ACCESS_LEVEL", @""), statusText];
    [self alertViewWithMessage:message];
}

- (void)requestPhotosAccessUsingImagePicker {
    /*
    There are two ways to prompt the user for permission to access photos. This one will display the photo picker UI.  See the PHPhotoLibrary example in this file for the other way to request photo access.
     */
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    /*
     Upon presenting the picker, consent will be required from the user if the user previously denied access to the photo library, an "access denied" lock screen will be presented to the user to remind them of this choice.
     */
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)requestPhotosAccessUsingPhotoLibrary {
    /*
     There are two ways to prompt the user for permission to access photos. This one will not display the photo picker UI.  See the UIImagePickerController example in this file for the other way to request photo access.
     */
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reportPhotosAuthorizationStatus];
        });
    }];
}

#pragma mark - Microphone methods

- (void)requestMicrophoneAccess {
    AVAudioSession *session = [[AVAudioSession alloc] init];
    [session requestRecordPermission:^(BOOL granted) {
        if(granted) {
            NSError *error;
            /*
             Setting the category will also request access from the user
             */
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
            
            /*
             Do something with the audio session
             */
        }
        else {
            /*
             Handle failure
             */
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:Microphone status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
        });
    }];
}

#pragma mark - Motion methods

- (void)requestMotionAccessData {
    self.cmManager = [[CMMotionActivityManager alloc] init];
    self.motionActivityQueue = [[NSOperationQueue alloc] init];
    [self.cmManager startActivityUpdatesToQueue:self.motionActivityQueue withHandler:^(CMMotionActivity *activity) {
        /* 
         * Do something with the activity reported
         */
        [self alertViewWithDataClass:Motion status:NSLocalizedString(@"ALLOWED", @"")];
        [self.cmManager stopActivityUpdates];
    }];
}

#pragma mark - Bluetooth methods

- (void)checkBluetoothAccess {
    if(!self.cbManager) {
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    /*
     We can ask the bluetooth manager ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    CBCentralManagerState state = [self.cbManager state];
    if(state == CBCentralManagerStateUnknown) {
        [self alertViewWithDataClass:Bluetooth status:NSLocalizedString(@"UNKNOWN", @"")];
    }
    else if(state == CBCentralManagerStateUnauthorized) {
        [self alertViewWithDataClass:Bluetooth status:NSLocalizedString(@"DENIED", @"")];
    }
    else {
        [self alertViewWithDataClass:Bluetooth status:NSLocalizedString(@"GRANTED", @"")];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    /*
     The delegate method will be called when the permission status changes the application should then attempt to handle the change appropriately by changing UI or setting up or tearing down data structures.
     */
}

- (void)requestBluetoothAccess {
    if(!self.cbManager) {
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    /*
     When the application requests to start scanning for bluetooth devices that is when the user is presented with a consent dialog.
     */
    [self.cbManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    /*
     Handle the discovered bluetooth devices...
     */
}

#pragma mark - Social methods

- (void)checkSocialAccountAuthorizationStatus:(NSString *)accountTypeIndentifier {
    if(!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    
    /*
     We can ask each social account type ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    ACAccountType *socialAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:accountTypeIndentifier];
    
    DataClass class;
    if([accountTypeIndentifier isEqualToString:ACAccountTypeIdentifierFacebook]) {
        class = Facebook;
    }
    else if([accountTypeIndentifier isEqualToString:ACAccountTypeIdentifierTwitter]) {
        class = Twitter;
    }
    else if([accountTypeIndentifier isEqualToString:ACAccountTypeIdentifierSinaWeibo]) {
        class = SinaWeibo;
    }
    else {
        class = TencentWeibo;
    }
    [self alertViewWithDataClass:class status:([socialAccount accessGranted]) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
}

#pragma mark - Facebook

- (void)requestFacebookAccess {
    if(!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    ACAccountType *facebookAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    /*
     When requesting access to the account is when the user will be prompted for consent.
     */
    NSDictionary *options = @{ ACFacebookAppIdKey: @"MY_CODE",
                               ACFacebookPermissionsKey: @[@"email", @"user_about_me"],
                               ACFacebookAudienceKey: ACFacebookAudienceFriends };
    [self.accountStore requestAccessToAccountsWithType:facebookAccount options:options completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:Facebook status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            /*
             Do something with account access...
             */
        });
    }];
}

#pragma mark - Twitter

- (void)requestTwitterAccess {
    if(!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    
    ACAccountType *twitterAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    /*
     When requesting access to the account is when the user will be prompted for consent.
     */
    [self.accountStore requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:Twitter status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            /*
             Do something with account access...
             */
        });
    }];
}

#pragma mark - SinaWeibo methods

- (void)requestSinaWeiboAccess {
    if(!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    
    ACAccountType *sinaWeiboAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierSinaWeibo];
    
    /*
     When requesting access to the account is when the user will be prompted for consent.
     */
    [self.accountStore requestAccessToAccountsWithType:sinaWeiboAccount options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:SinaWeibo status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            /*
             Do something with account access...
             */
        });
    }];
}

#pragma mark - TencentWeibo methods

- (void)requestTencentWeiboAccess {
    if(!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    
    ACAccountType *tencentWeiboAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTencentWeibo];
    
    /*
     When requesting access to the account is when the user will be prompted for consent.
     */
    [self.accountStore requestAccessToAccountsWithType:tencentWeiboAccount options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertViewWithDataClass:TencentWeibo status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            /*
             Do something with account access...
             */
        });
    }];
}

#pragma mark - Advertising

- (void)advertisingIdentifierStatus {
    /*
     It is required to check the value of the property isAdvertisingTrackingEnabled before using the advertising identifier.  if the value is NO, then identifier can only be used for the purposes enumerated in the program license agreement note that the advertising ID can be controlled by restrictions just like the rest of the privacy data classes.
     Applications should not cache the advertising ID as it can be changed via the reset button in Settings.
     */
    [self alertViewWithDataClass:Advertising status:([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) ? NSLocalizedString(@"ALLOWED", @"") : NSLocalizedString(@"DENIED", @"")];
}

#pragma mark - Health methods

- (void)checkHealthAccess {
    if ([HKHealthStore isHealthDataAvailable]) {
        if (!self.healthStore) {
            self.healthStore = [[HKHealthStore alloc] init];
        }
        
        HKQuantityType *heartRateType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:heartRateType];
        
        if (status == HKAuthorizationStatusNotDetermined) {
            [self alertViewWithDataClass:Health status:NSLocalizedString(@"UNKNOWN", @"")];
        }
        else if (status == HKAuthorizationStatusSharingAuthorized) {
            [self alertViewWithDataClass:Health status:NSLocalizedString(@"GRANTED", @"")];
        }
        else if (status == HKAuthorizationStatusSharingDenied) {
            [self alertViewWithDataClass:Health status:NSLocalizedString(@"DENIED", @"")];
        }
    }
    else {
        // Health data is not available on all devices
        [self alertViewWithDataClass:Health status:NSLocalizedString(@"UNAVAILABLE", @"")];
    }
}

- (void)requestHealthAccess {
    if ([HKHealthStore isHealthDataAvailable]) {
        if (!self.healthStore) {
            self.healthStore = [[HKHealthStore alloc] init];
        }
        
        HKQuantityType *heartRateType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        NSSet *typeSet = [NSSet setWithObject:heartRateType];
        
        /*
         Requests consent from the user to read and write heart rate data from the health store
         */
        [self.healthStore requestAuthorizationToShareTypes:typeSet
                                                 readTypes:typeSet
                                                completion:^(BOOL success, NSError *error) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self checkHealthAccess];
                                                    });
                                                }];
    }
    else {
        // Health data is not available on all devices
        [self alertViewWithDataClass:Health status:NSLocalizedString(@"UNAVAILABLE", @"")];
    }
}

#pragma mark - Home methods

- (void)requestHomeAccess {
    self.homeManager = [[HMHomeManager alloc] init];
    
    // HMHomeManager will notify the delegate when it's ready to vend home data. It will ask for user permission first, if needed.
    self.homeManager.delegate = self;
}

- (void)homeManagerDidUpdateHomes:(HMHomeManager *)manager {
    if (manager.homes.count > 0) {
        // A home exists, so we have access
        [self alertViewWithDataClass:Home status:NSLocalizedString(@"GRANTED", @"")];
    }
    else {
        // No homes are available.  Is that because no home is set in HMHomeManager, or because the user denied access?
        __weak HMHomeManager *weakHomeManager = manager; // Prevent memory leak
        [manager addHomeWithName:@"Test Home" completionHandler:^(HMHome *home, NSError *error) {
            
            if (!error) {
                [self alertViewWithDataClass:Home status:NSLocalizedString(@"GRANTED", @"")];
            }
            else {
                if (error.code == HMErrorCodeHomeAccessNotAuthorized) {
                    // User denied permission
                    [self alertViewWithDataClass:Home status:NSLocalizedString(@"DENIED", @"")];
                }
                else {
                    // Handle other errors cleanly
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"HOME_ERROR", @""), error.code, error.localizedDescription];
                    [self alertViewWithMessage:message];
                }
            }
            
            if (home) {
                // Clean up after ourselves, don't leave the Test Home in the HMHomeManager array
                [weakHomeManager removeHome:home completionHandler:^(NSError * _Nullable error) {
                    // ... do something with the result of removing the home ...
                }];
            }
        }];
    }
}

#pragma mark - Helper methods

- (void)alertViewWithDataClass:(DataClass)class status:(NSString *)status {
    NSString *formatString = NSLocalizedString(@"ACCESS_LEVEL", @"");
    NSString *message = [NSString stringWithFormat:formatString, [self stringForDataClass:class], status];
    [self alertViewWithMessage:message];
}

- (void)alertViewWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"REQUEST_STATUS", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (NSString *)stringForDataClass:(DataClass)class {
    if(class == Location) {
        return kDataClassLocation;
    }
    else if(class == Contacts) {
        return kDataClassContacts;
    }
    else if(class == Calendars) {
        return kDataClassCalendars;
    }
    else if(class == PhotosImagePicker) {
        return kDataClassPhotosImagePicker;
    }
    else if(class == PhotosLibrary) {
        return kDataClassPhotosLibrary;
    }
    else if(class == Reminders) {
        return kDataClassReminders;
    }
    else if(class == Bluetooth) {
        return kDataClassBluetooth;
    }
    else if(class == Microphone) {
        return kDataClassMicrophone;
    }
    else if(class == Motion) {
        return kDataClassMotion;
    }
    else if(class == Facebook) {
        return kDataClassFacebook;
    }
    else if(class == Twitter) {
        return kDataClassTwitter;
    }
    else if(class == SinaWeibo) {
        return kDataClassSinaWeibo;
    }
    else if(class == TencentWeibo) {
        return kDataClassTencentWeibo;
    }
    else if(class == Advertising) {
        return kDataClassAdvertising;
    }
    else if(class == Health) {
        return kDataClassHealth;
    }
    else if(class == Home) {
        return kDataClassHome;
    }
    
    return nil;
}

@end