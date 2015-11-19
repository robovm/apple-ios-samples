/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A data object for storing context information relevant to how the app was launched.
*/

#import "AAPLAppLaunchContext.h"

@implementation AAPLAppLaunchContext

- (instancetype)initWithListURL:(NSURL *)listURL listColor:(AAPLListColor)listColor {
    self = [super init];
    
    if (self) {
        _listURL = listURL;
        _listColor = listColor;
    }
    
    return self;
}

- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity listsController:(AAPLListsController *)listsController {
    self = [super init];
    
    if (self) {
        if (!userActivity.userInfo) {
            NSLog(@"User activity provided to \(__FUNCTION__) has no `userInfo` dictionary.");
            return nil;
        }
        
        /*
            The URL may be provided as either a URL or a URL path via separate keys. Check first for
            `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
        */
        _listURL = userActivity.userInfo[NSUserActivityDocumentURLKey];
        
        if (!_listURL) {
            NSString *listInfoFilePath = userActivity.userInfo[AAPLAppConfigurationUserActivityListURLPathUserInfoKey];
            if (!listInfoFilePath) {
                NSLog(@"The `userInfo` dictionary provided to \(__FUNCTION__) did not contain a URL or a URL path.");
                return nil;
            }

            _listURL = [NSURL fileURLWithPath:listInfoFilePath isDirectory:NO];
            
            if (![_listURL checkPromisedItemIsReachableAndReturnError:nil] && ![_listURL checkResourceIsReachableAndReturnError:nil]) {
                _listURL = [listsController.documentsDirectory URLByAppendingPathComponent:_listURL.lastPathComponent isDirectory:NO];
                
                if (![_listURL checkPromisedItemIsReachableAndReturnError:nil] && ![_listURL checkResourceIsReachableAndReturnError:nil]) {
                    _listURL = nil;
                }
            }
        }
        
        if (!_listURL) {
            NSLog(@"`listURL in \(__FUNCTION__) must not be `nil`.");
            return nil;
        }
        
        NSNumber *listInfoColorNumber = userActivity.userInfo[AAPLAppConfigurationUserActivityListColorUserInfoKey];
        
        if (!listInfoColorNumber && !(listInfoColorNumber.integerValue >= 0 && listInfoColorNumber.integerValue < 6)) {
            NSLog(@"The `userInfo` dictionary provided to \(__FUNCTION__) contains an invalid entry for the list color.");
            return nil;
        }
        
        // Set the `listColor` by converting the `NSNumber` to an NSInteger and casting to `AAPLListColor`.
        _listColor = (AAPLListColor)listInfoColorNumber.integerValue;
    }
    
    return self;
}

- (instancetype)initWithListerURL:(NSURL *)listerURL {
    self = [super init];
    
    if (self) {
        NSParameterAssert(listerURL.scheme != nil && [listerURL.scheme isEqualToString:AAPLAppConfigurationListerSchemeName]);
        
        NSString *filePath = listerURL.path;
        if (!filePath) {
            NSLog(@"URL provided to \(__FUNCTION__) is missing `path`.");
            return nil;
        }
        
        // Construct a file URL from the path of the lister:// URL.
        _listURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
        
        // Extract the query items to initialize the `listColor` property from the `color` query item.
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:listerURL resolvingAgainstBaseURL:NO];
        NSArray *queryItems = urlComponents.queryItems;
        
        if (!urlComponents || !queryItems) {
            NSLog(@"URL provided to \(__FUNCTION__) contains no query items.");
            return nil;
        }
        
        // Construct a predicate to extract the `color` query item.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", AAPLAppConfigurationListerColorQueryKey];
        NSArray *colorQueryItems = [queryItems filteredArrayUsingPredicate:predicate];
        
        if (colorQueryItems.count != 1) {
            NSLog(@"URL provided should contain only one `color` query item.");
            return nil;
        }
        
        NSURLQueryItem *colorQueryItem = colorQueryItems.firstObject;
        
        if (!colorQueryItem.value) {
            NSLog(@"URL provided contains an invalid value for `color`.");
            return nil;
        }
        
        // Set the `listColor` by converting the `NSString` value to an NSInteger and casting to `AAPLListColor`.
        _listColor = colorQueryItem.value.integerValue;
    }
    
    return self;
}

@end
