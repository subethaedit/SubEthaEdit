//  SEESavePanelAccessoryViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.10.13.

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
	[savePanel setExtensionHidden:NO]; // this is needed so the initial state is extension not hidden - although docu states that the call below (setCanSelectHiddenExtension:) does this already for us
	[savePanel setCanSelectHiddenExtension:NO];
	[savePanel setShowsHiddenFiles:showsHiddenFiles];
	[savePanel setDelegate:self];

	if (UTTypeConformsTo((__bridge CFStringRef)documentFileType, (__bridge CFStringRef)kSEETypeSEEText)) {
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
	
	if ([self.savePanelAccessoryFileFormatMatrixOutlet.selectedCell tag] == 1) {
		[aPanel setAllowsOtherFileTypes:NO];
		[aPanel setAllowedFileTypes:@[kSEETypeSEEText]];
	} else if (extension.length > 0 &&
			   ([[aPanel allowedFileTypes] containsObject:extension])) {
		[aPanel setAllowedFileTypes:@[extension]];
	} else if (extension.length > 0) {
			[aPanel setAllowedFileTypes:@[(NSString *)kUTTypeData]];
	} else {
		[aPanel setAllowedFileTypes:@[(NSString *)kUTTypeText]];
	}
	return result;
}

- (IBAction)selectFileFormat:(id)aSender
{
    NSSavePanel *panel = (NSSavePanel *)self.savePanel;
    if ([[aSender selectedCell] tag]==1) {
		[panel setAllowsOtherFileTypes:NO];
        [panel setAllowedFileTypes:@[kSEETypeSEEText]];
    } else {
		[panel setAllowsOtherFileTypes:YES];
		
		DocumentMode *documentMode = self.document.documentMode;
		NSArray *recognizedExtensions = [documentMode recognizedExtensions];
		NSString *desiredExtension = [self.document.fileURL pathExtension];
		NSString *targetValue = panel.nameFieldStringValue;
		if ([[targetValue pathExtension] isEqualTo:@"seetext"]) {
			targetValue = [targetValue stringByDeletingPathExtension];
		}
		if (!desiredExtension && [recognizedExtensions count] ) {
			desiredExtension = recognizedExtensions.firstObject;
		}
		if (targetValue.length > 0 && targetValue.pathExtension.length == 0) {
			targetValue = [targetValue stringByAppendingPathExtension:desiredExtension];
		}
		//		NSLog(@"%s value: %@ targetname: %@",__FUNCTION__,panel.nameFieldStringValue,targetValue);
		NSString *extension = [targetValue pathExtension];
		if (extension.length > 0) {
			NSString *UTI = nil;
			if ([extension isEqualToString:@"seetext"] ||
				[extension isEqualToString:@"seemode"]) {
				UTI = self.document.fileType;
				
				if ([UTI isEqualToString:kSEETypeSEEText] || [UTI isEqualToString:kSEETypeSEEMode]) {
					UTI = (NSString *)kUTTypePlainText;
				}
			} else {
				UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, kUTTypeText));
			}
			if (![UTI hasPrefix:@"dyn"]) {
				[panel setAllowedFileTypes:[@[UTI] arrayByAddingObjectsFromArray:[DocumentModeManager sharedInstance].allPathExtensions]];
			} else {
				[panel setAllowedFileTypes:[@[extension] arrayByAddingObjectsFromArray:[DocumentModeManager sharedInstance].allPathExtensions]];
			}
		} else {
			[panel setAllowedFileTypes:[@[(NSString *)kUTTypeText] arrayByAddingObjectsFromArray:[DocumentModeManager sharedInstance].allPathExtensions]];
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

/* this does get called even if not implemented on 10_9_3 */
- (void)panel:(id)sender willExpand:(BOOL)expanding {
	// ignore
}

- (void)panelSelectionDidChange:(id)sender {
	// ignore
}

@end
