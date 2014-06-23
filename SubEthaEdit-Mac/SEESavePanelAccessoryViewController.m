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

@interface SEESavePanelAccessoryViewController () <NSOpenSavePanelDelegate>

@end

@implementation SEESavePanelAccessoryViewController


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

    NSString *documentFileType = self.document.fileType;
    NSSavePanel *savePanel = self.savePanel;
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];

    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
	[savePanel setCanSelectHiddenExtension:NO];
	[savePanel setShowsHiddenFiles:showsHiddenFiles];
	[savePanel setDelegate:self];
	
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
}

- (NSString *)panel:(NSSavePanel *)aPanel userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag {
	NSString *result = filename;
	NSString *extension = filename.pathExtension;
	if (extension.length) {
		[aPanel setAllowedFileTypes:@[extension]];
		// doubling of extensions is happening so try to avoid it
		result = [filename stringByDeletingPathExtension];
		[aPanel setNameFieldStringValue:result];
	} else {
		[aPanel setAllowedFileTypes:@[(NSString *)kUTTypeText]];
	}
	return result;
}

- (IBAction)selectFileFormat:(id)aSender
{
    NSSavePanel *panel = (NSSavePanel *)self.savePanel;
    if ([[aSender selectedCell] tag]==1) {
        [panel setAllowedFileTypes:@[@"de.codingmonkeys.subethaedit.seetext"]];
		[panel setAllowsOtherFileTypes:NO];
    } else {
		[panel setAllowsOtherFileTypes:NO];
		
		DocumentMode *documentMode = self.document.documentMode;
		NSArray *recognizedExtensions = [documentMode recognizedExtensions];
		NSString *targetValue = panel.nameFieldStringValue;
		if ([recognizedExtensions count]) {
			NSString *fileExtension = recognizedExtensions.firstObject;
			if (targetValue.length > 0 && targetValue.pathExtension.length == 0) {
				targetValue = [targetValue stringByAppendingPathExtension:fileExtension];
			}
		}
		NSLog(@"%s value: %@ targetname: %@",__FUNCTION__,panel.nameFieldStringValue,targetValue);
		NSString *extension = [targetValue pathExtension];
		if ([extension isEqualTo:@"seetext"]) {
			extension = recognizedExtensions.firstObject;
			targetValue = [[targetValue stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
		}
		if (extension.length > 0) {
			[panel setAllowedFileTypes:@[extension]];
		} else {
			[panel setAllowedFileTypes:nil];
		}
		panel.nameFieldStringValue = targetValue;

    }
}


// MARK: optional methods - alghough in remote view controller mode they don't seem to be optional

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
	//NSLog(@"%s %@",__FUNCTION__,url);
	return YES;
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
	//NSLog(@"%s %@",__FUNCTION__,url);
	return YES;
}

- (void)panel:(id)sender didChangeToDirectoryURL:(NSURL *)url NS_AVAILABLE_MAC(10_6) {
	
}

/* this does get called even if not implemented */
- (void)panel:(id)sender willExpand:(BOOL)expanding {
	// ignore
}

- (void)panelSelectionDidChange:(id)sender {
	// ignore
}


@end
