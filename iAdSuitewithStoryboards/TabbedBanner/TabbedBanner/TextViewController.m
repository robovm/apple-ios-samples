/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple view controller that manages a content view and an ADBannerView.
*/

#import "TextViewController.h"
#import "BannerViewController.h"

@interface TextViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UILabel *timerLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CFTimeInterval ticks;

@end

@implementation TextViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BannerViewActionWillBegin object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BannerViewActionDidFinish object:nil];
}

- (void)setText:(NSString *)text
{
    _text = [text copy];
    self.textView.text = text;
}

- (void)startTimer
{
    if (self.timer == nil) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    }
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerTick:(NSTimer *)timer
{
    // Timers are not guaranteed to tick at the nominal rate specified, so this isn't technically accurate.
    // However, this is just an example to demonstrate how to stop some ongoing activity, so we can live with that inaccuracy.
    self.ticks += 0.1;
    double seconds = fmod(self.ticks, 60.0);
    double minutes = fmod(trunc(self.ticks / 60.0), 60.0);
    double hours = trunc(self.ticks / 3600.0);
    self.timerLabel.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%04.1f", hours, minutes, seconds];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBeginBannerViewActionNotification:) name:BannerViewActionWillBegin object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishBannerViewActionNotification:) name:BannerViewActionDidFinish object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.textView.text = self.text;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopTimer];
}

- (void)willBeginBannerViewActionNotification:(NSNotification *)notification
{
    [self stopTimer];
}

- (void)didFinishBannerViewActionNotification:(NSNotification *)notification
{
    [self startTimer];
}

@end
