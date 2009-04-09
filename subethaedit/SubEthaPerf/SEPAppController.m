//
//  SEPAppController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "SEPLogger.h"
#import "SEPAppController.h"


@implementation SEPAppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[SEPLogger registerLogger:self];
	[SEPLogger logWithFormat:@"------ start up -----\n"];
}

- (IBAction)runTests:(id)aSender {
	[SEPLogger logWithFormat:@"------ runTests -----\n"];
}


- (void)logString:(NSString *)aString
{
	[[[ibResultsTextView textStorage] mutableString] appendString:aString];
	NSLog(@"%@",aString);
}
@end
