//  SEEApplication.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.08.14.

#import "SEEApplication.h"
#import "SEEDocumentController.h"
#import "PlainTextDocument.h"

@interface NSApplication (Scripting)
- (id)handleQuitScriptCommand:(NSScriptCommand *)aScriptCommand;
@end

@implementation SEEApplication

- (BOOL)TCM_terminateShouldKeepWindowsDeterminedByDefaultsAndSenderState:(id)aSender {
    BOOL quitShouldKeepWindows = [[NSUserDefaults standardUserDefaults] boolForKey:@"NSQuitAlwaysKeepsWindows"];
    // toggle if alternate item - e.g. option was pressed on keyboard
    // checking the menu item to more stable hopefully. could also check self.currentEvent
    if ([aSender respondsToSelector:@selector(isAlternate)]) {
        if ([aSender isAlternate]) {
            quitShouldKeepWindows = !quitShouldKeepWindows;
        }
    }
    return quitShouldKeepWindows;
}

- (void)TCM_autosaveBeforeTermination {
	NSArray *documents = [[SEEDocumentController sharedInstance] documents];
    
	for (NSDocument *document in documents) {
		if ([document isKindOfClass:[PlainTextDocument class]]) {
			PlainTextDocument *plainTextDocument = (PlainTextDocument *)document;
            if (!plainTextDocument.fileURL) { // Untitled documents
                if (!plainTextDocument.isPreparedForTermination) {
                    if ([plainTextDocument hasUnautosavedChanges]) {
                        [plainTextDocument autosaveForStateRestore];
                    } else {
                        [plainTextDocument setPreparedForTermination:YES];
                    }
                }
            }
		}
	}
}

- (void)TCM_autosaveUntitlesBeforeTermination {
    NSArray *documents = [[SEEDocumentController sharedInstance] documents];

    for (NSDocument *document in documents) {
        if ([document isKindOfClass:[PlainTextDocument class]]) {
            PlainTextDocument *plainTextDocument = (PlainTextDocument *)document;
            if ([plainTextDocument hasUnautosavedChanges]) {
                [plainTextDocument autosaveForStateRestore];
            }
            [plainTextDocument setPreparedForTermination:YES];
        }
    }
}

- (IBAction)terminate:(id)sender {
    // Read System default
    if ([self TCM_terminateShouldKeepWindowsDeterminedByDefaultsAndSenderState:sender]) {
        [self TCM_autosaveBeforeTermination];
    }
    
    // Autosave all untitled documents with changes and prepare for termination
    [self TCM_autosaveUntitlesBeforeTermination];
    
    // Dismiss dismissable sheets here too - as it turns out cocoa checks against sheets
    // before calling the App delegates terminate
    [[AppController sharedInstance] ensureNoWindowsWithAlerts];

    [super terminate:sender];
}

// this is called from the dock quit command
- (id)handleQuitScriptCommand:(NSScriptCommand *)aScriptCommand {
    if ([self TCM_terminateShouldKeepWindowsDeterminedByDefaultsAndSenderState:nil]) {
        [self TCM_autosaveBeforeTermination];
    }
    id result = [super handleQuitScriptCommand:aScriptCommand];
    return result;
}

@end
