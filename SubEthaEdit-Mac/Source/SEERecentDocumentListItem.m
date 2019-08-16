//  SEERecentDocumentListItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 03.03.14.

#import "SEERecentDocumentListItem.h"

void * const SEERecentDocumentURLObservingContext = (void *)&SEERecentDocumentURLObservingContext;

@implementation SEERecentDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (instancetype)init
{
    self = [super init];
    if (self) {
		self.name = NSLocalizedString(@"Unknown Name", @"");
        self.image = [NSImage imageNamed:NSImageNameMultipleDocuments];

		[self installKVO];
    }
    return self;
}

- (void)dealloc
{
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"fileURL" options:0 context:SEERecentDocumentURLObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"fileURL" context:SEERecentDocumentURLObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEERecentDocumentURLObservingContext) {
		self.name = self.fileURL.lastPathComponent;
		[self updateImage];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
	return self.fileURL.absoluteString;
}

- (IBAction)itemAction:(id)aSender {
	NSURL *documentURL = self.fileURL;
	if (documentURL) {
		[documentURL startAccessingSecurityScopedResource];
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:documentURL display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {}];
	}
}

@end
