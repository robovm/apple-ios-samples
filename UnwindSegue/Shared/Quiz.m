/*
     File: Quiz.m
 Abstract: Model class for a Quiz.  Manages loading the quiz 
 data (questions, answers) from a plist file, vending questions, and recording 
 responses.
 
  Version: 1.0
 
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

#import "Quiz.h"

NSString * const QuestionsListKey = @"QuestionList";
NSString * const QuestionTextKey = @"QuestionText";
NSString * const AnswerTextKey = @"AnswerText";
NSString * const AnswerKey = @"Answer";


@interface Quiz ()
/// Array of Question objects.
@property (strong) NSArray *questions;
@property (readwrite) NSUInteger correctlyAnsweredQuestions;
@property (readwrite) NSUInteger answeredQuestions;
@end


@implementation Quiz

//| ----------------------------------------------------------------------------
//! Initializes and retuns a newly created Quiz with the questions from a plist
//! file at questionsURL.
//
//! @param  questionsURL
//!         A url for a plist file containing a list of questions.
///
- (id)initWithQuestionsPlistAtURL:(NSURL*)questionsURL
{
    self = [super init];
    
    if (self)
    {
        NSData *questionsPlistData;
        NSDictionary *questionsPlistDict;
        NSArray *questionsList;
        
        // Load and deserialize the plist
        questionsPlistData = [NSData dataWithContentsOfURL:questionsURL];
        questionsPlistDict = [NSPropertyListSerialization propertyListWithData:questionsPlistData
                                                                       options:NSPropertyListImmutable
                                                                        format:nil
                                                                         error:NULL];
        questionsList = questionsPlistDict[QuestionsListKey];
        
        // Create a temporary NSMutableArray to hold the Question objects 
        // that will be created from the data in questionsList.
        NSMutableArray *questions = [NSMutableArray arrayWithCapacity:questionsList.count];
        
        for (NSDictionary *questionDict in questionsList) {
            Question *question = [[Question alloc] initWithQuestionDict:questionDict];
            
            // Observe changes to the selectedResponse property of the newly 
            // created Question object.  When a change is observed, the Quiz may 
            // need to update its answeredQuestions and
            // correctlyAnsweredQuestions properties.
            [question addObserver:self
                       forKeyPath:@"selectedResponse"
                          options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                          context:NULL];
            
            [questions addObject:question];
        }
        
        // Create an immutable array from the mutable questions array and  
        // assign it to the ivar backing the questions property.
        _questions = [[NSArray alloc] initWithArray:questions];
    }
    
    return self;
}


//| ----------------------------------------------------------------------------
- (void)dealloc
{
    // Unregister Key-Value observing notifications for all Questions.
    for (Question *question in self.questions)
        [question removeObserver:self forKeyPath:@"selectedResponse" context:NULL];
}


//| ----------------------------------------------------------------------------
//! Manual implementation of the getter for the percentageScore property.
//
//  Because percentageScore is a function of the correctlyAnsweredQuestions
//  and answeredQuestions, it is computed as needed instead of stored.
//
- (float)percentageScore
{
    return (float)self.correctlyAnsweredQuestions/(float)self.answeredQuestions;
}


//| ----------------------------------------------------------------------------
//! Manual implementation of the getter for the totalQuestions property.
//
- (NSUInteger)totalQuestions
{
    return self.questions.count;
}


//| ----------------------------------------------------------------------------
//! Returns the Question at the specified index.
//
//  Implementing this method allows other objects to use the subscript
//  operator to access Questions by their index.
//     Ex: Question *q = myQuiz[0];
//
- (Question*)objectAtIndexedSubscript:(NSInteger)idx
{
    // Call through to -questionAtIndex:
    return [self questionAtIndex:idx];
}


//| ----------------------------------------------------------------------------
//! Returns the Question at the specified index.
//
- (Question*)questionAtIndex:(NSUInteger)idx
{
    return [self.questions objectAtIndex:idx];
}


//| ----------------------------------------------------------------------------
//! Resets the Quiz, clearing the current score.
//
- (void)resetQuiz
{
    // NSArray forwards calls to -setValue:forKey: to all the objects 
    // within the array.
    [self.questions setValue:@(NSNotFound) forKey:@"selectedResponse"];
}

#pragma mark - 
#pragma mark Key Value Observing

//| ----------------------------------------------------------------------------
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"percentageScore"])
        // percentageScore is derived from answeredQuestions and
        // correctlyAnsweredQuestions.
        return [NSSet setWithObjects:@"answeredQuestions", @"correctlyAnsweredQuestions", nil];
    else
        return [super keyPathsForValuesAffectingValueForKey:key];
}


//| ----------------------------------------------------------------------------
//  Callback for key-value observing (KVO) change notifications.
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedResponse"])
    // The selectedResponse of a Question changed.
    {
        NSInteger previouslySelectedResponse = [change[NSKeyValueChangeOldKey] integerValue];
        NSInteger selectedResponse = [change[NSKeyValueChangeNewKey] integerValue];
        
        if (previouslySelectedResponse == NSNotFound && selectedResponse != NSNotFound)
            // If the question had not been answered but now is, increment
            // answeredQuestions.
            self.answeredQuestions++;
        else if (previouslySelectedResponse != NSNotFound && selectedResponse == NSNotFound)
            // If the question had been answered but no longer is, decrement
            // answeredQuestions. This will occur when the quiz is being reset.
            self.answeredQuestions--;
        
        if (selectedResponse == [(Question*)object correctResponse] &&
            previouslySelectedResponse != [(Question*)object correctResponse])
            // If the current response is correct and the previous response was
            // incoorect, increment correctlyAnsweredQuestions.
            self.correctlyAnsweredQuestions++;
        else if (previouslySelectedResponse == [(Question*)object correctResponse] &&
                 selectedResponse != [(Question*)object correctResponse])
            // If the current response is incorrect and the previous response was
            // coorect, decrement correctlyAnsweredQuestions.
            self.correctlyAnsweredQuestions--;
    }
    else
        // Always invoke the super's implementation for unhandled keyPath's.
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
