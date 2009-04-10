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


@implementation SEPAppController

@synthesize testNSTextStorage,testFoldableTextStorage, testFoldableTextStorageOneFolding, testFoldableTextStorageEveryOtherLineFolding, numberOfRepeats;

- (void)setupLogFile {
	NSString *appName = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
	NSString *appDir = [[@"~/Library/Logs/" stringByExpandingTildeInPath] stringByAppendingPathComponent:appName];
	[[NSFileManager defaultManager] createDirectoryAtPath:appDir attributes:nil];
	
    int sequenceNumber = 0;
	NSString *name;
	do {
		sequenceNumber++;
		name = [NSString stringWithFormat:@"Perflog-%@-%@-%d.log", [[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y-%m-%d--%H-%M"], [[NSProcessInfo processInfo] hostName], sequenceNumber];
		name = [appDir stringByAppendingPathComponent:name];
	} while ([[NSFileManager defaultManager] fileExistsAtPath:name]);

    [[NSFileManager defaultManager] createFileAtPath:name contents:[NSData data] attributes:nil];
    logFileHandle = [[NSFileHandle fileHandleForWritingAtPath:name] retain];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
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
		[self performSelector:@selector(runTests:) withObject:nil afterDelay:1];
	}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[logFileHandle closeFile];
	[logFileHandle release];
}

- (void)reportTimingArray:(NSArray *)anArray forByteLength:(double)byteLength {
	double average = [[anArray valueForKeyPath:@"@avg.self"] doubleValue];
	double variance = 0.0;
	for (NSNumber *value in anArray) {
		variance += pow([value doubleValue] - average,2);
//		[SEPLogger logWithFormat:@"| %03.3f ",[value doubleValue]];
	}
	variance = variance / [anArray count];
	double deviance = sqrt(variance);
	double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;
	
	[SEPLogger logWithFormat:@"||%@ |%@ | +/-%@ ",
		[[NSString stringWithFormat:@"%03.3fs",average] stringByLeftPaddingUpToLength:8],
		[[NSString stringWithFormat:@"%03.3fms/kb",average / byteLength * 1024 * 1000] stringByLeftPaddingUpToLength:12],
		[[NSString stringWithFormat:@"%.1f %%",ninetyFivePercentConfidenceInterval] stringByLeftPaddingUpToLength:8]];
		
}

- (void)testFileAtPath:(NSString *)aFilePath
{
	NSMutableArray *timingArray = [NSMutableArray new];
	NSString *fileName = [aFilePath lastPathComponent];
	int byteSize = [[[NSFileManager defaultManager] fileAttributesAtPath:aFilePath traverseLink:YES] fileSize];
	[SEPLogger logWithFormat:
		[[NSString stringWithFormat:@"-> %@ (%d kb)", fileName, byteSize / 1024]
			stringByPaddingToLength:40 withString:@" " startingAtIndex:0]];
	[ibResultsTextView display];

	int i = 0;
	for (;i<self.numberOfRepeats;i++) {
		SEPDocument *document = [[SEPDocument alloc] initWithURL:[NSURL fileURLWithPath:aFilePath]];
		if (document) {
			NSTimeInterval time = [document timedHighlightAll];
			[timingArray addObject:[NSNumber numberWithFloat:time]];
			[document release];
		}
	}
	[self reportTimingArray:timingArray forByteLength:byteSize];
	[SEPLogger logWithFormat:@"\n"];
	[ibResultsTextView display];

	[timingArray release];
}

- (void)testFilesAtPath:(NSString *)aFilePath {
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *fileName in [fm directoryContentsAtPath:aFilePath]) {
		NSString *filePath = [aFilePath stringByAppendingPathComponent:fileName];
			[self testFileAtPath:filePath];
	}
	
}

- (void)application:(NSApplication *)anApplication openFiles:(NSArray *)aFilePathArray {
	[anApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess]; // so finder isn't worried anymore
	for (NSString *filePath in aFilePathArray) {
		[self testFileAtPath:filePath];
	}
}

- (IBAction)runTests:(id)aSender {
	[ibProgressIndicator startAnimation:self];
	[SEPLogger logWithFormat:@"------ runTests (%d times per document) -----\n", self.numberOfRepeats];
	// load up all files in TestFiles
	NSString *testfilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TestFiles"];
	[self testFilesAtPath:testfilePath];
	[ibProgressIndicator stopAnimation:self];
}


- (void)logString:(NSString *)aString
{
	[[[ibResultsTextView textStorage] mutableString] appendString:aString];
	NSLog(@"%@",aString);
	[logFileHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
