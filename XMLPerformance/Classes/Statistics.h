/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Collection of C functions for database storage of parser performance metrics.
*/

@import UIKit;
#import "iTunesRSSParser.h"

/* 
These functions encapsulate all interactions with a SQLite database used to store the amount of time taken to download 
and parse XML data. The measurements are stored by parser type, and aggregate queries retrieve the mean measurements, again
by parser type.
*/ 

// Close the database. This should be called when the application terminates.
void CloseStatisticsDatabase(void);

// Queries:

// Retrieve the number of measurements available for a parser of a given type.
NSUInteger NumberOfRunsForParserType(XMLParserType type);
// Retrieve the average number of seconds from starting the download to finishing the download for a parser of a given type.
double MeanDownloadTimeForParserType(XMLParserType type);
// Retrieve the average number of seconds spent in parsing code for a parser of a given type.
double MeanParseTimeForParserType(XMLParserType type);
// Retrieve the average number of seconds from starting the download to finishing the parse for a parser of a given type. 
double MeanTotalTimeForParserType(XMLParserType type);
// Delete all stored measurements. 
void ResetStatisticsDatabase(void);

// Store a measurement to the database.
void WriteStatisticToDatabase(XMLParserType type, double downloadDuration, double parseDuration, double totalDuration);


