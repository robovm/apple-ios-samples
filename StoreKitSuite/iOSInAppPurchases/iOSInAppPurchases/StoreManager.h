/*
     File: StoreManager.h
 Abstract: Retrieves product information from the App Store using SKRequestDelegate,
           SKProductsRequestDelegate,SKProductsResponse, and SKProductsRequest.
           Notifies its observer with a list of products available for sale along with
           a list of invalid product identifiers. Logs an error message if the product request failed.
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */

// Provide notification about the product request
NSString * const IAPProductRequestNotification;


@interface StoreManager : NSObject
typedef NS_ENUM(NSInteger, IAPProductRequestStatus)
{
    IAPProductsFound,// Indicate that there are some valid products
    IAPIdentifiersNotFound, // indicate that are some invalid product identifiers
    IAPRequestFailed // Indicate that the product request failed
};

// Provide the status of the product request
@property (nonatomic) IAPProductRequestStatus status;

// Keep track of all valid products. These products are available for sale in the App Store
@property (nonatomic, strong) NSMutableArray *availableProducts;

// Keep track of all invalid product identifiers
@property (nonatomic, strong) NSMutableArray *invalidProductIds;

// Indicate the cause of the product request failure
@property (nonatomic, copy) NSString *errorMessage;

+ (StoreManager *)sharedInstance;

// Query the App Store about the given product identifiers
-(void)fetchProductInformationForIds:(NSArray *)productIds;

// Return the product's title matching a given product identifier
-(NSString *)titleMatchingProductIdentifier:(NSString *)identifier;

@end
