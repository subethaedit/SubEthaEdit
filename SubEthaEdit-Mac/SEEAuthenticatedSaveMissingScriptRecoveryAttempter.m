//
//  SEEAuthenticatedSaveMissingScriptRecoveryAttempter.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 07.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEAuthenticatedSaveMissingScriptRecoveryAttempter.h"

@implementation SEEAuthenticatedSaveMissingScriptRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    BOOL success = NO;
    NSError *internalError = nil;
    NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:
							[delegate methodSignatureForSelector:didRecoverSelector]];
    [invoke setSelector:didRecoverSelector];

 	if (error && [error.domain isEqualToString:@"SEEDocumentSavingDomain"] && error.code == 0x0FE) {
 		// index == 0 is "Visit Website"
		if (recoveryOptionIndex == 0) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.subethaedit.net/"]];
		}
	}

    [invoke setArgument:(void *)&success atIndex:2];
    if (internalError) {
        [invoke setArgument:&internalError atIndex:3];
	}

    [invoke invokeWithTarget:delegate];
}

@end
