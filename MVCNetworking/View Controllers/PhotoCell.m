/*
    File:       PhotoCell.m

    Contains:   A table view cell to display a photo.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "PhotoCell.h"

#import "Photo.h"

@implementation PhotoCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self != nil) {
    
        // Observe a bunch of our own properties so that the UI adjusts to any changes.
    
        [self addObserver:self forKeyPath:@"photo.displayName"    options:0 context:&self->_photo];
        [self addObserver:self forKeyPath:@"photo.date"           options:0 context:&self->_dateFormatter];
        [self addObserver:self forKeyPath:@"photo.thumbnailImage" options:0 context:&self->_photo];
        [self addObserver:self forKeyPath:@"dateFormatter"        options:0 context:&self->_dateFormatter];
    }
    return self;
}

- (void)dealloc
{
    // Remove our observers.
    
    [self removeObserver:self forKeyPath:@"photo.displayName"];
    [self removeObserver:self forKeyPath:@"photo.date"];
    [self removeObserver:self forKeyPath:@"photo.thumbnailImage"];
    [self removeObserver:self forKeyPath:@"dateFormatter"];

    // Clean up our memory.
    
    [self->_photo release];
    [self->_dateFormatter release];

    [super dealloc];
}

// Because we self-observe dateFormatter in order to update after a locale change, 
// we only want to fire KVO notifications if the date formatter actually changes (which 
// is infrequent in day-to-day operations.  So we override the setter and handle the 
// KVO notifications ourself.

@synthesize dateFormatter = _dateFormatter;

+ (BOOL)automaticallyNotifiesObserversOfDateFormatter
{
    return NO;
}

- (void)setDateFormatter:(NSDateFormatter *)newValue
{
    if (newValue != self->_dateFormatter) {
        [self willChangeValueForKey:@"dateFormatter"];
        [self->_dateFormatter release];
        self->_dateFormatter = [newValue retain];
        [self  didChangeValueForKey:@"dateFormatter"];
    }
}

@synthesize photo         = _photo;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // Called when various properties of the photo change; updates the cell accordingly.
{
    if (context == &self->_photo) {
        assert(object == self);
        
        if ([keyPath isEqual:@"photo.displayName"]) {
            if (self.photo == nil) {
                self.textLabel.text   = nil;
            } else {
                self.textLabel.text   = self.photo.displayName;
            }

            // iOS 3 has a bug where, if you set the text of a cell's label to something longer 
            // than the existing text, it doesn't expand the label to accommodate the longer 
            // text.  The end result is that the text gets needlessly truncated.  We fix 
            // this by triggering a re-layout whenever we change the text.
            
            [self setNeedsLayout];
        } else if ([keyPath isEqual:@"photo.thumbnailImage"]) {
            if (self.photo == nil) {
                self.imageView.image  = nil;
            } else {
                self.imageView.image  = self.photo.thumbnailImage;
            }
        } else {
            assert(NO);
        }
    } else if (context == &self->_dateFormatter) {
        NSString *  dateText;

        assert(object == self);
        assert([keyPath isEqual:@"photo.date"] || [keyPath isEqual:@"dateFormatter"]);
        
        dateText = nil;
        if (self.photo != nil) {
            if (self.dateFormatter == nil) {
                // If there's no date formatter, just use the date's description.  This is 
                // somewhat lame, and you wouldn't want to run this code path in general.
                dateText = [self.photo.date description];
            } else {
                dateText = [self.dateFormatter stringFromDate:self.photo.date];
            }
        }
        self.detailTextLabel.text = dateText;
        [self setNeedsLayout];      // see comment above
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
