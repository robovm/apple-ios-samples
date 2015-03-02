/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLFilterViewController.h"
#import "AAPLImageFilter.h"


@implementation AAPLFilterViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // any custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // decide if we want the "Done" button (for iPhone), iPad doesn't need one
    // for iPhone the presentingViewController is nil, for iPad it's a UINavigationController
    //
    if (self.presentingViewController != nil) {
        self.navigationBar.topItem.rightBarButtonItem = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self update];
}

- (IBAction)dismiss:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        // inform our delegate we are going away
        [self.delegate wasDismissed];
    }];
}


#pragma mark - Filtering

// blue slider value has changed
- (IBAction)setBlurValue:(id)sender {
    
    if ([self.filter isKindOfClass:[BlurFilter class]] && self.slider) {
        BlurFilter *filter = (BlurFilter *)self.filter;
        filter.blurRadius = self.slider.value;
        filter.dirty = YES;
    }
}

// sepia intensity slider value has changed
- (IBAction)setIntensity:(id)sender {
    
    if ([self.filter isKindOfClass:[ModifyFilter class]] && self.slider) {
        ModifyFilter *filter = (ModifyFilter *)self.filter;
        filter.intensity = self.slider.value;
        filter.dirty = YES;
    }
}

// active or on/off switch has changed
- (IBAction)setActiveValue:(id)sender {
    
    self.filter.active = self.activeSwitch.on;
    self.filter.dirty = YES;
    if (self.slider) {
        self.slider.enabled = self.filter.active;
    }
}

- (void)update {
    
    if (self.filter) {
        self.activeSwitch.on = self.filter.active;
        if ([self.filter isKindOfClass:[BlurFilter class]]) {
            BlurFilter *blurFilter = (BlurFilter *)self.filter;
            if (self.slider) {
                self.slider.value = blurFilter.blurRadius;
                self.slider.enabled = self.filter.active;
            }
        }
        if ([self.filter isKindOfClass:[ModifyFilter class]]) {
            ModifyFilter *modifyFilter = (ModifyFilter *)self.filter;
            if (self.slider) {
                self.slider.value = modifyFilter.intensity;
                self.slider.enabled = self.filter.active;
            }
        }
    }
}


#pragma mark - UIStateRestoration

#define kImageFilterKey @"kImageFilterKey"

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.filter forKey:kImageFilterKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    self.filter = [coder decodeObjectForKey:kImageFilterKey];
}

- (void)applicationFinishedRestoringState {
    
    [self update];
}

@end
