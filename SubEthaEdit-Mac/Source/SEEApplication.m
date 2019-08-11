//  SEEApplication.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.08.14.

#import "SEEApplication.h"
#import "SEEDocumentController.h"
#import "PlainTextDocument.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface NSApplication  (Scripting)
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
