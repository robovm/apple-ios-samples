/*
     File: LibXMLParser.h
 Abstract: Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.
  Version: 1.4
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
*/

#import <UIKit/UIKit.h>
#import <libxml/tree.h>
#import "iTunesRSSParser.h"

@class Song;

// This approach to parsing uses NSURLConnection to asychronously retrieve the XML data. libxml's SAX parsing supports chunked parsing, with no requirement for the chunks to be discrete blocks of well formed XML. The primary purpose of this class is to start the download, configure the parser with a set of C callback functions, and pass downloaded data to it. In addition, the class maintains a number of state variables for the parsing.
@interface LibXMLParser : iTunesRSSParser {
@private
    // Reference to the libxml parser context
    xmlParserCtxtPtr context;
    NSURLConnection *rssConnection;
    // Overall state of the parser, used to exit the run loop.
    BOOL done;
    // State variable used to determine whether or not to ignore a given XML element
    BOOL parsingASong;
    // The following state variables deal with getting character data from XML elements. This is a potentially expensive 
    // operation. The character data in a given element may be delivered over the course of multiple callbacks, so that
    // data must be appended to a buffer. The optimal way of doing this is to use a C string buffer that grows exponentially.
    // When all the characters have been delivered, an NSString is constructed and the buffer is reset.
    BOOL storingCharacters;
    NSMutableData *characterBuffer;
    // A reference to the current song the parser is working with.
    Song *currentSong;

    NSDateFormatter *parseFormatter;
}

@property BOOL storingCharacters;
@property (nonatomic, strong) NSMutableData *characterBuffer;
@property BOOL done;
@property BOOL parsingASong;
@property (nonatomic, strong) Song *currentSong;
@property (nonatomic, strong) NSURLConnection *rssConnection;
@property (nonatomic, strong) NSDateFormatter *parseFormatter;

@end
