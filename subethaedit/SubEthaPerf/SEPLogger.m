//
//  SEPLogger.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "SEPLogger.h"

static NSMutableArray *loggingArray;

@implementation SEPLogger
+ (void)initialize {
	if (self == [SEPLogger class]) {
		loggingArray = [NSMutableArray new];
	}
}

+ (void)logWithFormat:(NSString *)format,... {
	va_list va;
	va_start(va,format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:va];
	va_end(va);
	[loggingArray makeObjectsPerformSelector:@selector(logString:) withObject:string];
	[string release];
}

+ (void)registerLogger:(id)aLogger {
	[loggingArray addObject:aLogger];
}
@end
