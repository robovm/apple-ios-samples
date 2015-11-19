/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Creates and runs an instance of the parser type chosen by the user, and displays the parsed songs in a table. Selecting a row in the table navigates to a detail view for that song.
*/


@import UIKit;
#import "iTunesRSSParser.h"

@interface SongsViewController : UITableViewController <iTunesRSSParserDelegate>

// called by the ParserChoiceViewController based on the selected parser type
- (void)parseWithParserType:(XMLParserType)parserType;

@end
