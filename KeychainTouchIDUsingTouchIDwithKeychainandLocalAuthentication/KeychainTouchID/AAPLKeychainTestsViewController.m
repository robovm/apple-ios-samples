/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Keychain with Touch ID demo implementation
  
 */

#import "AAPLKeychainTestsViewController.h"

@import Security;

@implementation AAPLKeychainTestsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // prepare the actions which can be tested in this class
    self.tests = @[
        [[AAPLTest alloc] initWithName:NSLocalizedString(@"ADD_ITEM", nil) details:@"Using SecItemAdd()" selector:@selector(addItemAsync)],
        [[AAPLTest alloc] initWithName:NSLocalizedString(@"QUERY_FOR_ITEM", nil) details:@"Using SecItemCopyMatching()" selector:@selector(copyMatchingAsync)],
        [[AAPLTest alloc] initWithName:NSLocalizedString(@"UPDATE_ITEM", nil) details:@"Using SecItemUpdate()" selector:@selector(updateItemAsync)],
        [[AAPLTest alloc] initWithName:NSLocalizedString(@"DELETE_ITEM", nil) details:@"Using SecItemDelete()" selector:@selector(deleteItemAsync)]

        ];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
}

-(void)viewDidLayoutSubviews
{
    // just set the proper size for the table view based on its content
    CGFloat height = MIN(self.view.bounds.size.height, self.tableView.contentSize.height);
    self.dynamicViewHeight.constant = height;
    [self.view layoutIfNeeded];
}

#pragma mark - Tests

- (void)copyMatchingAsync
{
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"SampleService",
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"AUTHENTICATE_TO_ACCESS_SERVICE_PASSWORD", nil)
        };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *msg;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess)
        {
            NSData *resultData = ( __bridge_transfer NSData *)dataTypeRef;
            NSString * result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        
            msg = [NSString stringWithFormat:NSLocalizedString(@"RESULT", nil), result];
        } else {
            msg = [NSString stringWithFormat:NSLocalizedString(@"SEC_ITEM_COPY_MATCHING_STATUS", nil), [self keychainErrorToString:status]];
        }
        [self printResult:self.textView message:msg];
    });
}

- (void)updateItemAsync
{
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"SampleService",
        (__bridge id)kSecUseOperationPrompt: @"Authenticate to update your password"
        };
    
    NSDictionary *changes = @{
        (__bridge id)kSecValueData: [@"UPDATED_SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding]
        };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"SEC_ITEM_UPDATE_STATUS", nil), [self keychainErrorToString:status]];
        [super printResult:self.textView message:msg];
    });
}

- (void)addItemAsync
{
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence, &error);
    if(sacObject == NULL || error != NULL)
    {
        NSLog(@"can't create sacObject: %@", error);
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"SEC_ITEM_ADD_CAN_CREATE_OBJECT", nil), error]];
        return;
    }
    
    // we want the operation to fail if there is an item which needs authentication so we will use
    // kSecUseNoAuthenticationUI
    NSDictionary *attributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"SampleService",
        (__bridge id)kSecValueData: [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding],
        (__bridge id)kSecUseNoAuthenticationUI: @YES,
        (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
        };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"SEC_ITEM_ADD_STATUS", nil), [self keychainErrorToString:status]];
        [self printResult:self.textView message:msg];
    });
}

- (void)deleteItemAsync
{
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"SampleService"
        };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"SEC_ITEM_DELETE_STATUS", nil), [self keychainErrorToString:status]];
        [super printResult:self.textView message:msg];
    });
}



#pragma mark - Tools

- (NSString *)keychainErrorToString: (OSStatus)error
{
    
    NSString *msg = [NSString stringWithFormat:@"%ld",(long)error];
    
    switch (error) {
        case errSecSuccess:
            msg = NSLocalizedString(@"SUCCESS", nil);
            break;
        case errSecDuplicateItem:
            msg = NSLocalizedString(@"ERROR_ITEM_ALREADY_EXISTS", nil);
            break;
        case errSecItemNotFound :
            msg = NSLocalizedString(@"ERROR_ITEM_NOT_FOUND", nil);
            break;
        case errSecAuthFailed:
            msg = NSLocalizedString(@"ERROR_ITEM_AUTHENTICATION_FAILED", nil);
            break;
        default:
            break;
    }
    
    return msg;
}

@end
