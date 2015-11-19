/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.
*/

@import UIKit;
#import "iTunesRSSParser.h"


// This approach to parsing uses NSURLSession to asychronously retrieve the XML data. libxml's SAX parsing supports chunked parsing, with no requirement for the chunks to be discrete blocks of well formed XML. The primary purpose of this class is to start the download, configure the parser with a set of C callback functions, and pass downloaded data to it. In addition, the class maintains a number of state variables for the parsing.
@interface LibXMLParser : iTunesRSSParser

@end
