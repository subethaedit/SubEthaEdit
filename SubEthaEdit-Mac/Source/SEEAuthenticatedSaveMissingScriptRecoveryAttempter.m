//  SEEAuthenticatedSaveMissingScriptRecoveryAttempter.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 07.05.14.

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
			// show finder window with script folder
			NSURL *userScriptsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
			[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[userScriptsDirectory]];

			// open URL in browser
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"WEBSITE_AUTHENTICATION_HELPER", @"Authentication Helper Website Link")]];


		}
	}

    [invoke setArgument:(void *)&success atIndex:2];
    if (internalError) {
        [invoke setArgument:&internalError atIndex:3];
	}

    [invoke invokeWithTarget:delegate];
}

@end
