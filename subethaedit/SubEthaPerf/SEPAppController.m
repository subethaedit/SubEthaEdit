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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[SEPLogger registerLogger:self];
	[SEPLogger logWithFormat:@"------ start up -----\n"];
	self.testNSTextStorage 								= YES;
	self.testFoldableTextStorage						= NO;
	self.testFoldableTextStorageOneFolding				= NO;
	self.testFoldableTextStorageEveryOtherLineFolding	= NO;
	self.numberOfRepeats = 3;
	[self performSelector:@selector(runTests:) withObject:nil afterDelay:1];
}


- (void)reportTimingArray:(NSArray *)anArray {
	double average = [[anArray valueForKeyPath:@"@avg.self"] doubleValue];
	double variance = 0.0;
	for (NSNumber *value in anArray) {
		variance += pow([value doubleValue] - average,2);
		[SEPLogger logWithFormat:@"| %0.3f ",[value doubleValue]];
	}
	variance = variance / [anArray count];
	double deviance = sqrt(variance);
	double ninetyFivePercentConfidenceInterval = (deviance * 2) / average * 100.0;
	
	[SEPLogger logWithFormat:@"|| %0.3f s +/- %3.1f %% ",average,ninetyFivePercentConfidenceInterval];
}

- (void)testFilesAtPath:(NSString *)aFilePath {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *timingArray = [NSMutableArray array];
	for (NSString *fileName in [fm directoryContentsAtPath:aFilePath]) {
		NSString *filePath = [aFilePath stringByAppendingPathComponent:fileName];
		if (![fileName isEqualToString:@"SoupDump.html"]) {
			[SEPLogger logWithFormat:
				[[NSString stringWithFormat:@"-> %@ (%d bytes)",
					fileName,
					[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES] fileSize]]
						stringByPaddingToLength:40 withString:@" " startingAtIndex:0]];
			[timingArray removeAllObjects];
			[ibResultsTextView display];
			int i = 0;
			for (;i<self.numberOfRepeats;i++) {
				SEPDocument *document = [[SEPDocument alloc] initWithURL:[NSURL fileURLWithPath:filePath]];
				if (document) {
					NSTimeInterval time = [document timedHighlightAll];
					[timingArray addObject:[NSNumber numberWithFloat:time]];
					[document release];
				}
			}
			[self reportTimingArray:timingArray];
			[SEPLogger logWithFormat:@"\n"];
			[ibResultsTextView display];
		}
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
}
@end
