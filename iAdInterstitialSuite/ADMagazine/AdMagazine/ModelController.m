/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The data model controller that manages our view controller pages.
 */

#import "ModelController.h"
#import "DataViewController.h"

@interface ModelController ()

@property (nonatomic, strong) NSMutableArray *pageData;

@end


#pragma mark -

@implementation ModelController

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        // Create the data model.
        _pageData = [NSMutableArray array];
        [self.pageData addObjectsFromArray:@[@"bunny1", @"bunny2", @"bunny3", @"bunny4"]];
    }
    return self;
}

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{
    // Return the data view controller for the given index.
    if ((self.pageData.count == 0) || (index >= self.pageData.count))
    {
        return nil;
    }

    // Create a new view controller and pass suitable data.
    DataViewController *dataViewController = [storyboard instantiateViewControllerWithIdentifier:@"DataViewController"];
    dataViewController.dataObject = self.pageData[index];
    
    return dataViewController;
}

- (NSUInteger)indexOfViewController:(DataViewController *)viewController
{
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the
    // view controller stores the model object; you can therefore use the model object to identify the index.
    //
    return [self.pageData indexOfObject:viewController.dataObject];
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if ((index == 0) || (index == NSNotFound))
    {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound)
    {
        return nil;
    }
    
    index++;
    if (index == self.pageData.count)
    {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
