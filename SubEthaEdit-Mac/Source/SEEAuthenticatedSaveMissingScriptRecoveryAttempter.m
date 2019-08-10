//  SEEAuthenticatedSaveMissingScriptRecoveryAttempter.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 07.05.14.

#import "SEEAuthenticatedSaveMissingScriptRecoveryAttempter.h"
#import "AppController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SEEAuthenticatedSaveMissingScriptRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo {
    BOOL success = NO;
    NSError *internalError = nil;
    NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:
							[delegate methodSignatureForSelector:didRecoverSelector]];
    [invoke setSelector:didRecoverSelector];

 	if (error && [error.domain isEqualToString:@"SEEDocumentSavingDomain"] && error.code == 0x0FE) {
 		// index == 0 is "Reveal installer script…"
		if (recoveryOptionIndex == 0) {
            [[AppController sharedInstance] revealInstallCommandInFinder:nil];
        }
	}

    [invoke setArgument:(void *)&success atIndex:2];
    if (internalError) {
        [invoke setArgument:&internalError atIndex:3];
	}

    [invoke invokeWithTarget:delegate];
}

@end
