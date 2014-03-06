//
//  SEENetworkDocumentRepresentation.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENetworkDocumentListItem.h"
#import "TCMMMSession.h"

#import "DocumentController.h"
#import "DocumentModeManager.h"

void * const SEENetworkDocumentRepresentationSessionObservingContext = (void *)&SEENetworkDocumentRepresentationSessionObservingContext;

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@implementation SEENetworkDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (id)init
{
    self = [super init];
    if (self) {
		self.name = NSLocalizedString(@"Unknown Name", @"");
        self.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
		self.documentAccessStateImage = [NSImage imageNamed:@"StatusPending"];

		[self installKVO];
    }
    return self;
}

- (void)dealloc
{
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"documentSession" options:0 context:SEENetworkDocumentRepresentationSessionObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"documentSession" context:SEENetworkDocumentRepresentationSessionObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkDocumentRepresentationSessionObservingContext) {
		self.name = self.documentSession.filename;

		[self updateAccessStateImage];
		[self updateImage];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateAccessStateImage {
	NSImage *accessStateImage = nil;
	switch (self.documentSession.accessState) {
		case TCMMMSessionAccessLockedState:
			accessStateImage = [NSImage imageNamed:@"StatusPending"];
			break;

		case TCMMMSessionAccessReadOnlyState:
			accessStateImage = [NSImage imageNamed:@"StatusReadOnly"];
			break;

		case TCMMMSessionAccessReadWriteState:
			accessStateImage = [NSImage imageNamed:@"StatusReadWrite"];
			break;
	}
	self.documentAccessStateImage = accessStateImage;
}

- (void)updateImage {
	NSString *fileExtension = self.name.pathExtension;
	NSString *fileType = (CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, nil)));
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
	self.image = image;
}

- (NSString *)uid {
	if (self.beepSession) {
		return [self.beepSession.sessionID stringByAppendingString:self.documentSession.sessionID];
	}
	return self.documentSession.sessionID;
}

- (IBAction)itemAction:(id)aSender {
	TCMMMSession *session = self.documentSession;
	if (session.isServer) {
		NSDocument *document = (NSDocument *)session.document;
		[document showWindows];
	} else {
		[session joinUsingBEEPSession:self.beepSession];
	}
}

@end
