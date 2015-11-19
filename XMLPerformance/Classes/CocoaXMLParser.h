/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of iTunesRSSParser that uses the Foundation framework's NSXMLParser for parsing the XML data.
*/

@import UIKit;
#import "iTunesRSSParser.h"


@interface CocoaXMLParser : iTunesRSSParser <NSXMLParserDelegate>

@end
