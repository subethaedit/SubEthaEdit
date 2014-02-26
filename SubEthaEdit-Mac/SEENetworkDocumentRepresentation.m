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

#import "SEENetworkDocumentRepresentation.h"
#import "TCMMMSession.h"

#import "DocumentController.h"
#import "DocumentModeManager.h"

void * const SEENetworkDocumentRepresentationSessionObservingContext = (void *)&SEENetworkDocumentRepresentationSessionObservingContext;

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@interface SEENetworkDocumentRepresentation ()
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSImage *image;
@end

@implementation SEENetworkDocumentRepresentation

- (id)init
{
    self = [super init];
    if (self) {
		self.name = @"New Document";
        self.image = [NSImage imageNamed:@"EditorAddSplit"];

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
		[self updateImage];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateImage {
	NSString *fileExtension = self.name.pathExtension;
	NSString *fileType = (CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, nil)));
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
	self.image = image;
}

- (IBAction)openDocument:(id)aSender {
	TCMMMSession *session = self.documentSession;
	if (session) {
		[session joinUsingBEEPSession:nil];
	}
	else
	{
		NSMenu *menu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
		NSMenuItem *menuItem = [menu itemWithTag:FileNewMenuItemTag];
		menu = [menuItem submenu];
		NSMenuItem *item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];

		[[NSDocumentController sharedDocumentController] newDocumentWithModeMenuItem:item];
	}
}

@end
