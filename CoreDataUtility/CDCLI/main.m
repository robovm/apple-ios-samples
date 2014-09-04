/*
     File: main.m
 Abstract: The main file.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


#import "Run.h"

NSManagedObjectModel *managedObjectModel();
NSManagedObjectContext *managedObjectContext();
NSURL *applicationLogDirectory();

NSString *STORE_TYPE;
NSString *STORE_FILENAME;
NSString *SUPPORT_DIRECTORY;


int main (int argc, const char * argv[])
{
    @autoreleasepool {
        
        STORE_TYPE = NSXMLStoreType;
        STORE_FILENAME = @"CDCLI.cdcli";
        SUPPORT_DIRECTORY = @"CDCLI";
        
        NSManagedObjectModel *mom = managedObjectModel();
        NSLog(@"mom: %@", mom);	
        
        if (applicationLogDirectory() == nil) {
            NSLog(@"Could not find application logs directory\nExiting...");
            exit(1);
        }
        
        /*
         Get the managed object context and use it to create a new instance of the Run entity.
         */
        NSManagedObjectContext *moc = managedObjectContext();
        
        NSEntityDescription *runEntity = [[mom entitiesByName] objectForKey:@"Run"];
        Run *run = [[Run alloc] initWithEntity:runEntity
                insertIntoManagedObjectContext:moc];
        
        /*
         Tell the Run instance what its process ID is.
         */
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        run.processID = [processInfo processIdentifier];
        
        NSLog(@"run.processID: %ld", run.processID);
        
        
        /*
         Save the context to commit the new Run instance to the persistent store.
         */
        NSError *error = nil;
        
        if (![managedObjectContext() save: &error]) {
            NSLog(@"Error while saving\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
            exit(1);
        }
        
        /*
         Create a fetch request to fetch all instances of the Run entity ("all" is implied by not providing a predicate) returned in chronological order (sort by date).
         */
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Run"];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"date" ascending:YES];
        
        [request setSortDescriptors:@[sortDescriptor]];
        
        /*
         Execute the fetch request.
         */
        error = nil;
        NSArray *fetchedArray = [moc executeFetchRequest:request error:&error];
        
        if (fetchedArray == nil) {
            NSLog(@"Error while fetching\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
            exit(1);
        }
        
        /*
         List the Run instances returned from the fetch request.
         */
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSLog(@"%@ run history:", [processInfo processName]);
        
        for (Run *aRun in fetchedArray) {
            NSLog(@"On %@ as process ID %ld", [formatter stringForObjectValue:aRun.date], aRun.processID);
        }
                
        return 0;
    }
}



NSManagedObjectModel *managedObjectModel() 
{
	static NSManagedObjectModel *mom = nil;
	
    /*
     If the managed object model already exists, return it.
     */
	if (mom != nil) {
        return mom;   
    }
    
    /*
     Create an entity description object for the Run entity.
     */
	NSEntityDescription *runEntity = [[NSEntityDescription alloc] init];
	[runEntity setName:@"Run"];
	[runEntity setManagedObjectClassName:@"Run"];
	
	
    /*
     Create the attributes for the Run entity.
     
     The 'date' attribute is straightforward: its type is NSDateAttributeType, and it's not optional.
     */
	NSAttributeDescription *dateAttribute;
	
	dateAttribute = [[NSAttributeDescription alloc] init];
	
	[dateAttribute setName:@"date"];
	[dateAttribute setAttributeType:NSDateAttributeType];
	[dateAttribute setOptional:NO];
	
	/*
     The 'processID attribute 
     */
	NSAttributeDescription *idAttribute;
	
	idAttribute = [[NSAttributeDescription alloc] init];
	
	[idAttribute setName:@"processID"];
	[idAttribute setAttributeType:NSInteger64AttributeType];
	[idAttribute setOptional:NO];
    [idAttribute setDefaultValue:@0];
	
	NSExpression *lhs = [NSExpression expressionForEvaluatedObject];
	NSExpression *rhs = [NSExpression expressionForConstantValue:@0];
	NSPredicate *validationPredicate = [NSComparisonPredicate
										predicateWithLeftExpression:lhs
										rightExpression:rhs
										modifier:NSDirectPredicateModifier
										type:NSGreaterThanPredicateOperatorType
										options:0];
	
	NSString *validationWarning = @"Process ID < 1";
	
	[idAttribute setValidationPredicates:@[validationPredicate]
				  withValidationWarnings:@[validationWarning]];
	
	
	[runEntity setProperties:@[dateAttribute, idAttribute]];
    
    
    /*
     Create a new managed object model instance, and set the entities of the model to an array containing just the Run entity.
     */
	mom = [[NSManagedObjectModel alloc] init];
    [mom setEntities:@[runEntity]];
    

    /*
     Create a localization dictionary for the model instance, and assign it to the model.
     */
    NSDictionary *localizationDictionary = @{
        @"Property/date/Entity/Run":@"Date",
        @"Property/processID/Entity/Run":@"Process ID",
        @"ErrorString/Process ID < 1":@"Process ID must not be less than 1"
    };
    
    [mom setLocalizationDictionary:localizationDictionary];
    
    return mom;
}



NSManagedObjectContext *managedObjectContext()
{
	static NSManagedObjectContext *moc = nil;
    
    if (moc != nil) {
        return moc;
    }
    
    /*
     Create the Core Data stack:
     
     * A persistent store coordinator
     * The managed object context.
     
     The persistent store coordinator requires a managed object model; also associate a persistent store.
     Initialize the managed object context for use on the main queue, and set its persistent store coordinator.
     */
	
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel()];
	
    NSError *error;
    /* Change this path/code to point to your App's data store. */
    NSURL *url = [applicationLogDirectory() URLByAppendingPathComponent:STORE_FILENAME];
	
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:STORE_TYPE configuration:nil URL:url options:nil error:&error];
	
	if (newStore == nil) {
		
		NSLog(@"Store Configuration Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
	}
	
    moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:coordinator];

    return moc;
}



NSURL *applicationLogDirectory()
{    
    NSString *LOG_DIRECTORY = @"CDCLI";
    static NSURL *ald = nil;
    
    if (ald == nil) {
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSURL *libraryURL = [fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (libraryURL == nil) {
            NSLog(@"Could not access Library directory\n%@", [error localizedDescription]);
        }
        else {
            ald = [libraryURL URLByAppendingPathComponent:@"Logs"];
            ald = [ald URLByAppendingPathComponent:LOG_DIRECTORY];
            NSDictionary *properties = [ald resourceValuesForKeys:@[NSURLIsDirectoryKey]
                                                            error:&error];
            if (properties == nil) {
                if (![fileManager createDirectoryAtURL:ald withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"Could not create directory %@\n%@", [ald path], [error localizedDescription]);
                    ald = nil;
                }
            }
        }
    }
    return ald;
}

