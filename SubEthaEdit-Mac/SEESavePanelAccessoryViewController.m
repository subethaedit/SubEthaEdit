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


- (void)loadView
{
	[super loadView];
    
    NSSavePanel *savePanel = self.savePanel;
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];

    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
	[savePanel setShowsHiddenFiles:showsHiddenFiles];
	[savePanel setExtensionHidden:NO];
    [savePanel setCanSelectHiddenExtension:NO];

//	[savePanel setAllowedFileTypes:@[@"public.text"]]; // this enables empty extension, but no default extension and extension gets removed when opening panel
	[savePanel setAllowedFileTypes:self.writablePlainTextDocumentTypes];
	[savePanel setAllowsOtherFileTypes:YES];

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
    }
    [panel setExtensionHidden:NO];
}


- (NSArray *)writablePlainTextDocumentTypes
{
	NSMutableArray *writableDocumentTypes = [[self.document writableTypesForSaveOperation:self.saveOperation] mutableCopy];
	[writableDocumentTypes addObject:@"public.text"];
	[writableDocumentTypes removeObject:@"de.codingmonkeys.subethaedit.seetext"];
	[writableDocumentTypes removeObject:self.document.fileType];
	[writableDocumentTypes insertObject:self.document.fileType atIndex:0]; // ensure mode filextesion is the default fallback

    return writableDocumentTypes;
}

@end
