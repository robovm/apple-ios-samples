/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A category for getting localized descriptions for HomeKit errors.
 */
@import Foundation;
@import HomeKit;

@interface NSError (HomeKit)

/**
 *  A localized translation of the HMErrorCode.
 */
@property (nonatomic, readonly) NSString *hmc_localizedTranslation;

@end
