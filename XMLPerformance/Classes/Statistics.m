/*
     File: Statistics.m
 Abstract: Collection of C functions for database storage of parser performance metrics.
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

#import "Statistics.h"

// This includes the header for the SQLite library.
#import <sqlite3.h>

static sqlite3 *database = NULL;
static sqlite3_stmt *insert_statement = NULL;
static sqlite3_stmt *count_statement = NULL;
static sqlite3_stmt *mean_download_time_statement = NULL;
static sqlite3_stmt *mean_parse_time_statement = NULL;
static sqlite3_stmt *mean_download_and_parse_time_statement = NULL;
static sqlite3_stmt *reset_statement = NULL;

// Returns a reference to the database, creating and opening if necessary.
sqlite3 *Database(void) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    if (database == NULL) {
        // First, test for existence.
        BOOL success;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"stats.sqlite"];
        if ([fileManager fileExistsAtPath:writableDBPath] == NO) {
            // The writable database does not exist, so copy the default to the appropriate location.
            NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"stats" ofType:@"sqlite"];
            success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
            if (!success) {
                NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
            }
        }
        // Open the database. The database was prepared outside the application.
        if (sqlite3_open([writableDBPath UTF8String], &database) != SQLITE_OK) {
            // Even though the open failed, call close to properly clean up resources.
            sqlite3_close(database);
            database = NULL;
            NSCAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
            // Additional error handling, as appropriate...
        }
    }
    return database;
}

// Close the database. This should be called when the application terminates.
void CloseStatisticsDatabase() {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    // Finalize (delete) all of the SQLite compiled queries. 
    if (insert_statement != NULL) {
        sqlite3_finalize(insert_statement);
        // reassign the pointer to NULL so that it will be correctly reinitialized if needed later. This pattern repeats for the rest of the statements below.
        insert_statement = NULL;
    }
    if (count_statement != NULL) {
        sqlite3_finalize(count_statement);
        count_statement = NULL;
    }
    if (mean_download_time_statement != NULL) {
        sqlite3_finalize(mean_download_time_statement);
        mean_download_time_statement = NULL;
    }
    if (mean_parse_time_statement != NULL) {
        sqlite3_finalize(mean_parse_time_statement);
        mean_parse_time_statement = NULL;
    }
    if (mean_download_and_parse_time_statement != NULL) {
        sqlite3_finalize(mean_download_and_parse_time_statement);
        mean_download_and_parse_time_statement = NULL;
    }
    if (reset_statement != NULL) {
        sqlite3_finalize(reset_statement);
        reset_statement = NULL;
    }
    if (database == NULL) return;
    // Close the database.
    if (sqlite3_close(database) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(database));
    }
    database = NULL;
}

// Retrieve the number of measurements available for a parser of a given type.
NSUInteger NumberOfRunsForParserType(XMLParserType type) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (count_statement == NULL) {
        // Prepare (compile) the SQL statement.
        static const char *sql = "SELECT COUNT(*) FROM statistic WHERE parser_type = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &count_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    // Bind the parser type to the statement.
    if (sqlite3_bind_int(count_statement, 1, type) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    // Execute the query.
    int success = sqlite3_step(count_statement);
    NSUInteger numberOfRuns = 0;
    if (success == SQLITE_ROW) {
        // Store the value of the first and only column for return.
        numberOfRuns = sqlite3_column_int(count_statement, 0);
    } else {
        NSCAssert1(0, @"Error: failed to execute query with message '%s'.", sqlite3_errmsg(db));
    }
    // Reset the query for the next use.
    sqlite3_reset(count_statement);
    return numberOfRuns;
}

// Retrieve the average number of seconds from starting the download to finishing the download for a parser of a given type.
double MeanDownloadTimeForParserType(XMLParserType type) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (mean_download_time_statement == NULL) {
        static const char *sql = "SELECT AVG(download_duration) FROM statistic WHERE parser_type = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &mean_download_time_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    if (sqlite3_bind_int(mean_download_time_statement, 1, type) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    int success = sqlite3_step(mean_download_time_statement);
    double meanValue = 0;
    if (success == SQLITE_ROW) {
        meanValue = sqlite3_column_double(mean_download_time_statement, 0);
    } else {
        NSCAssert1(0, @"Error: failed to execute query with message '%s'.", sqlite3_errmsg(db));
    }
    // Reset the query for the next use.
    sqlite3_reset(mean_download_time_statement);
    return meanValue;
}

// Retrieve the average number of seconds spent in parsing code for a parser of a given type.
double MeanParseTimeForParserType(XMLParserType type) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (mean_parse_time_statement == NULL) {
        static const char *sql = "SELECT AVG(parse_duration) FROM statistic WHERE parser_type = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &mean_parse_time_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    if (sqlite3_bind_int(mean_parse_time_statement, 1, type) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    int success = sqlite3_step(mean_parse_time_statement);
    double meanValue = 0;
    if (success == SQLITE_ROW) {
        meanValue = sqlite3_column_double(mean_parse_time_statement, 0);
    } else {
        NSCAssert1(0, @"Error: failed to execute query with message '%s'.", sqlite3_errmsg(db));
    }
    // Reset the query for the next use.
    sqlite3_reset(mean_parse_time_statement);
    return meanValue;
}

// Retrieve the average number of seconds from starting the download to finishing the parse for a parser of a given type. This is the total amount of time the parser needs to do all of its work.
double MeanTotalTimeForParserType(XMLParserType type) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (mean_download_and_parse_time_statement == NULL) {
        static const char *sql = "SELECT AVG(total_duration) FROM statistic WHERE parser_type = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &mean_download_and_parse_time_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    if (sqlite3_bind_int(mean_download_and_parse_time_statement, 1, type) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    int success = sqlite3_step(mean_download_and_parse_time_statement);
    double meanValue = 0;
    if (success == SQLITE_ROW) {
        meanValue = sqlite3_column_double(mean_download_and_parse_time_statement, 0);
    } else {
        NSCAssert1(0, @"Error: failed to execute query with message '%s'.", sqlite3_errmsg(db));
    }
    // Reset the query for the next use.
    sqlite3_reset(mean_download_and_parse_time_statement);
    return meanValue;
}

// Delete all stored measurements. You may want to do this after running the application using performance tools, which add considerable overhead and will distort the measurements. This is also the case if you were using the debugger, particularly if you were pausing execution.
void ResetStatisticsDatabase(void) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (reset_statement == NULL) {
        static const char *sql = "DELETE FROM statistic";
        if (sqlite3_prepare_v2(db, sql, -1, &reset_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    int success = sqlite3_step(reset_statement);
    if (success == SQLITE_ERROR) {
        NSCAssert1(0, @"Error: failed to execute query with message '%s'.", sqlite3_errmsg(db));
    }
    // Reset the query for the next use.
    sqlite3_reset(reset_statement);
}

// Store a measurement to the database.
void WriteStatisticToDatabase(XMLParserType type, double downloadDuration, double parseDuration, double totalDuration) {
    NSCAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    sqlite3 *db = Database();
    if (insert_statement == NULL) {
        static const char *sql = "INSERT INTO statistic (parser_type, download_duration, parse_duration, total_duration) VALUES(?, ?, ?, ?)";
        if (sqlite3_prepare_v2(db, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSCAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
        }
    }
    if (sqlite3_bind_int(insert_statement, 1, type) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }    
    if (sqlite3_bind_double(insert_statement, 2, downloadDuration) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    if (sqlite3_bind_double(insert_statement, 3, parseDuration) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    if (sqlite3_bind_double(insert_statement, 4, totalDuration) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to bind variable with message '%s'.", sqlite3_errmsg(db));
    }
    int success = sqlite3_step(insert_statement);
    sqlite3_reset(insert_statement);
    if (success == SQLITE_ERROR) {
        NSCAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(db));
    }
}
