/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    'AAPLMovieDetailController' implements an interface controller diplaying a WKInterfaceMovie with a poster frame and a URL.
*/

#import "AAPLMovieDetailController.h"

@interface AAPLMovieDetailController ()

@property (weak, nonatomic) IBOutlet WKInterfaceMovie *movie;

@end

@implementation AAPLMovieDetailController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Obtain a URL pointing to the movie to play.
    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"Ski1" withExtension:@"m4v"];
    
    // Setup the `movie` interface object with the URL to play.
    [self.movie setMovieURL:movieURL];
    
    // Provide a poster image to be displayed in the movie interface object prior to playback.
    [self.movie setPosterImage:[WKImage imageWithImageName:@"Ski1"]];
}

@end



