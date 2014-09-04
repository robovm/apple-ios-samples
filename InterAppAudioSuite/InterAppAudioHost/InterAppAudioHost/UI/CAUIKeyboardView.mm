/*
     File: CAUIKeyboardView.mm
 Abstract: 
  Version: 1.1.2
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "CAUIKeyboardView.h"
#import "AppDelegate.h"

#import <UIKit/UIGestureRecognizer.h>

#define kWhiteKeyWidthRatio		0.268f
#define kBlackKeyHeightRatio	0.634f
#define kBlackKeyWidthRatio		0.159f
#define kDbKeyOffsetRatio		0.201f
#define kEbKeyOffsetRatio		0.232f
#define kGbKeyOffsetRatio		0.146f
#define kAbKeyOffsetRatio		0.195f
#define kBbKeyOffsetRatio		0.234f

#pragma mark - Utility functions
typedef enum NoteIdentifier {
	C = 0, Db= 1, D = 2, Eb= 3, E = 4, F = 5, Gb= 6, G = 7, Ab= 8, A = 9, Bb= 10, B = 11
} NoteIdentifier;

BOOL IsWhiteKey(NSInteger note) {
	NSInteger value = note % 12;
	
	switch (value) {
		case 0: case 2: case 4: case 5: case 7: case 9: case 11:
			return YES;
		default:
			return NO;
	}
}

BOOL IsNoteSharp(NSInteger note) {
	NSInteger value = note % 12;
	
	switch (value) {
		case 0: case 2: case 4: case 5: case 7: case 9: case 11:
			return false;
		case 1: case 3: case 6: case 8: case 10:
			return true;
	}
	return false;
}

NoteIdentifier IdentifierForNote(NSInteger note) {
	NSInteger value = note % 12;
	return (NoteIdentifier)value;
}

NSInteger NumWhiteKeysBetweenNotes(NSInteger startNote, NSInteger endNote) {
	// figure out how many octaves between notes
	if (startNote == endNote)
		return 0;
	
	NSInteger keys = 0;
	NSInteger octaves = ((endNote - startNote) / 12);
	if (octaves > 0)
		keys = octaves * 7;
	
	if (IsWhiteKey(startNote))
		keys--;
	
	NSInteger extraNotes = (endNote - startNote) % 12;
	for (NSInteger indexKey = endNote - extraNotes; indexKey < endNote; indexKey++) {
		if (IsWhiteKey(indexKey))
			keys++;
	}
	
	return keys;
}
	
BOOL CGPointInRect(CGPoint aPoint, CGRect aRect) {
	return aPoint.x >= aRect.origin.x &&
	aPoint.x < (aRect.origin.x + aRect.size.width) &&
	aPoint.y >= aRect.origin.y &&
	aPoint.y < (aRect.origin.y + aRect.size.height);
}

#pragma mark - CAUIKeyboardView implementation
@implementation CAUIKeyboardView

@synthesize whiteKeyWidth, whiteKeyHeight, blackKeyWidth, blackKeyHeight;
@synthesize noteDownColor;
@synthesize engine = _engine;

#pragma mark Initialization
- (void) initialize {
    _engine = NULL;
	whiteKeyHeight	= floorf(self.frame.size.height);
	whiteKeyWidth	= roundf(whiteKeyHeight * kWhiteKeyWidthRatio);
	blackKeyHeight	= roundf(whiteKeyHeight * kBlackKeyHeightRatio);
	blackKeyWidth	= roundf(whiteKeyHeight * kBlackKeyWidthRatio);
	
	dbKeyOffset		= roundf(whiteKeyHeight * kDbKeyOffsetRatio);
	ebKeyOffset		= roundf(whiteKeyHeight * kEbKeyOffsetRatio);
	gbKeyOffset		= roundf(whiteKeyHeight * kGbKeyOffsetRatio);
	abKeyOffset		= roundf(whiteKeyHeight * kAbKeyOffsetRatio);
	bbKeyOffset		= roundf(whiteKeyHeight * kBbKeyOffsetRatio);
	
	self.noteDownColor = [[UIColor redColor] colorWithAlphaComponent: .7];
	notesDown = [NSMutableSet setWithCapacity: 0];
}

- (id) initWithCoder:(NSCoder *) aDecoder {
	self = [super initWithCoder: aDecoder];
	if (self) 
		[self initialize];

	return self;
}

#pragma mark Utility methods
- (NSInteger) offsetForBlackKey:(NSInteger) note {
	NoteIdentifier identifier = IdentifierForNote(note);
	switch (identifier) {
		case Db:
			return dbKeyOffset;
		case Eb:
			return ebKeyOffset;
		case Gb:
			return gbKeyOffset;
		case Ab:
			return abKeyOffset;
		case Bb:
			return bbKeyOffset;
		default:
			return 0;
	}
}

- (CGRect) noteRectForNote:(NSInteger) note inRect:(CGRect) rect {
	// starting with the starting note, calculate the rect that the note to be drawn is in
	// if the starting note is a sharp, we need to get the previous white key
	// if the starting note is a white key, we can calculate the location of the new note
	
	CGRect firstNoteRect = CGRectZero;
	CGRect firstWhiteNoteRect = CGRectZero;
	
	BOOL startingNoteSharp = IsNoteSharp(displayKeyStart);
	firstWhiteNoteRect = CGRectMake(rect.origin.x, rect.origin.y, self.whiteKeyWidth, self.whiteKeyHeight);
	
	if (startingNoteSharp) {
		firstNoteRect = CGRectMake(rect.origin.x, rect.origin.y, self.blackKeyWidth, self.blackKeyHeight);
		
		// we need to calculate the starting location of the previous white key
		NSInteger offset = [self offsetForBlackKey: note];
		firstWhiteNoteRect.origin.x -= offset;
	}
	else
		firstNoteRect = firstWhiteNoteRect;
	
	if (displayKeyStart == note)
		return firstNoteRect;
	
	// calculate distance in white keys between note and displayKeyStart
	NSInteger whiteInterval = NumWhiteKeysBetweenNotes(displayKeyStart, note) * self.whiteKeyWidth;
	NSInteger lastWhiteStart = firstWhiteNoteRect.origin.x + whiteInterval;
	
	BOOL endingNoteSharp = IsNoteSharp(note);
	if (!endingNoteSharp)
		return CGRectMake(lastWhiteStart+self.whiteKeyWidth, rect.origin.y, self.whiteKeyWidth, self.whiteKeyHeight);
	else
		return CGRectMake(lastWhiteStart+ [self offsetForBlackKey:note], rect.origin.y, self.blackKeyWidth, self.blackKeyHeight);
}

- (CGFloat) leftEdgeOfNote:(NSInteger) note {
	CGRect rect = [self noteRectForNote: note inRect: self.bounds];
	return rect.origin.x;
}

- (CGFloat) rightEdgeOfNote:(NSInteger) note {
	CGRect rect = [self noteRectForNote: note inRect: self.bounds];
	return rect.origin.x + rect.size.width;
}

- (NSInteger) displayKeyStart {
	return displayKeyStart;
}

- (void) setDisplayKeyStart:(NSInteger) note {
	if (note >= 0 && note < 128 && note != displayKeyStart) {
		displayKeyStart = note;
		
		[self prepareBackground];
		[self setNeedsDisplay];
	}
}

- (NSInteger) noteAtPoint: (CGPoint) point {
	// check to see which white key we are in
	CGRect firstWhiteNoteRect = CGRectZero;
	
	BOOL startingNoteSharp = IsNoteSharp(displayKeyStart);
	firstWhiteNoteRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, whiteKeyWidth, whiteKeyHeight);
	
	if (startingNoteSharp) {
		// we need to calculate the starting location of the previous white key
		NSInteger offset = [self offsetForBlackKey: displayKeyStart];
		firstWhiteNoteRect.origin.x -= offset;
	}
	
	NSInteger whiteNoteNumber = (point.x - firstWhiteNoteRect.origin.x)/whiteKeyWidth;
	NSInteger noteNumber = displayKeyStart + (((float)whiteNoteNumber/7) * 12);
	if (IsNoteSharp(noteNumber))
		noteNumber++;
	
	if (point.y <= blackKeyHeight) {	// we could be on a black key, so we need to check the black keys surrounding the white key
		// if we are not on a c or and f, check the previous flat
		BOOL foundFlat = NO;
		NoteIdentifier identifier = IdentifierForNote(noteNumber);
		if (identifier != C && identifier != F) {
			if (CGPointInRect(point, [self noteRectForNote:noteNumber-1 inRect:self.bounds])) {
				noteNumber--;
				foundFlat = YES;
			}
		}
		// check the next flat
		if (!foundFlat && CGPointInRect(point, [self noteRectForNote:noteNumber+1 inRect:self.bounds]))
			noteNumber++;
	}
	
	return noteNumber;
}

#pragma mark Drawing methods
- (UIBezierPath *) bezierPathForNote: (NSInteger) note {
	if (note < 0 || note > 127)
		return nil;
	
	if (!IsWhiteKey(note))
		return [UIBezierPath bezierPathWithRect: [self noteRectForNote: note inRect: self.bounds]];
	else {
		UIBezierPath *path = [UIBezierPath bezierPath];
		CGFloat edge;
		if (note == 0 || IsWhiteKey(note-1)) { // special case the very first note
			edge = [self leftEdgeOfNote: note] + 1;
            
			// if the previous key is a white key, then the left edge is the same as the edge of the note
			[path moveToPoint: CGPointMake(edge, whiteKeyHeight-1)];
			[path addLineToPoint: CGPointMake(edge + whiteKeyWidth-1, whiteKeyHeight-1)];
			[path addLineToPoint: CGPointMake(edge + whiteKeyWidth-1, blackKeyHeight)];
			
			edge = [self leftEdgeOfNote: note+1];
			[path addLineToPoint: CGPointMake(edge, blackKeyHeight)];
			[path addLineToPoint: CGPointMake(edge, 1)];
			edge = [self leftEdgeOfNote: note] + 1;
		} else {
			edge = [self rightEdgeOfNote: note-1];
			[path moveToPoint: CGPointMake(edge, 1)];
			[path addLineToPoint: CGPointMake(edge, blackKeyHeight)];
			
			edge = [self leftEdgeOfNote: note];
			[path addLineToPoint: CGPointMake(edge, blackKeyHeight)];
			[path addLineToPoint: CGPointMake(edge, whiteKeyHeight-1)];
			[path addLineToPoint: CGPointMake(edge + whiteKeyWidth-1, whiteKeyHeight-1)];
			
            // if the next key is a white key, then the right edge is the same as the edge of the note
			if (note == 127 || IsWhiteKey(note+1)) {
				edge = [self rightEdgeOfNote: note]-1;
				[path addLineToPoint: CGPointMake(edge, 1)];
			} else {
				[path addLineToPoint: CGPointMake(edge+ whiteKeyWidth-1, blackKeyHeight)];
				
				edge = [self leftEdgeOfNote: note+1];
				[path addLineToPoint: CGPointMake(edge, blackKeyHeight)];
			}
		}
		[path addLineToPoint: CGPointMake(edge, 1)];
		[path closePath];
		
		return path;
	}
	
	return nil;
}

- (void) drawRect:(CGRect) rect {
	[super drawRect: rect];
	
	CGRect myFrame = self.bounds;
    
	// prepares the image cache of the keyboard
	if (!imageCache)
		[self prepareBackground];
	
	[imageCache drawInRect: myFrame];
	
	[noteDownColor set];
	
	for (NSNumber *noteDown in notesDown) {
		NSInteger note = [noteDown integerValue];
		if (IsNoteSharp(note))
			UIRectFill([self noteRectForNote: note inRect: self.bounds]);
		else {
			UIBezierPath *path = [self bezierPathForNote: note];
			if (path)
				[path fill];
		}
	}
}

/* We draw the keyboard into a cache for performance reasons so that our draw rect only has to draw the notes that are currently pressed */
- (void) prepareBackground {
	UIGraphicsBeginImageContext(self.bounds.size);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
    
	displayKeyEnd = 127;
	CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
	CGContextFillRect(ctx, self.bounds);
	
	CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
	CGContextStrokeRect(ctx, self.bounds);
	
	CGRect noteRect = CGRectZero;
	NSInteger keyIndex, startKey = displayKeyStart;
	if (startKey > 0 == !IsWhiteKey(startKey-1))
		startKey--;
	
	for (keyIndex = startKey; keyIndex < 128; keyIndex++) {
		if ([notesDown containsObject: @(keyIndex)])
			continue;
		
		noteRect = [self noteRectForNote: keyIndex inRect: self.bounds];
		
		if (noteRect.origin.x > self.frame.origin.x + self.frame.size.width) {
			displayKeyEnd = keyIndex-1;
			break;
		}
		if (IsNoteSharp(keyIndex))
			CGContextFillRect(ctx, noteRect);
		else {
			CGContextStrokeRect(ctx, noteRect);
			
			// draw the note label if this is a C
			NoteIdentifier identifier = IdentifierForNote(keyIndex);
			if (identifier == C) {
				if (!labelAttributes) {
					UIFont *font = [UIFont systemFontOfSize: 12];
					NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
					paraStyle.alignment = NSTextAlignmentCenter;
					
					labelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: font, NSFontAttributeName,
									   paraStyle, NSParagraphStyleAttributeName,
									   [UIColor grayColor], NSForegroundColorAttributeName, nil];
				}
				NSAttributedString *label = [[NSAttributedString alloc]initWithString:[NSString stringWithFormat: @"C%d", (int)(keyIndex / 12) - 1] attributes: labelAttributes];
				[label drawInRect: CGRectMake(noteRect.origin.x + 1, noteRect.origin.y + self.whiteKeyHeight - 16, noteRect.size.width -2, 12)];
			}
			[[UIColor blackColor] set];
		}
	}
    
	if (noteRect.origin.x + noteRect.size.width < self.bounds.size.width) {
		CGContextSetFillColorWithColor(ctx, [UIColor darkGrayColor].CGColor);
		CGFloat rightEdge = noteRect.origin.x + noteRect.size.width;
		CGContextFillRect(ctx, CGRectMake(rightEdge, 0, self.bounds.size.width - rightEdge, self.bounds.size.height));
	}
	
	imageCache = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
    [self setNeedsDisplay];
}

#pragma mark Event handling
- (OSStatus) playNote:(UInt32) note velocity: (UInt32) velocity {
	const UInt32 noteOnCommand = kMidiMessage_NoteOn << 4 | 0;
    OSStatus result =  -1;
    if (self.engine){
        AudioUnit au = [self.engine getAudioUnitInstrument];
        result = MusicDeviceMIDIEvent(au, noteOnCommand, note, 100, 0);
    }
	return result;
}

- (OSStatus) stopNote:(UInt32) note {
	const UInt32 noteOffCommand = kMidiMessage_NoteOff << 4 | 0;
    OSStatus result =  -1;
    if (self.engine)
        result = MusicDeviceMIDIEvent([self.engine getAudioUnitInstrument], noteOffCommand, note, 100, 0);
	
	return result;
}

- (OSStatus) stopAllNotes {
	const UInt32 allNotesOffCommand = kMidiController_AllNotesOff << 4 | 0;
    OSStatus result =  -1;
    if (self.engine)
        result = MusicDeviceMIDIEvent([self.engine getAudioUnitInstrument], allNotesOffCommand, 0, 0, 0);
    
	return result;
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
    
	for (UITouch *touch in touches) {
		CGPoint loc = [touch locationInView: self];
		NSNumber * note = @([self noteAtPoint: loc]);
		
		if (![notesDown containsObject: note])
			[notesDown addObject: note];
		
		CGRect noteRect = [self noteRectForNote:[note intValue] inRect:self.bounds];
        
		// generate a 1 to 127 value based on the vertical position of the tap
		NSInteger margin = 6;
		Float32 velocity = 127;
		
		CGFloat adjustedPoint = loc.y - noteRect.origin.y;
		if (adjustedPoint > noteRect.size.height - margin)
			velocity = 127;
		else if (adjustedPoint > margin) {
			velocity = (adjustedPoint - margin) / (noteRect.size.height - margin * 2);
			velocity = velocity * 127;
		}
		[self playNote: [note unsignedIntValue] velocity: velocity];
	}
	[self setNeedsDisplay];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
    
	for (UITouch *touch in touches) {
		CGPoint previousLoc = [touch previousLocationInView: self];
		CGPoint currentLoc  = [touch locationInView: self];
		
		BOOL previousInView = CGPointInRect(previousLoc, self.bounds);
		BOOL currentInView  = CGPointInRect(currentLoc, self.bounds);
		
		NSInteger previousNote, currentNote;
		
		previousNote = previousInView ? [self noteAtPoint: previousLoc] : -1;
		currentNote  = currentInView  ? [self noteAtPoint: currentLoc]  : -1;
		
		// if the previous and current note match, don't do anything
		// otherwise, if the note has changed, end previous note, and start new note
		if (previousNote != currentNote) {
			if (previousNote > -1) {
                
				[notesDown removeObject: @(previousNote)];
				// end the note
				OSStatus result = [self stopNote: (UInt32)previousNote];
				if (result != noErr)
					NSLog(@"Error stopping note %ld: %d", (long)previousNote, (int)result);
			}
			
			if (currentNote >= -1) {
				if (![notesDown containsObject: @(currentNote)])
					[notesDown addObject: @(currentNote)];
				
				// start the new note
				OSStatus result = [self playNote: (UInt32)currentNote velocity: 100];
				if (result != noErr)
					NSLog(@"Error playing note %ld: %d", (long)currentNote, (int)result);
			}
		}
	}
	[self setNeedsDisplay];
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
	for (UITouch *touch in touches) {
		CGPoint currentLoc  = [touch locationInView: self];
        CGPoint previousLoc = [touch previousLocationInView:self];
        
		NSNumber *note = @([self noteAtPoint: currentLoc]);
		NSNumber *prevNote = @([self noteAtPoint: previousLoc]);
		
		if ([notesDown containsObject: note]) {
			[notesDown removeObject: note];
        } else  if ([notesDown containsObject: prevNote]){
			[notesDown removeObject: prevNote];
			note = prevNote;
        }
		
		// end the note
		OSStatus result = [self stopNote: [note unsignedIntValue]];
		if (result != noErr)
			NSLog(@"Error stopping note %lu: %d", [note unsignedLongValue], (int)result);
	}
	[self setNeedsDisplay];
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
	[notesDown removeAllObjects];
	[self setNeedsDisplay];
	
	// end all playing notes
	OSStatus result = [self stopAllNotes];
	if (result != noErr)
		NSLog(@"Error stopping all notes: %d", (int)result);
}

@end
