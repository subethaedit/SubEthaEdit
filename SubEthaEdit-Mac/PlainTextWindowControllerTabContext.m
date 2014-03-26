//
//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextLoadProgress.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@implementation PlainTextWindowControllerTabContext

@synthesize activePlainTextEditor = _activePlainTextEditor;

- (id)init {
    self = [super init];
    if (self) {
        _plainTextEditors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowControllerTabContext:) withObject:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, document: %@", [super description], self.document];
}

- (void)setIsAlertScheduled:(BOOL)flag {
    if (flag) {
        [self setIcon:[NSImage imageNamed:@"SymbolWarn"]];
        [self setIconName:@"Alert"];
    } else {
        [self setIcon:nil];
        [self setIconName:@""];
    }
    _isAlertScheduled = flag;
}

- (void)setActivePlainTextEditor:(PlainTextEditor *)activePlainTextEditor {
	if ([self.plainTextEditors containsObject:activePlainTextEditor]) {
		_activePlainTextEditor = activePlainTextEditor;
	}
}

- (PlainTextEditor *)activePlainTextEditor {
	PlainTextEditor *result = _activePlainTextEditor;
	if (!result) {
		result = self.plainTextEditors.firstObject;
	}
	return result;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	[super encodeRestorableStateWithCoder:coder];

	NSURL *documentURL = self.document.fileURL;
	NSURL *documentAutosaveURL = self.document.autosavedContentsFileURL;

	NSData *documentURLBookmark = [documentURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
										includingResourceValuesForKeys:nil
														 relativeToURL:nil
																 error:nil];
	
	NSData *documentAutosaveURLBookmark = [documentAutosaveURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
														includingResourceValuesForKeys:nil
																		 relativeToURL:nil
																				 error:nil];

	[coder encodeObject:documentURLBookmark forKey:@"SEETabContextDocumentURLBookmark"];
	[coder encodeObject:documentAutosaveURLBookmark forKey:@"SEETabContextDocumentAutosaveURLBookmark"];

	if (self.plainTextEditors.count > 0) {
		[coder encodeBool:YES forKey:@"SEETabContextShowsEditorSplit"];
		// TODO: store split frames...
	} else {
		[coder encodeBool:NO forKey:@"SEETabContextShowsEditorSplit"];
	}

	[self. document encodeRestorableStateWithCoder:coder];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	[super restoreStateWithCoder:coder];
}

@end
