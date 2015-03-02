/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A category for getting localized descriptions for HomeKit errors.
 */

#import "NSError+HomeKit.h"

@implementation NSError (HomeKit)

- (NSString *)hmc_localizedTranslation {
    static NSDictionary *errorCodeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errorCodeMap = @{@(HMErrorCodeAlreadyExists): NSLocalizedString(@"Already Exits", @"Already Exits"),
                         @(HMErrorCodeNotFound): NSLocalizedString(@"Not Found", @"Not Found"),
                         @(HMErrorCodeInvalidParameter): NSLocalizedString(@"Invalid Parameter", @"Invalid Parameter"),
                         @(HMErrorCodeAccessoryNotReachable): NSLocalizedString(@"Accessory Not Reachable", @"Accessory Not Reachable"),
                         @(HMErrorCodeReadOnlyCharacteristic): NSLocalizedString(@"Read Only Characteristic", @"Read Only Characteristic"),
                         @(HMErrorCodeWriteOnlyCharacteristic): NSLocalizedString(@"Write Only Characteristic", @"Write Only Characteristic"),
                         @(HMErrorCodeNotificationNotSupported): NSLocalizedString(@"Notification Not Supported", @"Notification Not Supported"),
                         @(HMErrorCodeOperationTimedOut): NSLocalizedString(@"Operation Timed Out", @"Operation Timed Out"),
                         @(HMErrorCodeAccessoryPoweredOff): NSLocalizedString(@"Accessory Powered Off", @"Accessory Powered Off"),
                         @(HMErrorCodeAccessDenied): NSLocalizedString(@"Access Denied", @"Access Denied"),
                         @(HMErrorCodeObjectAssociatedToAnotherHome): NSLocalizedString(@"Object Associated To Another Home", @"Object Associated To Another Home"),
                         @(HMErrorCodeObjectNotAssociatedToAnyHome): NSLocalizedString(@"Object Not Associated To Any Home", @"Object Not Associated To Any Home"),
                         @(HMErrorCodeObjectAlreadyAssociatedToHome): NSLocalizedString(@"Object Already Associated To Home", @"Object Already Associated To Home"),
                         @(HMErrorCodeAccessoryIsBusy): NSLocalizedString(@"Accessory Is Busy", @"Accessory Is Busy"),
                         @(HMErrorCodeOperationInProgress): NSLocalizedString(@"Operation In Progress", @"Operation In Progress"),
                         @(HMErrorCodeAccessoryOutOfResources): NSLocalizedString(@"Accessory Out Of Resources", @"Accessory Out Of Resources"),
                         @(HMErrorCodeInsufficientPrivileges): NSLocalizedString(@"Insufficient Privileges", @"Insufficient Privileges"),
                         @(HMErrorCodeAccessoryPairingFailed): NSLocalizedString(@"Accessory Pairing Failed", @"Accessory Pairing Failed"),
                         @(HMErrorCodeInvalidDataFormatSpecified): NSLocalizedString(@"Invalid Data Format Specified", @"Invalid Data Format Specified"),
                         @(HMErrorCodeNilParameter): NSLocalizedString(@"Nil Parameter", @"Nil Parameter"),
                         @(HMErrorCodeUnconfiguredParameter): NSLocalizedString(@"Unconfigured Parameter", @"Unconfigured Parameter"),
                         @(HMErrorCodeInvalidClass): NSLocalizedString(@"Invalid Class", @"Invalid Class"),
                         @(HMErrorCodeOperationCancelled): NSLocalizedString(@"Operation Cancelled", @"Operation Cancelled"),
                         @(HMErrorCodeRoomForHomeCannotBeInZone): NSLocalizedString(@"Room For Home Cannot Be In Zone", @"Room For Home Cannot Be In Zone"),
                         @(HMErrorCodeNoActionsInActionSet): NSLocalizedString(@"No Actions In Action Set", @"No Actions In Action Set"),
                         @(HMErrorCodeNoRegisteredActionSets): NSLocalizedString(@"No Registered Action Sets", @"No Registered Action Sets"),
                         @(HMErrorCodeMissingParameter): NSLocalizedString(@"Missing Parameter", @"Missing Parameter"),
                         @(HMErrorCodeFireDateInPast): NSLocalizedString(@"Fire Date In Past", @"Fire Date In Past"),
                         @(HMErrorCodeRoomForHomeCannotBeUpdated): NSLocalizedString(@"Room For Home Cannot Be Updated", @"Room For Home Cannot Be Updated"),
                         @(HMErrorCodeActionInAnotherActionSet): NSLocalizedString(@"Action In Another Action Set", @"Action In Another Action Set"),
                         @(HMErrorCodeObjectWithSimilarNameExistsInHome): NSLocalizedString(@"Object With Similar Name Exists In Home", @"Object With Similar Name Exists In Home"),
                         @(HMErrorCodeHomeWithSimilarNameExists): NSLocalizedString(@"Home With Similar Name Exists", @"Home With Similar Name Exists"),
                         @(HMErrorCodeRenameWithSimilarName): NSLocalizedString(@"Rename With Similar Name", @"Rename With Similar Name"),
                         @(HMErrorCodeCannotRemoveNonBridgeAccessory): NSLocalizedString(@"Cannot Remove Non Bridge Accessory", @"Cannot Remove Non Bridge Accessory"),
                         @(HMErrorCodeNameContainsProhibitedCharacters): NSLocalizedString(@"Name Contains Prohibited Characters", @"Name Contains Prohibited Characters"),
                         @(HMErrorCodeNameDoesNotStartWithValidCharacters): NSLocalizedString(@"Name Does Not Start With Valid Characters", @"Name Does Not Start With Valid Characters"),
                         @(HMErrorCodeUserIDNotEmailAddress): NSLocalizedString(@"User ID Not Email Address", @"User ID Not Email Address"),
                         @(HMErrorCodeUserDeclinedAddingUser): NSLocalizedString(@"User Declined Adding User", @"User Declined Adding User"),
                         @(HMErrorCodeUserDeclinedRemovingUser): NSLocalizedString(@"User Declined Removing User", @"User Declined Removing User"),
                         @(HMErrorCodeUserDeclinedInvite): NSLocalizedString(@"User Declined Invite", @"User Declined Invite"),
                         @(HMErrorCodeUserManagementFailed): NSLocalizedString(@"User Management Failed", @"User Management Failed"),
                         @(HMErrorCodeRecurrenceTooSmall): NSLocalizedString(@"Recurrence Too Small", @"Recurrence Too Small"),
                         @(HMErrorCodeInvalidValueType): NSLocalizedString(@"Invalid Value Type", @"Invalid Value Type"),
                         @(HMErrorCodeValueLowerThanMinimum): NSLocalizedString(@"Value Lower Than Minimum", @"Value Lower Than Minimum"),
                         @(HMErrorCodeValueHigherThanMaximum): NSLocalizedString(@"Value Higher Than Maximum", @"Value Higher Than Maximum"),
                         @(HMErrorCodeStringLongerThanMaximum): NSLocalizedString(@"String Longer Than Maximum", @"String Longer Than Maximum"),
                         @(HMErrorCodeHomeAccessNotAuthorized): NSLocalizedString(@"Home Access Not Authorized", @"Home Access Not Authorized"),
                         @(HMErrorCodeOperationNotSupported): NSLocalizedString(@"Operation Not Supported", @"Operation Not Supported"),
                         @(HMErrorCodeMaximumObjectLimitReached): NSLocalizedString(@"Maximum Object Limit Reached", @"Maximum Object Limit Reached"),
                         @(HMErrorCodeAccessorySentInvalidResponse): NSLocalizedString(@"Accessory Sent Invalid Response", @"Accessory Sent Invalid Response"),
                         @(HMErrorCodeStringShorterThanMinimum): NSLocalizedString(@"String Shorter Than Minimum", @"String Shorter Than Minimum"),
                         @(HMErrorCodeGenericError): NSLocalizedString(@"Generic Error", @"Generic Error"),
                         @(HMErrorCodeSecurityFailure): NSLocalizedString(@"Security Failure", @"Security Failure"),
                         @(HMErrorCodeCommunicationFailure): NSLocalizedString(@"Communication Failure", @"Communication Failure"),
                         @(HMErrorCodeMessageAuthenticationFailed): NSLocalizedString(@"Message Authentication Failed", @"Message Authentication Failed"),
                         @(HMErrorCodeInvalidMessageSize): NSLocalizedString(@"Invalid Message Size", @"Invalid Message Size"),
                         @(HMErrorCodeAccessoryDiscoveryFailed): NSLocalizedString(@"Accessory Discovery Failed", @"Accessory Discovery Failed"),
                         @(HMErrorCodeClientRequestError): NSLocalizedString(@"Client Request Error", @"Client Request Error"),
                         @(HMErrorCodeAccessoryResponseError): NSLocalizedString(@"Accessory Response Error", @"Accessory Response Error"),
                         @(HMErrorCodeNameDoesNotEndWithValidCharacters): NSLocalizedString(@"Name Does Not End With Valid Characters", @"Name Does Not End With Valid Characters"),
                         @(HMErrorCodeAccessoryIsBlocked): NSLocalizedString(@"Accessory Is Blocked", @"Accessory Is Blocked"),
                         @(HMErrorCodeInvalidAssociatedServiceType): NSLocalizedString(@"Invalid Associated Service Type", @"Invalid Associated Service Type"),
                         @(HMErrorCodeActionSetExecutionFailed): NSLocalizedString(@"Action Set Execution Failed", @"Action Set Execution Failed"),
                         @(HMErrorCodeActionSetExecutionPartialSuccess): NSLocalizedString(@"Action Set Execution Partial Success", @"Action Set Execution Partial Success"),
                         @(HMErrorCodeActionSetExecutionInProgress): NSLocalizedString(@"Action Set Execution In Progress", @"Action Set Execution In Progress"),
                         @(HMErrorCodeAccessoryOutOfCompliance): NSLocalizedString(@"Accessory Out Of Compliance", @"Accessory Out Of Compliance"),
                         @(HMErrorCodeDataResetFailure): NSLocalizedString(@"Data Reset Failure", @"Data Reset Failure"),
                         @(HMErrorCodeNotificationAlreadyEnabled): NSLocalizedString(@"Notification Already Enabled", @"Notification Already Enabled"),
                         @(HMErrorCodeRecurrenceMustBeOnSpecifiedBoundaries): NSLocalizedString(@"Recurrence Must Be On Specified Boundaries", @"Recurrence Must Be On Specified Boundaries"),
                         @(HMErrorCodeDateMustBeOnSpecifiedBoundaries): NSLocalizedString(@"Date Must Be On Specified Boundaries", @"Date Must Be On Specified Boundaries"),
                         @(HMErrorCodeCannotActivateTriggerTooFarInFuture): NSLocalizedString(@"Cannot Activate Trigger Too Far In Future", @"Cannot Activate Trigger Too Far In Future"),
                         @(HMErrorCodeRecurrenceTooLarge): NSLocalizedString(@"Recurrence Too Large", @"Recurrence Too Large"),
                         @(HMErrorCodeReadWritePartialSuccess): NSLocalizedString(@"Read Write Partial Success", @"Read Write Partial Success"),
                         @(HMErrorCodeReadWriteFailure): NSLocalizedString(@"Read Write Failure", @"Read Write Failure"),
                         @(HMErrorCodeNotSignedIntoiCloud): NSLocalizedString(@"Not Signed Into iCloud", @"Not Signed Into iCloud"),
                         @(HMErrorCodeKeychainSyncNotEnabled): NSLocalizedString(@"Keychain Sync Not Enabled", @"Keychain Sync Not Enabled"),
                         @(HMErrorCodeCloudDataSyncInProgress): NSLocalizedString(@"Cloud Data Sync In Progress", @"Cloud Data Sync In Progress"),
                         @(HMErrorCodeNetworkUnavailable): NSLocalizedString(@"Network Unavailable", @"Network Unavailable"),
                         @(HMErrorCodeAddAccessoryFailed): NSLocalizedString(@"Add Accessory Failed", @"Add Accessory Failed"),
                         @(HMErrorCodeMissingEntitlement): NSLocalizedString(@"Missing Entitlement", @"Missing Entitlement")};
    });
    NSString *translation = errorCodeMap[@(self.code)];
    if (translation) {
        return translation;
    }
    return self.userInfo[NSLocalizedDescriptionKey] ?: self.description;
}

@end
