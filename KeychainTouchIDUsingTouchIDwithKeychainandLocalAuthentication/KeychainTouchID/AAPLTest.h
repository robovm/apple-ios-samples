/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Test instance which holds the test name details and the selector which should be invoked to perform the test.
  
 */


@interface AAPLTest : NSObject

- (instancetype)initWithName:(NSString *)name details:(NSString *)details selector:(SEL)method;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *details;
@property (nonatomic) SEL method;

@end
