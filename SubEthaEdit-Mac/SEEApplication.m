//
//  SEEApplication.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.08.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEApplication.h"
#import "SEEDocumentController.h"
#import "PlainTextDocument.h"

@implementation SEEApplication

- (IBAction)terminate:(id)sender {

	NSArray *documents = [[SEEDocumentController sharedInstance] documents];

	for (NSDocument *document in documents) {
		if ([document isKindOfClass:[PlainTextDocument class]]) {
			PlainTextDocument *plainTextDocument = (PlainTextDocument *)document;
			if ([plainTextDocument hasUnautosavedChanges]) {
				[plainTextDocument autosaveWithImplicitCancellability:NO completionHandler:^(NSError *errorOrNil) {
					
				}];
			}
			[plainTextDocument setPreparedForTermination:YES];
		}
	}

	[super terminate:sender];
}

@end
