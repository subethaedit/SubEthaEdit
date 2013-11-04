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


+ (BOOL)prepareSavePanel:(NSSavePanel *)savePanel withSaveOperation:(NSSaveOperationType)saveOperation forDocument:(PlainTextDocument *)document
{
    SEESavePanelAccessoryViewController *viewController = nil;
    if (saveOperation == NSSaveToOperation) {
        viewController = [[[self class] alloc] initWithNibName:@"SEEPlainTextDocumentSavePanelSaveToAccessory" bundle:nil];
    } else {
        viewController = [[[self class] alloc] initWithNibName:@"SEEPlainTextDocumentSavePanelAccessory" bundle:nil];
    }
    viewController.document = document;
    viewController.savePanel = savePanel;
    viewController.saveOperation = saveOperation;
    
    savePanel.accessoryView = viewController.view;
    
    return YES;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}


- (void)loadView
{
	[super loadView];
    
    NSSavePanel *savePanel = self.savePanel;
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];
    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
	[savePanel setShowsHiddenFiles:showsHiddenFiles];
    [savePanel setCanSelectHiddenExtension:YES];
    
	self.savePanelProxy.content = savePanel;
    
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


- (IBAction)selectFileFormat:(id)aSender
{
    NSSavePanel *panel = (NSSavePanel *)self.savePanel;
    NSString *seeTextExtension = [self.document fileNameExtensionForType:@"de.codingmonkeys.subethaedit.seetext" saveOperation:NSSaveOperation];
    if ([[aSender selectedCell] tag]==1) {
        [panel setAllowedFileTypes:@[seeTextExtension]];
    } else {
        [panel setAllowedFileTypes:@[]];
        NSTextField *nameField = [panel valueForKey:@"_nameField"];
        if (nameField && [nameField isKindOfClass:[NSTextField class]]) {
            NSString *name = [nameField stringValue];
            if ([[name pathExtension] isEqualToString:seeTextExtension]) {
                [nameField setStringValue:[name stringByDeletingPathExtension]];
            }
        }
    }
    [panel setExtensionHidden:NO];
}


- (NSArray *)writableDocumentTypes
{
    return [self.document writableTypesForSaveOperation:self.saveOperation];
}

@end
