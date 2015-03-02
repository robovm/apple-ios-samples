/*
     File: Calculator.m
 Abstract: This file implements the Calculator class.
  Version: 1.2
 
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

#import "Calculator.h"

// These string constants contain the characters that the input: method accepts.
const NSString *Operators = @"+-*/";
const NSString *Equals    = @"=";
const NSString *Digits    = @"0123456789.";
const NSString *Period    = @".";
const NSString *Delete    = @"D";
const NSString *Clear     = @"C";


@interface Calculator ()
@property double operand;
@property (nonatomic, copy) NSString *operator;
// The calculator display (the value a harwdare-based calculator shows on its LCD screen).
@property (nonatomic, copy) NSMutableString *display;

@end


@implementation Calculator

#pragma mark Lifecycle

- init {
   if ((self = [super init])) {
      _display = [NSMutableString stringWithCapacity:20];
      _operator = nil;
   }
   return self;
}


#pragma mark Calculator Operation

/*
 * The input: method accepts the characters in the string constants
 * Operators, Equals, Digits, Period Delete, and Clear.
 *
 * The results of this method's computations are stored in _display.
 * This method uses operand and operator in its calculations.
 */
- (void) input:(NSString *) input_character {
   static BOOL last_character_is_operator = NO;
   BOOL bad_character;
   
   // Does input_character contain exactly one character?
   if (!(bad_character = !(input_character && [input_character length] == 1))) {
      
      // Is input_character in Digits?
      if ([Digits rangeOfString: input_character].length) {
         if (last_character_is_operator) {
            // Set the display to input_character.
            [self.display setString: input_character];
            
            last_character_is_operator = NO;
         }
         // Is input_character a digit, or is a period while a period has not been added to _display?
         else if (![input_character isEqualToString: (NSString *)Period] || [self.display rangeOfString: (NSString *)Period].location == NSNotFound) {
            // Add input_character to _display.
            [self.display appendString:input_character];
         }
      }
      
      // Is input_character in Operators or is it Equals?
      else if ([Operators rangeOfString:input_character].length || [input_character isEqualToString:(NSString *)Equals]) {
         if (!self.operator && ![input_character isEqualToString:(NSString *)Equals]) {
            // input_character is this calculation's operator.
            //
            // Save the operand and the operator.
            self.operand  = [[self displayValue] doubleValue];
            self.operator = input_character;
         }
         else {
            // input_character is in Operators or Equals.
            //
            // Perform the computation indicated by the saved operator between the saved operand and _display.
            // Place the result in _display.
            if (self.operator) {
               double operand2 = [[self displayValue] doubleValue];
               switch ([Operators rangeOfString: _operator].location) {
                  case 0:
                     self.operand = self.operand + operand2;
                     break;
                  case 1:
                     self.operand = self.operand - operand2;
                     break;
                  case 2:
                     self.operand = self.operand * operand2;
                     break;
                  case 3:
                     self.operand = self.operand / operand2;
                     break;
               }
               [self.display setString: [@(self.operand) stringValue]];
            }
            // Save the operation (if this is a chained computation).
            self.operator = ([input_character isEqualToString:(NSString *)Equals])? nil : input_character;
         }
         last_character_is_operator = YES;
      }
      // Is input_character Delete?
      else if ([input_character isEqualToString:(NSString *)Delete]) {
         // Remove the rightmost character from _display.
         NSInteger index_of_char_to_remove = [self.display length] - 1;
         if (index_of_char_to_remove >= 0) {
            [self.display deleteCharactersInRange:NSMakeRange(index_of_char_to_remove, 1)];
            last_character_is_operator = NO;
         }
      }
      // Is input_character Clear?
      else if ([input_character isEqualToString:(NSString *)Clear]) {
         // If there's something in _display, clear it.
         if ([self.display length]) {
            [self.display setString:[NSString string]];
         }
         // Otherwise, clear the saved operator.
         else {
            self.operator = nil;
         }
      }
      else {
         // input_character is an unexpected (invalid) character.
         bad_character = TRUE;
      }
   }
   if (bad_character) {
      // Raise exception for unexpected character.
      NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:@"The input_character parameter contains an unexpected value."
                                                     userInfo:@{@"arg0": input_character}];
      [exception raise];
   }
}


/*
 * The displayValue method retuns a copy of display.
 */
- (NSString *) displayValue {
   if ([self.display length]) {
      return [self.display copy];
   }
   return @"0";
}

@end
