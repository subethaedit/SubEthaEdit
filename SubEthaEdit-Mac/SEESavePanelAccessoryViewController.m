//
//  SEESavePanelAccessoryViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEESavePanelAccessoryViewController.h"
#import "PlainTextDocument.h"
#import "EncodingManager.h"
#import "DocumentModeManager.h"

@interface SEESavePanelAccessoryViewController ()

@end

@implementation SEESavePanelAccessoryViewController

@dynamic writableDocumentTypes;


+ (instancetype)prepareSavePanel:(NSSavePanel *)savePanel withSaveOperation:(NSSaveOperationType)saveOperation forDocument:(PlainTextDocument *)document
{
    SEESavePanelAccessoryViewController *viewController = [[[self class] alloc] initWithNibName:@"SavePanelAccessory" bundle:nil];

    viewController.document = document;
    viewController.savePanel = savePanel;
    viewController.saveOperation = saveOperation;

	(void)viewController.view; // force load the view

	if (saveOperation == NSSaveToOperation) {
		savePanel.accessoryView = viewController.saveToPanelAccessoryOutlet;
	} else {
		savePanel.accessoryView = viewController.savePanelAccessoryOutlet;
	}
    
    return viewController;
}


- (void)dealloc
{
	[self.savePanel removeObserver:self forKeyPath:@"isExtensionHidden"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (void *)0x745274) {
		[self selectFileFormat:self.savePanelAccessoryFileFormatMatrixOutlet];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)loadView
{
	[super loadView];

    NSString *documentFileType = self.document.fileType;
    NSSavePanel *savePanel = self.savePanel;
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];

    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
	[savePanel setShowsHiddenFiles:showsHiddenFiles];
    [savePanel setCanSelectHiddenExtension:YES];
	[savePanel setExtensionHidden:NO];

	if (UTTypeConformsTo((__bridge CFStringRef)documentFileType, (CFStringRef)@"de.codingmonkeys.subethaedit.seetext")) {
		[self.savePanelAccessoryFileFormatMatrixOutlet selectCellWithTag:1];
	} else {
		[self.savePanelAccessoryFileFormatMatrixOutlet selectCellWithTag:0];
	}
	[self selectFileFormat:self.savePanelAccessoryFileFormatMatrixOutlet];

	self.savePanelProxy.content = savePanel;

	if (self.saveOperation == NSSaveToOperation) {
		EncodingPopUpButton *encodingPopup = self.encodingPopUpButtonOutlet;
		if (encodingPopup) {
			PlainTextDocument *document = self.document;
			NSArray *encodings = [[EncodingManager sharedInstance] enabledEncodings];
			NSMutableArray *lossyEncodings = [NSMutableArray array];
			for (id loopItem in encodings) {
				if (![document canBeConvertedToEncoding:[loopItem unsignedIntValue]]) {
					[lossyEncodings addObject:loopItem];
				}
			}
			[[EncodingManager sharedInstance] registerEncoding:[document fileEncoding]];
			[encodingPopup setEncoding:[document fileEncoding] defaultEntry:NO modeEntry:NO lossyEncodings:lossyEncodings];
		}
    }

	[savePanel addObserver:self forKeyPath:@"isExtensionHidden" options:0 context:(void *)0x745274];
}


- (IBAction)selectFileFormat:(id)aSender
{
    NSSavePanel *panel = (NSSavePanel *)self.savePanel;
    if ([[aSender selectedCell] tag]==1) {
        [panel setAllowedFileTypes:@[@"de.codingmonkeys.subethaedit.seetext"]];
		[panel setAllowsOtherFileTypes:NO];
    } else {
		[panel setAllowedFileTypes:self.writablePlainTextDocumentTypes];
		[panel setAllowsOtherFileTypes:YES];

		DocumentMode *documentMode = self.document.documentMode;
		if (panel.isExtensionHidden == NO) {
			NSArray *recognizedExtensions = [documentMode recognizedExtensions];
			if ([recognizedExtensions count]) {
				NSString *fileExtension = recognizedExtensions.firstObject;
				NSString *filename = panel.nameFieldStringValue;
				if (filename.length > 0 && filename.pathExtension.length == 0) {
					panel.nameFieldStringValue = [filename stringByAppendingPathExtension:fileExtension];
				}
			}
		}
    }
}


- (NSArray *)writablePlainTextDocumentTypes
{
	NSMutableArray *writableDocumentTypes = [[self.document writableTypesForSaveOperation:self.saveOperation] mutableCopy];
	[writableDocumentTypes removeObject:@"de.codingmonkeys.subethaedit.seetext"];

	[writableDocumentTypes removeObject:self.document.fileType];
	[writableDocumentTypes insertObject:self.document.fileType atIndex:0]; // ensure mode filextesion is the default fallback

	[writableDocumentTypes removeObject:(NSString *)kUTTypeText];
	[writableDocumentTypes insertObject:(NSString *)kUTTypeText atIndex:0]; // this enables empty extensions

    return writableDocumentTypes;
}

@end
