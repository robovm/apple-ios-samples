/*
	    File: SQLiteQueryPlugIn.m
	Abstract: SQLiteQueryPlugin class.
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
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "SQLiteQueryPlugIn.h"

#define	kQCPlugIn_Name				@"SQLite Query"
#define	kQCPlugIn_Description		@"Performs a query on a local SQLite database."

@implementation SQLiteQueryPlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputDataBasePath, inputQueryString, outputResultStructure;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputDataBasePath"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Database Path", QCPortAttributeNameKey, @"myDatabase.db", QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"inputQueryString"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Query String", QCPortAttributeNameKey, @"select * from myTable;", QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"outputResultStructure"])
	return [NSDictionary dictionaryWithObject:@"Result Structure" forKey:QCPortAttributeNameKey];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a processor (it runs a command line tool) */
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	return kQCPlugInTimeModeNone;
}

@end

@implementation NSMutableData (SQLiteQueryPlugIn)

/* Extend the NSMutableData class to add a method called by NSFileHandleDataAvailableNotification to automatically append the new data */
- (void) _SQLiteQueryPlugInFileHandleDataAvailable:(NSNotification*)notification
{
	NSFileHandle*			fileHandle = [notification object];
	
	[self appendData:[fileHandle availableData]];
	
	[fileHandle waitForDataInBackgroundAndNotify];
}

@end

@implementation SQLiteQueryPlugIn (Execution)

- (int) _runTask:(NSTask*)task inData:(NSData*)inData outData:(NSData**)outData errorData:(NSData**)errorData
{
	NSPipe*				inPipe = nil;
	NSPipe*				outPipe = nil;
	NSPipe*				errorPipe = nil;
	NSFileHandle*		fileHandle;
	
	/* Reset output variables */
	if(outData)
	*outData = nil;
	if(errorData)
	*errorData = nil;
	
	/* Safe check */
	if(task == nil)
	return -1;
	
	/* Create standard input pipe */
	if([inData length]) {
		if(inPipe = [NSPipe new]) {
			[task setStandardInput:inPipe];
			[inPipe release];
		}
		else {
			task = nil;
			goto Exit;
		}
	}
	
	/* Create standard output pipe */
	if(outData) {
		if(outPipe = [NSPipe new]) {
			[task setStandardOutput:outPipe];
			[outPipe release];
		}
		else {
			task = nil;
			goto Exit;
		}
	}
	
	/* Create standard error pipe */
	if(errorData) {
		if(errorPipe = [NSPipe new]) {
			[task setStandardError:errorPipe];
			[errorPipe release];
		}
		else {
			task = nil;
			goto Exit;
		}
	}
	
	/* Launch task */
NS_DURING
	[task launch];
NS_HANDLER
	task = nil;
NS_ENDHANDLER
	if(task == nil)
	goto Exit;
	
	/* Write data to standard input pipe */
	if(fileHandle = [inPipe fileHandleForWriting]) {
NS_DURING
		[fileHandle writeData:inData];
		[fileHandle closeFile];
NS_HANDLER
		[task terminate];
		[task interrupt];
		task = nil;
NS_ENDHANDLER
	}
	if(task == nil)
	goto Exit;
	
	/* Read data from standard output and standard error pipes in background */
	if(fileHandle = [outPipe fileHandleForReading]) {
		*outData = [NSMutableData data];
		[[NSNotificationCenter defaultCenter] addObserver:*outData selector:@selector(_SQLiteQueryPlugInFileHandleDataAvailable:) name:NSFileHandleDataAvailableNotification object:fileHandle];
		[fileHandle waitForDataInBackgroundAndNotify];
	}
	if(fileHandle = [errorPipe fileHandleForReading]) {
		*errorData = [NSMutableData data];
		[[NSNotificationCenter defaultCenter] addObserver:*errorData selector:@selector(_SQLiteQueryPlugInFileHandleDataAvailable:) name:NSFileHandleDataAvailableNotification object:fileHandle];
		[fileHandle waitForDataInBackgroundAndNotify];
	}
	
	/* We cannot use -[NSTask waitUntilExit] as it runs the runloop in default mode which might make Quartz Composer re-enter its execution e.g. from a QCView, so we run in a private mode */
	while([task isRunning])
	[[NSRunLoop currentRunLoop] runMode:@"SQLiteQueryPlugInMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	
	/* Finish reading data */
	if(fileHandle = [errorPipe fileHandleForReading]) {
		[[NSNotificationCenter defaultCenter] removeObserver:*errorData name:NSFileHandleDataAvailableNotification object:fileHandle];
		[(NSMutableData*)*errorData appendData:[fileHandle readDataToEndOfFile]];
	}
	if(fileHandle = [outPipe fileHandleForReading]) {
		[[NSNotificationCenter defaultCenter] removeObserver:*outData name:NSFileHandleDataAvailableNotification object:fileHandle];
		[(NSMutableData*)*outData appendData:[fileHandle readDataToEndOfFile]];
	}
	
Exit:
	[[inPipe fileHandleForReading] closeFile];
	[[inPipe fileHandleForWriting] closeFile];
	[[outPipe fileHandleForReading] closeFile];
	[[outPipe fileHandleForWriting] closeFile];
	[[errorPipe fileHandleForReading] closeFile];
	[[errorPipe fileHandleForWriting] closeFile];
	
	return (task ? [task terminationStatus] : -1);
}

+ (NSURL*) urlFromString:(NSString*)string withCompositionURL:(NSURL*)compositionURL
{
	NSURL*					url = nil;
	CFURLRef				urlRef;
	CFStringRef				stringRef;
	
	if([string length]) {
		/* Do we have a patch relative to the user directory? */
		if([string characterAtIndex:0] == '~')
		url = [NSURL fileURLWithPath:[string stringByExpandingTildeInPath]];
		/* Do we have an absolute path? */
		else if([string characterAtIndex:0] == '/')
		url = [NSURL fileURLWithPath:string];
		else {
			url = [NSURL URLWithString:string];
			/* Do we have a relative URL? */
			if([url scheme] == nil) {
				url = nil;
				if(compositionURL && (urlRef = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)compositionURL))) {
					if(stringRef = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, NULL, kCFStringEncodingUTF8)) {
						url = [(id)CFMakeCollectable(CFURLCreateWithString(kCFAllocatorDefault, stringRef, urlRef)) autorelease];
						CFRelease(stringRef);
					}
					CFRelease(urlRef);
				}
			}
		}
	}
	
	return url;
}

+ (NSArray*) arrayFromSQLiteResult:(NSString*)result
{
	NSMutableArray*			array = [NSMutableArray array];
	NSScanner*				scanner;
	NSString*				line;
	NSMutableDictionary*	dictionary;
	NSRange					range;
	
	/* Scan the result string in "line" mode and convert it to an array of dictionaries */
	scanner = [[NSScanner alloc] initWithString:result];
	[scanner setCharactersToBeSkipped:nil];
	while(![scanner isAtEnd]) {
		dictionary = [NSMutableDictionary new];
		while(1) {
			[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
			if(![scanner scanUpToString:@"\n" intoString:&line])
			break;
			
			range = [line rangeOfString:@" = "];
			if(range.location != NSNotFound)
			[dictionary setObject:[line substringWithRange:NSMakeRange(range.location + range.length, [line length] - range.location - range.length)] forKey:[line substringWithRange:NSMakeRange(0, range.location)]];
			
			if(![scanner isAtEnd])
			[scanner setScanLocation:([scanner scanLocation] + 1)];
		}
		if([dictionary count])
		[array addObject:dictionary];
		[dictionary release];
		
		if(![scanner scanString:@"\n" intoString:NULL])
		break;
	}
	[scanner release];
	
	return array;
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	NSURL*					databaseURL = [SQLiteQueryPlugIn urlFromString:self.inputDataBasePath withCompositionURL:[context compositionURL]];
	NSTask*					task;
	NSMutableArray*			args;
	NSUInteger				i;
	NSData*					outData;
	int						status;
	NSString*				string;
	
	/* Make sure we have a valid database URL and a valid query */
	if(![databaseURL isFileURL] || ![self.inputQueryString length]) {
		self.outputResultStructure = nil;
		return YES;
	}
	
	/* Create task */
	task = [NSTask new];
	[task setLaunchPath:@"/usr/bin/sqlite3"];
	[task setArguments:[NSArray arrayWithObject:[databaseURL path]]];
	
	/* Execute task */
	if([self _runTask:task inData:[[@".mode line\n" stringByAppendingString:self.inputQueryString] dataUsingEncoding:NSUTF8StringEncoding] outData:&outData errorData:NULL] == 0) {
		if([outData length]) {
			string = [[NSString alloc] initWithBytes:[outData bytes] length:([outData length] - 1) encoding:NSUTF8StringEncoding];
			self.outputResultStructure = [SQLiteQueryPlugIn arrayFromSQLiteResult:string];
			[string release];
		}
		else
		self.outputResultStructure = [NSArray array];
	}
	else {
		[context logMessage:@"SQLite Error: %@", ([outData length] ? [[[NSString alloc] initWithBytes:[outData bytes] length:([outData length] - 1) encoding:NSUTF8StringEncoding] autorelease] : nil)];
		self.outputResultStructure = nil;
	}
	
	/* Destroy task */
	[task release];
	
	return YES;
}

@end
