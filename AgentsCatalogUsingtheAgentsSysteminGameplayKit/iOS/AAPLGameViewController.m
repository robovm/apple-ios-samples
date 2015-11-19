/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	iOS view controller. Handles switching demo scenes based on UI controls.
 */

#import "AAPLGameViewController.h"

#import "AAPLGameScene.h"

@interface AAPLGameViewController ()

@property AAPLSceneType sceneType;

@end

@implementation AAPLGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.ignoresSiblingOrder = YES;
    
    // Present the scene.
    [self selectScene:self.sceneType];
}

- (void)selectScene:(AAPLSceneType)sceneType {
    AAPLGameScene *scene = [AAPLGameScene sceneWithType:sceneType size:CGSizeMake(800, 600)];
    scene.scaleMode = SKSceneScaleModeAspectFit;
	SKView * skView = (SKView *)self.view;
    [skView presentScene:scene];

    self.navigationItem.title = scene.sceneName;
}

- (IBAction)goToPreviousScene:(UIBarButtonItem *)sender {
    if (--self.sceneType < 0) {
        self.sceneType = AAPLSceneTypesCount - 1;
    }
    [self selectScene:self.sceneType];
}

- (IBAction)goToNextScene:(UIBarButtonItem *)sender {
    if (++self.sceneType >= AAPLSceneTypesCount) {
        self.sceneType = 0;
    }

    [self selectScene:self.sceneType];
}

@end
