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
#import "TCMMMUser.h"

void * const SEENetworkDocumentRepresentationFileNameObservingContext = (void *)&SEENetworkDocumentRepresentationFileNameObservingContext;

@implementation SEENetworkDocumentRepresentation

- (id)init
{
    self = [super init];
    if (self) {
        self.fileIcon = [NSImage imageNamed:@"NSApplicationIcon"];
		self.fileName = @"Unknown";

		[self installKVO];
    }
    return self;
}

- (void)dealloc
{
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"fileName" options:0 context:SEENetworkDocumentRepresentationFileNameObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"fileName" context:SEENetworkDocumentRepresentationFileNameObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkDocumentRepresentationFileNameObservingContext) {
		[self updateFileIcon];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)updateFileIcon {
	NSString *fileExtension = self.fileName.pathExtension;
	NSString *fileType = (CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, nil)));
	NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
	self.fileIcon = fileIcon;
}


- (IBAction)joinDocument:(id)aSender {
	TCMMMSession *session = self.documentSession;
	[session joinUsingBEEPSession:nil];
}

@end
