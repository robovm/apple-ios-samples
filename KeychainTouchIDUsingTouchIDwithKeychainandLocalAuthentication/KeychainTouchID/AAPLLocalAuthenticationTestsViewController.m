/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

 Implements LocalAuthentication framework demo
 
*/


#import "AAPLLocalAuthenticationTestsViewController.h"

@import LocalAuthentication;

@implementation AAPLLocalAuthenticationTestsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // prepare the actions which can be tested in this class
    self.tests = @[
       [[AAPLTest alloc] initWithName:NSLocalizedString(@"TOUCH_ID_PREFLIGHT", nil) details:@"Using canEvaluatePolicy:" selector:@selector(canEvaluatePolicy)],
       [[AAPLTest alloc] initWithName:NSLocalizedString(@"TOUCH_ID", nil) details:@"Using evaluatePolicy:" selector:@selector(evaluatePolicy)],
       [[AAPLTest alloc] initWithName:NSLocalizedString(@"TOUCH_ID_CUSTOM", nil) details:@"Using evaluatePolicy:" selector:@selector(evaluatePolicy2)]
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

- (void)canEvaluatePolicy
{
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    NSError *error;
    BOOL success;
    
    // test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
    success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        msg =[NSString stringWithFormat:NSLocalizedString(@"TOUCH_ID_IS_AVAILABLE", nil)];
    } else {
        msg =[NSString stringWithFormat:NSLocalizedString(@"TOUCH_ID_IS_NOT_AVAILABLE", nil)];
    }
    [super printResult:self.textView message:msg];
    
}

- (void)evaluatePolicy
{
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    
    // show the authentication UI with our reason string
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"UNLOCK_ACCESS_TO_LOCKED_FATURE", nil) reply:
     ^(BOOL success, NSError *authenticationError) {
         if (success) {
             msg =[NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_SUCCESS", nil)];
         } else {
             msg = [NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_WITH_ERROR", nil), authenticationError.localizedDescription];
         }
         [self printResult:self.textView message:msg];
     }];
    
}

- (void)evaluatePolicy2
{
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    
    // set text for the localized fallback button
    context.localizedFallbackTitle = NSLocalizedString(@"TOUCH_ID_FALLBACK",nil);
    
    // show the authentication UI with our reason string
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"UNLOCK_ACCESS_TO_LOCKED_FATURE", nil) reply:
     ^(BOOL success, NSError *authenticationError) {
         if (success) {
             msg =[NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_SUCCESS", nil)];
         } else {
             msg = [NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_WITH_ERROR", nil), authenticationError.localizedDescription];
         }
         [self printResult:self.textView message:msg];
     }];
    
}

@end
