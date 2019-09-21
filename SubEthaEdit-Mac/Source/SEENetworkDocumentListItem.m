//  SEENetworkDocumentRepresentation.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.

#import "SEENetworkDocumentListItem.h"
#import "TCMMMSession.h"

#import "SEEDocumentController.h"
#import "DocumentModeManager.h"

void * const SEENetworkDocumentRepresentationSessionObservingContext = (void *)&SEENetworkDocumentRepresentationSessionObservingContext;
void * const SEENetworkDocumentRepresentationSessionAccessStateObservingContext = (void *)&SEENetworkDocumentRepresentationSessionAccessStateObservingContext;


extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@implementation SEENetworkDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (instancetype)init {
    self = [super init];
    if (self) {
		self.name = NSLocalizedString(@"Unknown Name", @"");
        self.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
		self.documentAccessStateImage = [NSImage imageNamed:@"StatusPending"];

		[self installKVO];
    }
    return self;
}

- (void)dealloc {
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"documentSession" options:0 context:SEENetworkDocumentRepresentationSessionObservingContext];
	[self addObserver:self forKeyPath:@"documentSession.accessState" options:0 context:SEENetworkDocumentRepresentationSessionAccessStateObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"documentSession" context:SEENetworkDocumentRepresentationSessionObservingContext];
	[self removeObserver:self forKeyPath:@"documentSession.accessState" context:SEENetworkDocumentRepresentationSessionAccessStateObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkDocumentRepresentationSessionObservingContext) {
		self.name = self.documentSession.filename;

		[self updateAccessStateImage];
		[self updateImage];

	} else if (context == SEENetworkDocumentRepresentationSessionAccessStateObservingContext) {
		[self updateAccessStateImage];
		
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
	NSImage *image = nil;
	if (fileExtension) {
		NSString *fileType = (CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, nil)));
		image = [[[NSWorkspace sharedWorkspace] iconForFileType:fileType] copy];
	} else {
		image = [[[NSWorkspace sharedWorkspace] iconForFileType:(NSString *)kUTTypePlainText] copy];
	}
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];

    if (selector == @selector(itemAction:)) {
		return YES;
    }
    return YES;
}

@end
