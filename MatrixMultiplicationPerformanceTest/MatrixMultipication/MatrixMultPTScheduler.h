/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for dispatching BLAS sgemm and Metal matrix multipication performance tests
 */

#import <Foundation/Foundation.h>

// Keys for the Performance dictionary      // For values
extern NSString* kMatrixMultTestID;         // Unsigned Short 32
extern NSString* kMatrixARowCount;          // Unsigned Short 16
extern NSString* kMatrixAColCount;          // Unsigned Short 16
extern NSString* kMatrixBRowCount;          // Unsigned Short 16
extern NSString* kMatrixBColCount;          // Unsigned Short 16
extern NSString* kMatrixCPaddRowCount;      // Unsigned Short 16
extern NSString* kMatrixCPaddColCount;      // Unsigned Short 16
extern NSString* kMatrixMultGFlopsBlas;     // Double
extern NSString* kMatrixMultGFlopsMetal;    // Double
extern NSString* kMatrixMultTimeBlas;       // Double
extern NSString* kMatrixMultTimeMetal;      // Double
extern NSString* kMatrixMultLength;         // Double

// Keys for the performnace log dictionary
extern NSString* kMatrixLogTestID;          // Unsigned Short 32
extern NSString* kMatrixLogDimensions;      // String
extern NSString* kMatrixLogPerformance;     // String

// Notifications
extern NSString* kMatrixNotificationIsReadyPerfData;
extern NSString* kMatrixNotificationIsReadyLogData;
extern NSString* kMatrixNotificationIsDoneTests;

// Forward decelaration for the matrix multipication mediator
@class MatrixMultPTScheduler;

// Matrix multipication delegate for finalizing the performance
// data dictionary - e.g., post processing such as logging or
// populating UI with the data.
@protocol MatrixMultPTSchedulerfDelegate <NSObject>

@optional
// Implement this to provide data for the elements of the
// input matrices A and B.  If this is not implemented
// random data is generated using uniform real distribution
// for the elements of the input matrices A and B.  The type
// here represents the matrix type being initialized.  So,
// matrix A expect type = 'a' and for matrix B, type = 'b'.
- (void) matrix:(const uint8_t)type
           rows:(const uint16_t)rows
        columns:(const uint16_t)columns
           data:(float *)data;

// Implement this to provide dimension triplets for the
// input and output matrices in a matrix multipication
// performance test
- (void) dimensions:(uint16_t *)dims
              count:(const uint32_t)count;

@end

// Metal and Blas matrix multipication performance test mediator
@interface MatrixMultPTScheduler: NSObject

// Optional and required delgates
@property (nonatomic, assign) id<MatrixMultPTSchedulerfDelegate> delegate;

// Performance data.  This is an array of dictionaries
// containing the performance data from the matrix
// multipication test and populated after a call and
// subsequent completion of the dispatch method.
@property (nonatomic, readonly) NSMutableArray* data;

// Performance log results.  This is an array of
// dictionaries containing the performance data
// from the matrix multipication tests, with each
// dictionary containing two strings represnting
// matrix dimensions used in the performance tests
// and a string representing the performance results.
@property (nonatomic, readonly) NSMutableArray* logs;

// Matrix elements have random values
@property (nonatomic, readonly) BOOL isRandomized;

// Matrix dimensions with the number of elements
// equal to 3 times the number of tests.
@property (nonatomic) uint16_t* dims;

// Log the test results
@property (nonatomic) BOOL print;

// Number of loops per test
@property (nonatomic) uint32_t loops;

// Number of tests
@property (nonatomic) uint32_t tests;

// Greatest lower bound of the range of values that may
// be used for uniform integer distribution.
@property (nonatomic) uint16_t min;

// Least upper bound of the range of values that may be
// used for uniform integer distribution.
@property (nonatomic) uint16_t max;

// Generate some random values for matrices A = [m x n]
// and B = [n x k] and run matrix multipication Metal
// compute and Blas sgemm performance tests
- (void) dispatch;

@end
