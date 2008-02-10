//
//  ByteFormatter.m
//  Pandora
//
//  Created by Martin Pittenauer on 26.01.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "StatusFormatter.h"


@implementation StatusFormatter

	- (NSString *)transformedValue:(id)aArg
	{
		NSException	*loc_err;
		NSString	*loc_val;
		double		loc_dbl;
		
		// parameter check
		if (aArg != nil)
		{
				// reformat the data
				loc_dbl = [aArg doubleValue];
				//loc_dbl = loc_dbl / 1024.0;
				
				if (loc_dbl == 0) {
					loc_val = @"Unmapped";					
				}
				
				if (loc_dbl == 1) {
					loc_val = @"Trying";					
				}
				
				if (loc_dbl == 2) {
					loc_val = @"Mapped";					
				}
				
				
		}
		else
		{
			// raise an exception
			loc_err = 
				[NSException exceptionWithName:NSInvalidArgumentException 
					reason:@"Nil argument"
					userInfo:nil];
			[loc_err raise];
		}
		// return the formatting results
		return (loc_val);
	}

+ (BOOL)allowsReverseTransformation {
	return NO;
}


	
@end
