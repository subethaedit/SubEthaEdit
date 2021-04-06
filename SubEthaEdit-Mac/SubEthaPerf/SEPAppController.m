//
//  SEPAppController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "SEPLogger.h"
#import "SEPAppController.h"
#import "SEPDocument.h"
#import "DocumentModeManager.h"

@implementation TCMMMUserManager
+ (NSString *)myUserID {
    return @"B5145FD4-6D3C-4426-B1EF-6DD774944F49";
}
@end

@implementation SEPAppController

@synthesize testNSTextStorage,testFoldableTextStorage, testFoldableTextStorageOneFolding, testFoldableTextStorageEveryOtherLineFolding, numberOfRepeats;

- (void)setupLogFile {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *possibleURLs = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
	NSURL *logsDirectory = nil;
	
	if ([possibleURLs count] >= 1) { // Use the first directory (if multiple are returned)
		logsDirectory = [possibleURLs objectAtIndex:0]; // .*/Library
	}
	if (logsDirectory) {
		logsDirectory = [logsDirectory URLByAppendingPathComponent:@"Logs"]; // .*/Library/Logs
		NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
		logsDirectory = [logsDirectory URLByAppendingPathComponent:appBundleID]; // .*/Library/Logs/de.codingmonkeys.SubEthaEdit.Mac
		[fileManager createDirectoryAtURL:logsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	NSString *logsPath = [logsDirectory path];
    int sequenceNumber = 0;
	NSString *name;
	do {
		sequenceNumber++;
		name = [NSString stringWithFormat:@"Perflog-%@-%@-%d.log", [NSDate date], [[NSProcessInfo processInfo] hostName], sequenceNumber];
		name = [logsPath stringByAppendingPathComponent:name];
	} while ([fileManager fileExistsAtPath:name]);

    [fileManager createFileAtPath:name contents:[NSData data] attributes:nil];
    logFileHandle = [NSFileHandle fileHandleForWritingAtPath:name];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	throughputDictionary = [NSMutableDictionary new];
	[self setupLogFile];

	[SEPLogger registerLogger:self];
	[SEPLogger logWithFormat:@"------ start up (v%@)-----\n", [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"]];
	NSProcessInfo *info = [NSProcessInfo processInfo];
	[SEPLogger logWithFormat:@"%@, %d cpus, %d MB, %@\n",[info hostName],[info activeProcessorCount],[info physicalMemory] / 1024 / 1024,[info operatingSystemVersionString]];
	self.testNSTextStorage 								= YES;
	self.testFoldableTextStorage						= NO;
	self.testFoldableTextStorageOneFolding				= NO;
	self.testFoldableTextStorageEveryOtherLineFolding	= NO;
	self.numberOfRepeats = 3;
	
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RunTestsAtStart"]) {
		[self performSelector:@selector(runTests:) withObject:nil afterDelay:2];
	}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[logFileHandle closeFile];
}

- (void)getAverage:(double *)anAverage deviance:(double *)aDeviance ofArray:(NSArray *)anArray {
	*anAverage = [[anArray valueForKeyPath:@"@avg.self"] doubleValue];
	double variance = 0.0;
	for (NSNumber *value in anArray) {
		variance += pow([value doubleValue] - *anAverage,2);
	}
	variance = variance / [anArray count];
	*aDeviance = sqrt(variance);
}

// returns throughput Average
- (void)reportTotal:(NSArray *)anArray referenceArray:(NSArray *)aReferenceArray {
	double average = 0.0;
	double deviance = 0.0;
	[self getAverage:&average deviance:&deviance ofArray:anArray];
	double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;

	[SEPLogger logWithFormat:@"----------------------------------------------------------------------\n"];
	[SEPLogger logWithFormat:@"-- Total (avg of mode avgs) || (min:%@ | max:%@) %@ | +/-%@ \n",
		[NSString stringWithFormat:@"%03.1fkb/s",[[anArray valueForKeyPath:@"@min.self"] doubleValue] / 1024.0],
		[NSString stringWithFormat:@"%03.1fkb/s",[[anArray valueForKeyPath:@"@max.self"] doubleValue] / 1024.0],
		[[NSString stringWithFormat:@"%03.1fkb/s",average / 1024.0] stringByLeftPaddingUpToLength:12],
		[[NSString stringWithFormat:@"%.1f %%",ninetyFivePercentConfidenceInterval] stringByLeftPaddingUpToLength:8]];
	if ([aReferenceArray count]) {
		double referenceAverage = 0.0;
		[self getAverage:&referenceAverage deviance:&deviance ofArray:aReferenceArray];
		double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;
		[SEPLogger logWithFormat:@"-- Reference Total          || (min:%@ | max:%@) %@ | +/-%@ \n",
			[NSString stringWithFormat:@"%03.1fkb/s",[[aReferenceArray valueForKeyPath:@"@min.self"] doubleValue] / 1024.0],
			[NSString stringWithFormat:@"%03.1fkb/s",[[aReferenceArray valueForKeyPath:@"@max.self"] doubleValue] / 1024.0],
			[[NSString stringWithFormat:@"%03.1fkb/s",referenceAverage / 1024.0] stringByLeftPaddingUpToLength:12],
			[[NSString stringWithFormat:@"%.1f %%",ninetyFivePercentConfidenceInterval] stringByLeftPaddingUpToLength:8]];
		[SEPLogger logWithFormat:@"-- Change:%@\n",[[NSString stringWithFormat:@"%0.1f%%", (average - referenceAverage) / referenceAverage * 100] stringByLeftPaddingUpToLength:9]];
	}
	[SEPLogger logWithFormat:@"----------------------------------------------------------------------\n"];
}


// returns throughput Average
- (double)reportModeTimingArray:(NSArray *)anArray {
	double average = 0.0;
	double deviance = 0.0;
	[self getAverage:&average deviance:&deviance ofArray:anArray];
	double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;

	[SEPLogger logWithFormat:@"%@ | +/-%@ ",
		[[NSString stringWithFormat:@"%03.1fkb/s",average / 1024.0] stringByLeftPaddingUpToLength:12],
		[[NSString stringWithFormat:@"%.1f %%",ninetyFivePercentConfidenceInterval] stringByLeftPaddingUpToLength:8]];

	return average;
}


// returns throughput
- (double)reportTimingArray:(NSArray *)anArray forByteLength:(double)byteLength {
	double average = 0.0;
	double deviance = 0.0;
	[self getAverage:&average deviance:&deviance ofArray:anArray];

	double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;
	double throughPut = byteLength / average;

	[SEPLogger logWithFormat:@"||%@ |%@ | +/-%@ ",
		[[NSString stringWithFormat:@"%03.3fs",average] stringByLeftPaddingUpToLength:8],
		[[NSString stringWithFormat:@"%03.1fkb/s",throughPut / 1024.0] stringByLeftPaddingUpToLength:12],
		[[NSString stringWithFormat:@"%.1f %%",ninetyFivePercentConfidenceInterval] stringByLeftPaddingUpToLength:8]];
	return throughPut;
}

- (void)testFileAtPath:(NSString *)aFilePath recordThroughPut:(NSMutableDictionary *)aThroughPutDictionary
{
	NSMutableArray *timingArray = [NSMutableArray new];
	NSString *fileName = [aFilePath lastPathComponent];
	int byteSize = [[[NSFileManager defaultManager] fileAttributesAtPath:aFilePath traverseLink:YES] fileSize];
	
	int testMode=0;
	for (testMode=0; testMode<4; testMode++) {
		[timingArray removeAllObjects];
		if ((testMode == 0 && !self.testNSTextStorage) ||
			(testMode == 1 && !self.testFoldableTextStorage) ||
			(testMode == 2 && !self.testFoldableTextStorageOneFolding) ||
			(testMode == 3 && !self.testFoldableTextStorageEveryOtherLineFolding)) {
			continue;
		}
		NSString *textStorageType = @"NSTextStorage";
		switch (testMode) {
			case 1: textStorageType = @"Foldable"; break;
			case 2: textStorageType = @"Foldable1Fold"; break;
			case 3: textStorageType = @"FoldableManyFold"; break;
		}
		[SEPLogger logWithFormat:
			[[NSString stringWithFormat:@"-> %@ (%d kb)", fileName, byteSize / 1024]
				stringByPaddingToLength:40 withString:@" " startingAtIndex:0]];
		[SEPLogger logWithFormat:
			[[NSString stringWithFormat:@"%@ ",textStorageType]
				stringByPaddingToLength:17 withString:@" " startingAtIndex:0]];
		[ibResultsTextView display];
	
		int i = 0;
		NSString *modeIdentifier = nil;
		for (;i<self.numberOfRepeats;i++) {
			SEPDocument *document = [[SEPDocument alloc] initWithURL:[NSURL fileURLWithPath:aFilePath]];
			if (document) {
				if (testMode > 0) {
					[document changeToFoldableTextStorage];
					if (testMode == 2) {
						[document addOneFolding];
					} else if (testMode == 3) {
						[document foldEveryOtherLine];
					}
				}
				modeIdentifier = [[document documentMode] documentModeIdentifier];
				NSTimeInterval time = [document timedHighlightAll];
				[timingArray addObject:[NSNumber numberWithFloat:time]];
			}
		}
		double throughPut = [self reportTimingArray:timingArray forByteLength:byteSize];
		if (![aThroughPutDictionary objectForKey:modeIdentifier]) {
			[aThroughPutDictionary setObject:[NSMutableArray array] forKey:modeIdentifier];
		}
		[[aThroughPutDictionary objectForKey:modeIdentifier] addObject:[NSNumber numberWithDouble:throughPut]];
		[SEPLogger logWithFormat:@"\n"];
		[ibResultsTextView display];
	}
}

- (void)testFiles:(NSArray *)aFilePathArray
{
	[throughputDictionary removeAllObjects];
	for (NSString *filePath in aFilePathArray) {
		[self testFileAtPath:filePath recordThroughPut:throughputDictionary];
	}
	[SEPLogger logWithFormat:@"--- Breakdown by Mode ---\n"];
	NSDictionary *referenceThroughput = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReferenceThroughput"];
	NSMutableArray *totalArray = [NSMutableArray array];
	NSMutableArray *otherTotalArray = [NSMutableArray array];
	for (NSString *key in [[throughputDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
		DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:key];
		
		[SEPLogger logWithFormat:
			[[NSString stringWithFormat:@"- %@ (%@ v%@)", [mode displayName], [mode documentModeIdentifier], [[[mode bundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]
				stringByPaddingToLength:45 withString:@" " startingAtIndex:0]];
		double average = [self reportModeTimingArray:[throughputDictionary objectForKey:key]];
		[totalArray addObject:[NSNumber numberWithDouble:average]];

		if ([referenceThroughput objectForKey:key]) {
			[SEPLogger logWithFormat:@"     Reference:"];
			double otherAverage = [self reportModeTimingArray:[referenceThroughput objectForKey:key]];
			[SEPLogger logWithFormat:@" || Change:%@",[[NSString stringWithFormat:@"%0.1f%%", (average - otherAverage) / otherAverage * 100] stringByLeftPaddingUpToLength:9]];
			[otherTotalArray addObject:[NSNumber numberWithDouble:otherAverage]];
		}

		[SEPLogger logWithFormat:@"\n"];
	}
	[self reportTotal:totalArray referenceArray:otherTotalArray];
}

- (void)testFilesAtPath:(NSString *)aFilePath {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *filePathArray = [NSMutableArray array];
	for (NSString *fileName in [[fm directoryContentsAtPath:aFilePath] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
		[filePathArray addObject:[aFilePath stringByAppendingPathComponent:fileName]];
	}
	[self testFiles:filePathArray];	
}

- (void)application:(NSApplication *)anApplication openFiles:(NSArray *)aFilePathArray {
	[SEPLogger logWithFormat:@"------ opening testfiles (%d times per document) -----\n", self.numberOfRepeats];
	[anApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess]; // so finder isn't worried anymore
	[self testFiles:[aFilePathArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
}

- (IBAction)runTests:(id)aSender {
	[ibProgressIndicator startAnimation:self];
	[SEPLogger logWithFormat:@"------ runTests (%d times per document) -----\n", self.numberOfRepeats];
	// load up all files in TestFiles
	NSString *testfilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TestFiles"];
	[self testFilesAtPath:testfilePath];
	[ibProgressIndicator stopAnimation:self];
}

- (IBAction)setReference:(id)aSender {
	[[NSUserDefaults standardUserDefaults] setObject:throughputDictionary forKey:@"ReferenceThroughput"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)logString:(NSString *)aString
{
	[[[ibResultsTextView textStorage] mutableString] appendString:aString];
	NSLog(@"%@",aString);
	[logFileHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
