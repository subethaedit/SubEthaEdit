//
//  SEEDocumentController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//	ARCified by Michael Ehrmann on Thu Mar 27 2014
//  Copyright (c) 2004-2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEDocumentController.h"
#import "TCMMMSession.h"
#import "SEEDocumentCreationFlags.h"
#import "PlainTextDocument.h"
#import "EncodingManager.h"
#import "DocumentModeManager.h"
#import "AppController.h"
#import "TCMMMPresenceManager.h"
#import "TCMPreferenceController.h"
#import "TCMPreferenceModule.h"
#import "NSMenuTCMAdditions.h"
#import "StylePreferences.h"
#import "GeneralPreferences.h"
#import "FoldableTextStorage.h"
//#import "MoreSecurity.h"
#import "PlainTextWindowController.h"
#import "SEEOpenPanelAccessoryViewController.h"
#import "SEEDocumentListWindowController.h"
#import "NSApplicationTCMAdditions.h"
#import "SEEScopedBookmarkManager.h"

#import <PSMTabBarControl/PSMTabBarControl.h>
#import <objc/objc-runtime.h>			// for objc_msgSend

NSString *const RecentDocumentsDidChangeNotification = @"RecentDocumentsDidChangeNotification";

@interface SEEDocumentController ()

@property (nonatomic, strong) SEEDocumentListWindowController *documentListWindowController;

@property (assign) BOOL isOpeningInTab;
@property (assign) NSUInteger filesToOpenCount;
@property (assign) BOOL isOpeningUsingAlternateMenuItem;
@property (nonatomic, strong) NSMutableDictionary *documentCreationFlagsLookupDict;
@property (nonatomic, strong) NSMutableArray *filenamesFromLastRunOpenPanel;

@property (nonatomic, copy) NSURL *locationForNextOpenPanel;
@property (nonatomic, readwrite, assign) NSStringEncoding encodingFromLastRunOpenPanel;
@property (nonatomic, readwrite, copy) NSString *modeIdentifierFromLastRunOpenPanel;

@end


@implementation SEEDocumentController

+ (SEEDocumentController *)sharedInstance {
    return (SEEDocumentController *)[NSDocumentController sharedDocumentController];
}

- (id)init {
    self = [super init];
    if (self) {
        self.filenamesFromLastRunOpenPanel = [NSMutableArray array];
		self.documentCreationFlagsLookupDict = [NSMutableDictionary dictionary];

		I_propertiesForOpenedFiles = [NSMutableDictionary new];
        I_suspendedSeeScriptCommands = [NSMutableDictionary new];
        I_waitingDocuments = [NSMutableDictionary new];
        I_refCountsOfSeeScriptCommands = [NSMutableDictionary new];
        I_pipingSeeScriptCommands = [NSMutableArray new];
        I_windowControllers = [NSMutableArray new];
    }
    return self;
}

// actually never gets called - as any other top level nib object isn't dealloced...
- (void)dealloc {
    self.modeIdentifierFromLastRunOpenPanel = nil;
    self.filenamesFromLastRunOpenPanel = nil;
    self.documentCreationFlagsLookupDict = nil;
	self.locationForNextOpenPanel = nil;
}


#pragma mark - Actions

- (IBAction)mergeAllWindows:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"Are you sure you want to merge all windows?", nil)];
    [alert setInformativeText:NSLocalizedString(@"Merging windows moves all open tabs and windows into a single, tabbed editor window. This cannot be undone.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Merge", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    int response = [alert runModal];
    if (NSAlertFirstButtonReturn == response) {
        PlainTextWindowController *targetWindowController = [self activeWindowController];
        id document = [targetWindowController document];
        int count = [I_windowControllers count];
        while (--count >= 0) {
            PlainTextWindowController *sourceWindowController = [I_windowControllers objectAtIndex:count];
            if (sourceWindowController != targetWindowController) {
                [sourceWindowController moveAllTabsToWindowController:targetWindowController];
                [sourceWindowController close];
                [self removeWindowController:sourceWindowController];
            }
        }
        [targetWindowController setDocument:document];
    }
}

- (IBAction)alwaysShowTabBar:(id)sender
{
    BOOL flag = ([sender state] == NSOnState) ? NO : YES;
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:kSEEDefaultsKeyAlwaysShowTabBar];

    PlainTextWindowController *windowController;
    for (windowController in I_windowControllers) {
        PSMTabBarControl *tabBar = [windowController tabBar];
        if (![windowController hasManyDocuments]) {
            [tabBar setHideForSingleTab:!flag];
            [tabBar hideTabBar:!flag animate:YES];
        } else {
            [tabBar setHideForSingleTab:!flag];
        }
    }

}

- (IBAction)installMode:(id)sender {
    [NSApp stopModal];
}

- (IBAction)changeModeInstallationDomain:(id)sender {
    int tag = [[O_modeInstallerDomainMatrix selectedCell] tag];
    NSString *informativeText = @"";
    NSBundle *modeBundle = [NSBundle bundleWithPath:I_currentModeFileName];
    NSString *modeIdentifier = [modeBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
    if (mode) {
        NSBundle *installedModeBundle = [mode bundle];
        NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *installedModeFileName = [installedModeBundle bundlePath];
        NSString *installedModeName = [NSString stringWithFormat:@"%@ (%@)", [installedModeFileName lastPathComponent], versionStringOfInstalledMode];
        informativeText = [NSString stringWithFormat:NSLocalizedString(@"Mode \"%@\" is already installed in \"%@\".", nil), installedModeName, installedModeFileName];

        short domain;
        BOOL isKnownDomain = YES;
        if ([installedModeFileName hasPrefix:@"/Users/"]) {
            domain = kUserDomain;
        } else if ([installedModeFileName hasPrefix:@"/Library/"]) {
            domain = kLocalDomain;
        } else if ([installedModeFileName hasPrefix:@"/Network/"]) {
            domain = kNetworkDomain;
        } else {
            isKnownDomain = NO;
        }

        if (tag == 0) {
            if (!isKnownDomain || domain == kNetworkDomain || domain == kLocalDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
            } else if (domain == kUserDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
            }
        } else if (tag == 1) {
            if (!isKnownDomain || domain == kNetworkDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
            } else if (domain == kLocalDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
            } else if (domain == kUserDomain) {
                informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"The installed mode will override your new mode.", nil)];
            }
        }
    }

    if (tag == 1) {
        if ([informativeText length] > 0)
            informativeText = [informativeText stringByAppendingString:@" "];
        informativeText = [informativeText stringByAppendingString:NSLocalizedString(@"When you click Install, you'll be asked to enter the name and password for an administrator of this computer.", nil)];
    }
    [O_modeInstallerInformativeTextField setObjectValue:informativeText];
}

- (IBAction)cancelModeInstallation:(id)sender {
    [NSApp abortModal];
}

- (IBAction)concealAllDocuments:(id)aSender {
    PlainTextDocument *document=nil;
    NSEnumerator *documents = [[self documents] objectEnumerator];
    while ((document=[documents nextObject])) {
        if ([document isAnnounced]) {
            [document setIsAnnounced:NO];
        }
    }
}


#pragma mark - DocumentList window

- (IBAction)showDocumentListWindow:(id)sender {
	if (!self.documentListWindowController) {
		SEEDocumentListWindowController *networkBrowser = [[SEEDocumentListWindowController alloc] initWithWindowNibName:@"SEEDocumentListWindowController"];
		self.documentListWindowController = networkBrowser;
	}
	if (sender == NSApp) {
		self.documentListWindowController.shouldCloseWhenOpeningDocument = YES;
	} else {
		self.documentListWindowController.shouldCloseWhenOpeningDocument = NO;
	}
	[self.documentListWindowController showWindow:sender];
}



#pragma mark - DocumentTypes

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError **)outError
{
	NSString *result = [super typeForContentsOfURL:url error:outError];
	return result;
}


- (Class)documentClassForType:(NSString *)typeName
{
	Class documentClass = [super documentClassForType:typeName];
	if ([typeName isEqualToString:@"de.codingmonkeys.subethaedit.seetext"] && [documentClass class] != [PlainTextDocument class]) {
		documentClass = [PlainTextDocument class];
	} else if ([typeName isEqualToString:@"de.codingmonkeys.subethaedit.mode"] && [documentClass class] != [PlainTextDocument class]) {
		documentClass = [PlainTextDocument class];
	}

	return  documentClass;
}


#pragma mark - Tab menu

- (void)updateMenuWithTabMenuItems:(NSMenu *)aMenu shortcuts:(BOOL)withShortcuts {
    // NSLog(@"%s",__FUNCTION__);
    static NSMutableSet *menusCurrentlyUpdating = nil;
    if (!menusCurrentlyUpdating) menusCurrentlyUpdating = [NSMutableSet new];
    if ([menusCurrentlyUpdating containsObject:aMenu]) {
        NSLog(@"%s woof woof",__FUNCTION__);
    } else {
        [menusCurrentlyUpdating addObject:aMenu];
        [aMenu removeAllItems];
        NSMenuItem *prototypeMenuItem=
            [[NSMenuItem alloc] initWithTitle:@""
                                       action:@selector(showDocumentAtIndex:)
                                keyEquivalent:@""];
        PlainTextWindowController *windowController = nil;
        BOOL firstWC = YES;
        for (windowController in I_windowControllers) {
            NSEnumerator      *documents = [[windowController orderedDocuments] objectEnumerator];
            PlainTextDocument *document = nil;
            if (!firstWC) {
                [aMenu addItem:[NSMenuItem separatorItem]];
            }
            BOOL hasSheet = [[windowController window] attachedSheet] ? YES : NO;
            int isMainWindow = ([[windowController window] isMainWindow] || [[windowController window] isKeyWindow]) ? 1 : NO;
//            NSLog(@"%s %@ was main window: %d %d",__FUNCTION__, windowController, isMainWindow, withShortcuts);
            int documentPosition = 0;
            while ((document = [documents nextObject])) {
                [prototypeMenuItem setTarget:windowController];
                [prototypeMenuItem setTitle:[windowController windowTitleForDocumentDisplayName:[document displayName] document:document]];
                [prototypeMenuItem setRepresentedObject:[NSNumber numberWithInt:documentPosition]];
                [prototypeMenuItem setEnabled:!hasSheet];
                if (withShortcuts) {
                    if (isMainWindow && isMainWindow < 10) {
//						NSLog(@"added shortcut");
                        [prototypeMenuItem setKeyEquivalent:[NSString stringWithFormat:@"%d",isMainWindow%10]];
                        [prototypeMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
                        isMainWindow++;
                    } else {
                        [prototypeMenuItem setKeyEquivalent:@""];
                    }
                }
                NSMenuItem *itemToAdd = [prototypeMenuItem copy];
                [aMenu addItem:itemToAdd];
//				NSLog(@"%@",itemToAdd);
                [itemToAdd setMark:[document isDocumentEdited]];
                documentPosition++;
            }
            firstWC = NO;
        }
        [menusCurrentlyUpdating removeObject:aMenu];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)aMenu {
    [self updateMenuWithTabMenuItems:aMenu shortcuts:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];

    if (selector == @selector(concealAllDocuments:)) {
        return [[[TCMMMPresenceManager sharedInstance] announcedSessions] count]>0;
    } else if (selector == @selector(alwaysShowTabBar:)) {
        BOOL isChecked = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar];
        [menuItem setState:(isChecked ? NSOnState : NSOffState)];
        return YES;
    } else if (selector == @selector(openAlternateDocument:)) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab]) {
            [menuItem setTitle:NSLocalizedString(@"Open in New Window...", @"Menu Entry for opening files in a new window.")];
        } else {
            [menuItem setTitle:NSLocalizedString(@"Open in Front Window...", @"Menu Entry for opening files in the front window.")];
        }
        return YES;
    } else if ([menuItem tag] == GotoTabMenuItemTag) {
        if ([[self documents] count] >0) {
            [self updateMenuWithTabMenuItems:[menuItem submenu] shortcuts:YES];
            return YES;
        } else {
            [[menuItem submenu] removeAllItems];
            return NO;
        };
    } else if (selector == @selector(mergeAllWindows:)) {
        BOOL hasSheet = NO;
        PlainTextWindowController *controller;
        for (controller in I_windowControllers) {
            if ([[controller window] attachedSheet] != nil) {
                hasSheet = YES;
                break;
            }
        }
        return (([I_windowControllers count] > 1) && !hasSheet);
    }
    return [super validateMenuItem:menuItem];
}

- (void)updateTabMenu {
    NSMenuItem *menuItem = [[[[NSApp mainMenu] itemWithTag:WindowMenuTag] submenu] itemWithTag:GotoTabMenuItemTag];
    if (menuItem)
    {
        if ([[self documents] count] >0) {
            [self updateMenuWithTabMenuItems:[menuItem submenu] shortcuts:YES];
        } else {
            [[menuItem submenu] removeAllItems];
        }
    }
}


- (IBAction)menuValidationNoneAction:(id)aSender {

}



- (NSMenu *)documentMenu {
    NSMenu *documentMenu = [NSMenu new];
    [self updateMenuWithTabMenuItems:documentMenu shortcuts:NO];
    return documentMenu;
}

- (void)addProxyDocumentWithSession:(TCMMMSession *)aSession {
    PlainTextDocument *document = [[PlainTextDocument alloc] initWithSession:aSession];
    [document makeProxyWindowController];
    [self addDocument:document];
    [document showWindows];
}

- (NSArray *)documentsInMode:(DocumentMode *)aDocumentMode {
    NSMutableArray *result=[NSMutableArray array];
    NSEnumerator *documents=[[self documents] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document=[documents nextObject])) {
        if ([[document documentMode] isEqual:aDocumentMode]) {
            [result addObject:document];
        }
    }
    return result;
}


#pragma mark - Handling Window Controllers

- (PlainTextDocument *)frontmostPlainTextDocument {
    NSWindow *window = nil;
    for (window in [NSApp orderedWindows]) {
        NSWindowController *controller = [window windowController];
        if ([controller isKindOfClass:[PlainTextWindowController class]]) {
	        return [[(PlainTextWindowController *)controller activePlainTextEditor] document];
        }
    }
    return nil;
}

- (PlainTextWindowController *)activeWindowController {
    int count = [I_windowControllers count];
    if (count == 0) {
        PlainTextWindowController *controller = [[PlainTextWindowController alloc] init];
        [I_windowControllers addObject:controller];
        count++;
    }
    PlainTextWindowController *activeWindowController = nil;
    while (--count >= 0) {
        PlainTextWindowController *controller = [I_windowControllers objectAtIndex:count];
        if (![[controller window] attachedSheet]) {
            activeWindowController = controller;
            if ([[controller window] isMainWindow]) break;
        }
    }
    if (!activeWindowController) {
        activeWindowController = [[PlainTextWindowController alloc] init];
        [I_windowControllers addObject:activeWindowController];
    }
    return activeWindowController;
}

- (void)addWindowController:(id)aWindowController {
    [I_windowControllers addObject:aWindowController];
}

- (void)removeWindowController:(id)aWindowController {
	__autoreleasing id autoreleasedWindowController = aWindowController;
    [I_windowControllers removeObject:autoreleasedWindowController];
}

#pragma mark - Open new document

- (void)newDocumentWithModeIdentifier:(NSString *)aModeIdentifier {
    if (aModeIdentifier) {
		DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
        DocumentMode *newMode = [modeManager documentModeForIdentifier:aModeIdentifier];
        if (!newMode) return;
		
        PlainTextDocument *document = (PlainTextDocument *)[self openUntitledDocumentAndDisplay:YES error:nil];
        [document setDocumentMode:newMode];
        [document resizeAccordingToDocumentMode];
        [document showWindows];

        NSStringEncoding encoding = [[newMode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        if (encoding < SmallestCustomStringEncoding) {
            [document setFileEncoding:encoding];
        }

        NSString *templateFileContent=[newMode templateFileContent];
        if (templateFileContent && ![templateFileContent canBeConvertedToEncoding:[document fileEncoding]]) {
            templateFileContent=[[NSString alloc]
								  initWithData:[templateFileContent dataUsingEncoding:[document fileEncoding] allowLossyConversion:YES]
								  encoding:[document fileEncoding]];
        }

        if (templateFileContent) {
            FoldableTextStorage *textStorage=(FoldableTextStorage *)[document textStorage];
            [textStorage replaceCharactersInRange:NSMakeRange(0,[textStorage length]) withString:templateFileContent];
            [document updateChangeCount:NSChangeCleared];
        }
    }
}


- (IBAction)newDocument:(id)aSender
{
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = NO;
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	if ([aSender respondsToSelector:@selector(representedObject)]) {
		DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
		NSString *identifier = [modeManager documentModeIdentifierForTag:[[aSender representedObject] tag]];
		[self newDocumentWithModeIdentifier:identifier];
	} else {
		[self newDocumentWithModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]];
	}
}

- (IBAction)newAlternateDocument:(id)sender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = YES;
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier = [modeManager documentModeIdentifierForTag:[[sender representedObject] tag]];
	[self newDocumentWithModeIdentifier:identifier];
}


- (IBAction)newDocumentInTab:(id)sender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = YES;
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	[self newDocumentWithModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]];
}


- (IBAction)newDocumentByUserDefault:(id)sender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	[self newDocumentWithModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]];
}


- (IBAction)newDocumentWithModeMenuItem:(id)aSender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = NO;
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

    DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier = [modeManager documentModeIdentifierForTag:[aSender tag]];
	[self newDocumentWithModeIdentifier:identifier];
}


- (IBAction)newAlternateDocumentWithModeMenuItem:(id)sender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = YES;
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier = [modeManager documentModeIdentifierForTag:[sender tag]];
	[self newDocumentWithModeIdentifier:identifier];
}


- (IBAction)newDocumentWithModeMenuItemFromDock:(id)aSender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

    DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier = [modeManager documentModeIdentifierForTag:[aSender tag]];
	[self newDocumentWithModeIdentifier:identifier];

	[NSApp activateIgnoringOtherApps:YES];
}


- (IBAction)newDocumentFromDock:(id)aSender {
	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
		self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
	}

	DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier=[modeManager documentModeIdentifierForTag:[[aSender representedObject] tag]];
	[self newDocumentWithModeIdentifier:identifier];

	[NSApp activateIgnoringOtherApps:YES];
}


- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
	id result = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
	return result;
}


- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError {
	id result = [super makeUntitledDocumentOfType:typeName error:outError];

	if ([result isKindOfClass:PlainTextDocument.class]) {
		PlainTextDocument *plainTextDocument = (PlainTextDocument *)result;

		SEEDocumentCreationFlags *creationFlags = nil;
		@synchronized(self.documentCreationFlagsLookupDict) {
			creationFlags = self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"];
		}
		if (creationFlags) {
			plainTextDocument.attachedCreationFlags = creationFlags;
			@synchronized(self.documentCreationFlagsLookupDict) {
				[self.documentCreationFlagsLookupDict removeObjectForKey:@"MakeUntitledDocument"];
			}
		}
	}

	return result;
}


#pragma mark - Open existing documents

- (void)beginOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)inTypes completionHandler:(void (^)(NSInteger result))completionHandler {

	SEEOpenPanelAccessoryViewController *openPanelAccessoryViewController = [SEEOpenPanelAccessoryViewController openPanelAccessoryControllerForOpenPanel:openPanel];
	if ([self locationForNextOpenPanel]) {
		[openPanel setDirectoryURL:[self locationForNextOpenPanel]];
		[self setLocationForNextOpenPanel:nil];
	}

	[self.filenamesFromLastRunOpenPanel removeAllObjects];

	[super beginOpenPanel:openPanel forTypes:inTypes completionHandler:^(NSInteger result) {
		[self setModeIdentifierFromLastRunOpenPanel:[openPanelAccessoryViewController.modePopUpButtonOutlet selectedModeIdentifier]];
		[self setEncodingFromLastRunOpenPanel:[[openPanelAccessoryViewController.encodingPopUpButtonOutlet selectedItem] tag]];

		if (result == NSFileHandlingPanelOKButton) {
			for (NSURL *URL in openPanel.URLs) {
				if ([URL isFileURL]) {
					NSString *fileName = [URL path];
					BOOL isDir = NO;
					BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fileName];
					NSString *extension = [fileName pathExtension];
					if (isFilePackage && [extension isEqualToString:@"mode"]) {
						// this is done in openDocumentWithContentsOfURL:display:completionHandler:
						//[self openModeFile:fileName];
					} else if ([[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir] && isDir && !isFilePackage) {
						// this is done in openDocumentWithContentsOfURL:display:completionHandler:
						//[self openDirectory:fileName];
					} else {
						if (self.isOpeningUsingAlternateMenuItem && [self documentForURL:URL]) {
							// do nothing to not accidently put a window in front and distribute the new files
						} else {
							[self.filenamesFromLastRunOpenPanel addObject:fileName];
						}
					}
				}

				@synchronized(self.documentCreationFlagsLookupDict) {
					SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
					creationFlags.openInTab = self.isOpeningInTab;
					creationFlags.isAlternateAction = self.isOpeningUsingAlternateMenuItem;
					self.documentCreationFlagsLookupDict[URL] = creationFlags;
				}

				// if should open in tabs is enabled we like to open all of them in one new window. so only the first document should be opened in a new window in this case
				if (self.isOpeningInTab) {
					self.isOpeningUsingAlternateMenuItem = NO;
				}
			}
			self.isOpeningInTab = NO;
		}

		self.filesToOpenCount = openPanel.URLs.count;

		if (completionHandler) {
			completionHandler(result);
		}
	}];
}

- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument {
    NSInteger index = [self.filenamesFromLastRunOpenPanel indexOfObject:[[aDocument fileURL] path]];
    if (index == NSNotFound) {
        return NO;
    }
    [self.filenamesFromLastRunOpenPanel removeObjectAtIndex:index];
    return YES;
}

- (NSDictionary *)propertiesForOpenedFile:(NSString *)fileName {
    return [I_propertiesForOpenedFiles objectForKey:fileName];
}

- (IBAction)openNormalDocument:(id)aSender {
	self.isOpeningInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
	self.isOpeningUsingAlternateMenuItem = NO;
    [self openDocument:(id)aSender];
}

- (IBAction)openAlternateDocument:(id)aSender {
	self.isOpeningInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
	self.isOpeningUsingAlternateMenuItem = YES;
    [self openDocument:(id)aSender];
}


#pragma mark - Document Opening

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *, BOOL, NSError *))completionHandler
{
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"%s", __FUNCTION__);

    NSString *filename = [url path];
    BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename];
    NSString *extension = [filename pathExtension];
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
    if (isFilePackage && [extension isEqualToString:@"mode"]) {
        [self openModeFile:filename];

		if (completionHandler) {
			completionHandler(nil, NO, nil);
		}
    } else if (!isFilePackage && isDirectory) {
        [self setLocationForNextOpenPanel:url];
        [self performSelector:@selector(openDocument:) withObject:nil afterDelay:0.0];

		if (completionHandler) {
			completionHandler(nil, NO, nil);
		}
    } else {
		[super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error)
		 {
			 NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
			 if (document && [document isKindOfClass:PlainTextDocument.class] && displayDocument) {
				 [(PlainTextDocument *)document handleOpenDocumentEvent:eventDesc];
			 }

			 if (completionHandler) {
				 completionHandler(document, displayDocument, error);
			 }
		 }];
	}
}


- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	id result = [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];

	if ([result isKindOfClass:PlainTextDocument.class]) {
		PlainTextDocument *plainTextDocument = (PlainTextDocument *)result;

		SEEDocumentCreationFlags *creationFlags = nil;
		@synchronized(self.documentCreationFlagsLookupDict) {
			creationFlags = self.documentCreationFlagsLookupDict[url];
		}
		if (creationFlags) {
			plainTextDocument.attachedCreationFlags = creationFlags;
			@synchronized(self.documentCreationFlagsLookupDict) {
				[self.documentCreationFlagsLookupDict removeObjectForKey:url];
			}
		}
	}

	return result;
}


#pragma mark - NSWindowRestoration

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
//	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	SEEDocumentController *documentController = [[self class] sharedDocumentController];

	if ([identifier isEqualToString:@"DocumentList"]) {
		[documentController showDocumentListWindow:self];

		[self finishRestoreWindowWithIdentifier:identifier
										  state:state
									   document:nil
										 window:documentController.documentListWindowController.window
										  error:nil
							  completionHandler:completionHandler];
	} else {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = NO;
		documentController.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;

		[super restoreWindowWithIdentifier:identifier state:state completionHandler:^(NSWindow *window, NSError *inError) {
//			NSLog(@"%s - %d", __FUNCTION__, __LINE__);

			NSDocument *selectedDocument = [[window windowController] document];
			NSString *selectedDocumentTabLookupKey = [state decodeObjectForKey:@"PlainTextWindowSelectedTabLookupKey"];
			if (selectedDocumentTabLookupKey && [selectedDocument isKindOfClass:[PlainTextDocument class]]) {
				PlainTextDocument *plainTextDocument = (PlainTextDocument *)selectedDocument;
				PlainTextWindowController *windowController = window.windowController;
				NSTabViewItem *tabItem = [windowController tabViewItemForDocument:plainTextDocument];
				PlainTextWindowControllerTabContext *tabContext = tabItem.identifier;
				tabContext.uuid = selectedDocumentTabLookupKey;
			}


			// we also may have to restore tabs in this window
			NSArray *tabs = [state decodeObjectForKey:@"PlainTextWindowOpenTabLookupKeys"];
			__block NSUInteger restoredTabsCount = 0;

			if (tabs.count > 1) {
				for (NSString *tabLookupKey in tabs) {
					NSData *tabData = [state decodeObjectForKey:tabLookupKey];
					NSKeyedUnarchiver *tabState = [[NSKeyedUnarchiver alloc] initForReadingWithData:tabData];

					if (tabState) {
						NSData *documentURLBookmark = [tabState decodeObjectForKey:@"SEETabContextDocumentURLBookmark"];
						NSURL *documentURL = [NSURL URLByResolvingBookmarkData:documentURLBookmark
																	   options:NSURLBookmarkResolutionWithSecurityScope
																 relativeToURL:nil
														   bookmarkDataIsStale:NULL
																		 error:NULL];
						[documentURL startAccessingSecurityScopedResource];

						NSData *documentAutosaveURLBookmark = [tabState decodeObjectForKey:@"SEETabContextDocumentAutosaveURLBookmark"];
						NSURL *documentAutosaveURL = [NSURL URLByResolvingBookmarkData:documentAutosaveURLBookmark
																			   options:NSURLBookmarkResolutionWithSecurityScope
																		 relativeToURL:nil
																   bookmarkDataIsStale:NULL
																				 error:NULL];

						// TODO: We should restore the original display name for untitled documents
//						NSString *tabDisplayName = [tabState decodeObjectForKey:@"SEETabContextDocumentDisplayName"];

						if (! documentAutosaveURL) { // if there is no autosave file make sure to read from original URL
							documentAutosaveURL = documentURL;
						} else {
							[documentAutosaveURL startAccessingSecurityScopedResource];
						}
						[tabState finishDecoding];

						if (documentAutosaveURL) {
							if (! [tabLookupKey isEqualToString:selectedDocumentTabLookupKey]) {
								[NSApp extendStateRestoration];
								[documentController reopenDocumentForURL:documentURL withContentsOfURL:documentAutosaveURL inWindow:window display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {

									if ([document isKindOfClass:[PlainTextDocument class]]) {
										PlainTextDocument *plainTextDocument = (PlainTextDocument *)document;
										PlainTextWindowController *windowController = window.windowController;
										NSTabViewItem *tabItem = [windowController tabViewItemForDocument:plainTextDocument];
										PlainTextWindowControllerTabContext *tabContext = tabItem.identifier;
										tabContext.uuid = tabLookupKey;
									}

									restoredTabsCount++;
									if (restoredTabsCount == tabs.count) {
										[self finishRestoreWindowWithIdentifier:identifier
																		  state:state
																	   document:selectedDocument
																		 window:window
																		  error:inError
															  completionHandler:completionHandler];
									}
									[NSApp completeStateRestoration];
								}];
							} else {
								// this was the selected tab of the window so it's already restored...
								// need to select it again after all tabs are restored
								restoredTabsCount++;
							}
						} else {
							if (! [tabLookupKey isEqualToString:selectedDocumentTabLookupKey]) {
								// untitled document tab ifnore the selected tab
								SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
								creationFlags.openInTab = YES;
								creationFlags.tabWindow = window;
								documentController.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;

								NSDocument *document = [documentController openUntitledDocumentAndDisplay:YES error:nil];

								if ([document isKindOfClass:[PlainTextDocument class]]) {
									PlainTextDocument *plainTextDocument = (PlainTextDocument *)document;
									PlainTextWindowController *windowController = window.windowController;
									NSTabViewItem *tabItem = [windowController tabViewItemForDocument:plainTextDocument];
									PlainTextWindowControllerTabContext *tabContext = tabItem.identifier;
									tabContext.uuid = tabLookupKey;
								}
							}
							restoredTabsCount++;
						}
					} else {
						// there is no valid data for a tab that is stored in the tab order array.
						// maybe this should be an error? Currently I think its better to fail gracefully.
						restoredTabsCount++;
					}

					if (restoredTabsCount == tabs.count) {
						[self finishRestoreWindowWithIdentifier:identifier
														  state:state
													   document:selectedDocument
														 window:window
														  error:inError
											  completionHandler:completionHandler];
					}
				}
			} else {
				[self finishRestoreWindowWithIdentifier:identifier
												  state:state
											   document:selectedDocument
												 window:window
												  error:inError
									  completionHandler:completionHandler];
			}
		}];
	}
}


+ (void)finishRestoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state document:(NSDocument *)document window:(NSWindow *)window error:(NSError *)inError completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {

	NSWindowController *windowController = window.windowController;
	if ([windowController isKindOfClass:[PlainTextWindowController class]]) {
		PlainTextWindowController *plainTextWindowController = (PlainTextWindowController *)windowController;

//		NSArray *tabNames = [plainTextWindowController.tabView.tabViewItems valueForKey:@"label"];
//		NSArray *tabs = [state decodeObjectForKey:@"PlainTextWindowOpenTabNames"];
//
//		NSLog(@"\n%@\n%@", tabNames, tabs);

		[plainTextWindowController selectTabForDocument:document];
	}

	// completion handler will trigger -(void)restoreStateWithCoder: on the window
	if (completionHandler) {
		completionHandler(window, inError);
	}
}


- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
{
//	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	[self.filenamesFromLastRunOpenPanel removeAllObjects];

	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = NO;
		self.documentCreationFlagsLookupDict[contentsURL] = creationFlags;
	}

	[super reopenDocumentForURL:urlOrNil withContentsOfURL:contentsURL display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
//		NSLog(@"%s - %d", __FUNCTION__, __LINE__);
		if (completionHandler) {
			completionHandler(document, documentWasAlreadyOpen, error);
		}
	}];
}


- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL inWindow:(NSWindow *)parentWindow display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
{
//	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	[self.filenamesFromLastRunOpenPanel removeAllObjects];

	@synchronized(self.documentCreationFlagsLookupDict) {
		SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
		creationFlags.openInTab = YES;
		creationFlags.tabWindow = parentWindow;

		self.documentCreationFlagsLookupDict[contentsURL] = creationFlags;
	}

	[super reopenDocumentForURL:urlOrNil withContentsOfURL:contentsURL display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
//		NSLog(@"%s - %d", __FUNCTION__, __LINE__);
		if (completionHandler) {
			completionHandler(document, documentWasAlreadyOpen, error);
		}
	}];
}


- (id)makeDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError {
//	NSLog(@"%s - %d", __FUNCTION__, __LINE__);
	NSAssert(contentsURL, @"%s - contentsURL can't be nil.", __FUNCTION__);

	id result = [super makeDocumentForURL:urlOrNil withContentsOfURL:contentsURL ofType:typeName error:outError];

	if ([result isKindOfClass:PlainTextDocument.class]) {
		PlainTextDocument *plainTextDocument = (PlainTextDocument *)result;

		SEEDocumentCreationFlags *creationFlags = nil;
		@synchronized(self.documentCreationFlagsLookupDict) {
			creationFlags = self.documentCreationFlagsLookupDict[contentsURL];
		}
		if (creationFlags) {
			plainTextDocument.attachedCreationFlags = creationFlags;
			@synchronized(self.documentCreationFlagsLookupDict) {
				[self.documentCreationFlagsLookupDict removeObjectForKey:contentsURL];
			}
		}
	}

	return result;
}


#pragma mark - Recent Document Support

- (void)noteNewRecentDocumentURL:(NSURL *)url {
	[super noteNewRecentDocumentURL:url];

	// This seems to be very hacky, but currently the only version that works.
	// recentDocumentURLs gets updated asyncroniously and there is no hook to update it then
	// we don't get events of unmounting media etc right now.
	NSNotification *recentDocumentsDidChangeNotification = [NSNotification notificationWithName:RecentDocumentsDidChangeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:recentDocumentsDidChangeNotification
											   postingStyle:NSPostASAP
											   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
												   forModes:@[NSRunLoopCommonModes]];
}

- (IBAction)clearRecentDocuments:(id)sender {
	[super clearRecentDocuments:sender];

	NSNotification *recentDocumentsDidChangeNotification = [NSNotification notificationWithName:RecentDocumentsDidChangeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:recentDocumentsDidChangeNotification
											   postingStyle:NSPostASAP
											   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
												   forModes:@[NSRunLoopCommonModes]];
}

#pragma mark - Apple Script support

- (id)handleOpenScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        id file;
        NSEnumerator *parameterEnumerator = [directParameter objectEnumerator];
        while ((file = [parameterEnumerator nextObject])) {
            if ([file isKindOfClass:[NSURL class]]) {
                [files addObject:[file path]];
            } else {
                [files addObject:file];
            }
        }
    } else if ([directParameter isKindOfClass:[NSString class]]) {
        [files addObject:directParameter];
    } else if ([directParameter isKindOfClass:[NSURL class]]) {
        [files addObject:[directParameter path]];
    }
    
    NSString *filename;
    for (filename in files) {
		BOOL isSEEStdinTempFile = [[filename pathExtension] isEqualToString:@"seetmpstdin"];
		if (isSEEStdinTempFile) continue;
        BOOL isDir = NO;
        BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename];
        NSString *extension = [filename pathExtension];
        if (isFilePackage && [extension isEqualToString:@"mode"]) {
            [self openModeFile:filename];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir] && isDir && !isFilePackage) {
            [self openDirectory:filename];
        } else {
            [I_propertiesForOpenedFiles setObject:properties forKey:filename];
			[[SEEScopedBookmarkManager sharedManager] startAccessingScriptedFileURL:[NSURL fileURLWithPath:filename]];
			[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
				if (error) NSLog(@"%@",error);
			}];
        }
    }
            
    return nil;
}

- (id)handlePrintScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"properties: %@", properties);
    
    NSMutableArray *files = [NSMutableArray array];
    id directParameter = [command directParameter];
    if ([directParameter isKindOfClass:[NSArray class]]) {
        id file;
        NSEnumerator *parameterEnumerator = [directParameter objectEnumerator];
        while ((file = [parameterEnumerator nextObject])) {
            if ([file isKindOfClass:[NSURL class]]) {
                [files addObject:[file path]];
            } else {
                [files addObject:file];
            }
        }
    } else if ([directParameter isKindOfClass:[NSString class]]) {
        [files addObject:directParameter];
    } else if ([directParameter isKindOfClass:[NSURL class]]) {
        [files addObject:[directParameter path]];
    }
    
    NSString *filename;
    for (filename in files) {
        [I_propertiesForOpenedFiles setObject:properties forKey:filename];
        BOOL shouldClose = ([self documentForURL:[NSURL fileURLWithPath:filename]] == nil);

		[[SEEScopedBookmarkManager sharedManager] startAccessingScriptedFileURL:[NSURL fileURLWithPath:filename]];
		[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:NO completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
			if (error) {
				NSLog(@"%@",error);
			} else {
				[document printDocumentWithSettings:nil showPrintPanel:NO delegate:nil didPrintSelector:NULL contextInfo:NULL];
				if (shouldClose && !documentWasAlreadyOpen) {
					[document close];
				}
			}
		}];
    }
    return nil;
}

- (id)handleSeeScriptCommand:(NSScriptCommand *)command {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"command: %@", [command description]);

    NSScriptClassDescription *classDescription = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] 
                                                    classDescriptionWithAppleEventCode:'docu'];
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    NSDictionary *evaluatedProperties = [[command evaluatedArguments] objectForKey:@"WithProperties"];
    NSEnumerator *enumerator = [evaluatedProperties keyEnumerator];
    id argumentKey;
    while ((argumentKey = [enumerator nextObject])) {
        if ([argumentKey isKindOfClass:[NSNumber class]]) {
            NSString *key = [classDescription keyWithAppleEventCode:[argumentKey unsignedLongValue]];
            if (key) {
                if ([argumentKey unsignedLongValue] == 'Mode') {
                    // Workaround for see tool and older scripts which assume that the mode property is a string.
                    // Properties aren't coerced automatically.
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:@"mode"];
                } else {
                    [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:key];
                }
            }
        } else if ([argumentKey isKindOfClass:[NSString class]]) {
            [properties setObject:[evaluatedProperties objectForKey:argumentKey] forKey:argumentKey];
        }
    }
    
    
    NSString *jobDescription = [[command evaluatedArguments] objectForKey:@"JobDescription"];    
    BOOL shouldPrint = [[[command evaluatedArguments] objectForKey:@"ShouldPrint"] boolValue];
    BOOL isPipingOut = [[[command evaluatedArguments] objectForKey:@"PipeOut"] boolValue];
    BOOL shouldWait = [[[command evaluatedArguments] objectForKey:@"ShouldWait"] boolValue];
    BOOL shouldMakePipeDirty = [[[command evaluatedArguments] objectForKey:@"ShouldMakePipeDirty"] boolValue];
    NSString *openIn = [[command evaluatedArguments] objectForKey:@"OpenIn"];
    NSArray *gotoLineComponents = [[[command evaluatedArguments] objectForKey:@"GotoString"] componentsSeparatedByString:@":"];
    int lineToGoTo=0,columnToGoTo=-1, selectionLength = 0;
    BOOL shouldJumpToLine = NO;
    if ([gotoLineComponents count]>0) {
        if ([[NSScanner scannerWithString:[gotoLineComponents objectAtIndex:0]] scanInt:&lineToGoTo]) {
            shouldJumpToLine = YES;
            if ([gotoLineComponents count] > 1) {
                NSScanner *scanner = [NSScanner scannerWithString:[gotoLineComponents objectAtIndex:1]];
                if (![scanner scanInt:&columnToGoTo]) {
                    columnToGoTo=-1;
                } else {
                    if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","] intoString:nil]) {
                        if (![scanner scanInt:&selectionLength]) {
                            selectionLength=0;
                        }
                    } 
                }
            }
        }
    }
    BOOL previousOpenSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
    __block BOOL shouldSwitchOpening = NO;
    if (openIn) {
        if ([openIn isEqualToString:@"tabs"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
        } else if ([openIn isEqualToString:@"windows"]) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
        } else { // new-window
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
            shouldSwitchOpening = YES;
        }
    }
    
    NSMutableArray *documents = [NSMutableArray array];
    
    NSMutableArray *files = [NSMutableArray array];
    id argument = [[command evaluatedArguments] objectForKey:@"Files"];
    if ([argument isKindOfClass:[NSArray class]]) {
        [files addObjectsFromArray:argument];
    } else if ([argument isKindOfClass:[NSString class]]) {
        [files addObject:argument];
    } else if ([argument isKindOfClass:[NSURL class]]) {
        [files addObject:[argument path]];
    }

    NSString *fileName;
    for (fileName in files) {
		// print handeld by workspace print command for now, don't open file if just printing
		if (! shouldPrint) {
			[I_propertiesForOpenedFiles setObject:properties forKey:fileName];
			[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:fileName] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
				if (document) {
					if (shouldSwitchOpening) {
						shouldSwitchOpening = NO;
						[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
					}
					[(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
					if (jobDescription) {
						[(PlainTextDocument *)document setJobDescription:jobDescription];
					}
					if (shouldPrint) {
						// handeld by workspace print command for now
//						BOOL shouldClose = ([self documentForURL:[NSURL fileURLWithPath:fileName]] == nil);
//
//						[document printDocumentWithSettings:nil showPrintPanel:NO delegate:nil didPrintSelector:NULL contextInfo:NULL];
//						if (shouldClose && !documentWasAlreadyOpen) {
//							[document close];
//						}
					} else {
						if (shouldJumpToLine) {
							if (columnToGoTo!=-1) {
								NSRange lineRange = [(FoldableTextStorage *)[(PlainTextDocument *)document textStorage] findLine:lineToGoTo];
								[(PlainTextDocument *)document selectRange:NSMakeRange(lineRange.location+columnToGoTo,selectionLength)];
							} else {
								[(PlainTextDocument *)document gotoLine:lineToGoTo];
							}
						}
						[documents addObject:document];
					}
				} else {
					NSLog(@"%@",error);
				}
			}];
		}
    }


    NSMutableArray *newFiles = [NSMutableArray array];
    argument = [[command evaluatedArguments] objectForKey:@"NewFiles"];
    if ([argument isKindOfClass:[NSArray class]]) {
        [newFiles addObjectsFromArray:argument];
    } else if ([argument isKindOfClass:[NSString class]]) {
        [newFiles addObject:argument];
    } else if ([argument isKindOfClass:[NSURL class]]) {
        [newFiles addObject:[argument path]];
    }
    
    NSString *documentModeIdentifierArgument = [properties objectForKey:@"mode"];
    for (fileName in newFiles) {
        NSDocument *document = [self openUntitledDocumentAndDisplay:YES error:nil];
        if (document) {
            if (shouldSwitchOpening) {
                shouldSwitchOpening = NO;
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
            }
            [(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
            if (!documentModeIdentifierArgument) {
				DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:fileName withContentString:nil];
                [properties setObject:[mode documentModeIdentifier] forKey:@"mode"];
            }
            if ([properties objectForKey:@"encoding"] == nil && documentModeIdentifierArgument != nil) {
                DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForName:documentModeIdentifierArgument];
                if (mode) {
                    NSUInteger encodingNumber = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
                    if (encodingNumber < SmallestCustomStringEncoding) {
                        NSString *IANAName = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encodingNumber));
                        if (IANAName != nil) {
                            [properties setObject:IANAName forKey:@"encoding"];
                        }
                    }
                } else {
                    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"mode name argument invalid: %@", documentModeIdentifierArgument);
                }
            }            
            [document setScriptingProperties:properties];
            [(PlainTextDocument *)document resizeAccordingToDocumentMode];
            [(PlainTextDocument *)document setShouldSelectModeOnSave:NO];
            [(PlainTextDocument *)document setShouldChangeExtensionOnModeChange:NO];
            [(PlainTextDocument *)document setTemporaryDisplayName:[fileName lastPathComponent]];
            [(PlainTextDocument *)document setDirectoryForSavePanel:[fileName stringByDeletingLastPathComponent]];
            if (jobDescription) {
                [(PlainTextDocument *)document setJobDescription:jobDescription];
            }
            if (shouldPrint) {
//                [document printShowingPrintPanel:NO];
                [document close];
            } else {
                [documents addObject:document];
            }
        }
    }
        
    
    NSString *standardInputFile = nil;
    argument = [[command evaluatedArguments] objectForKey:@"Stdin"];
    if ([argument isKindOfClass:[NSString class]]) {
        standardInputFile = argument;
    } else if ([argument isKindOfClass:[NSURL class]]) {
        standardInputFile = [argument path];
    }
    
    if (standardInputFile) {
        NSString *pipeTitle = [[command evaluatedArguments] objectForKey:@"PipeTitle"];
    
        NSDocument *document = [self openUntitledDocumentAndDisplay:YES error:nil];
        if (document) {
            if (shouldSwitchOpening) {
//                shouldSwitchOpening = NO;
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
            }
            [(PlainTextDocument *)document setIsWaiting:(shouldWait || isPipingOut)];
            if (isPipingOut) {
                [(PlainTextDocument *)document setShouldChangeChangeCount:NO];
            }
            if (pipeTitle) {
                [(PlainTextDocument *)document setTemporaryDisplayName:pipeTitle];
            } 
            
            [document setScriptingProperties:properties];
            [I_propertiesForOpenedFiles setObject:properties forKey:standardInputFile];
            [(PlainTextDocument *)document resizeAccordingToDocumentMode];
            [document readFromURL:[NSURL fileURLWithPath:standardInputFile] ofType:@"public.plain-text" error:NULL];

			[(PlainTextDocument *)document autosaveForStateRestore];

            if (shouldMakePipeDirty) {
                [document updateChangeCount:NSChangeDone];
            }
            if (!pipeTitle) {
                [(PlainTextDocument *)document setShouldChangeExtensionOnModeChange:YES];
            }

            if (![properties objectForKey:@"mode"]) {
				DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:pipeTitle withContentString:[[(PlainTextDocument *)document textStorage] string]];
                [(PlainTextDocument *)document setDocumentMode:mode];
                [(PlainTextDocument *)document resizeAccordingToDocumentMode];
                [(PlainTextDocument *)document setShouldSelectModeOnSave:[mode isBaseMode]];
            }
            
            if (jobDescription) {
                [(PlainTextDocument *)document setJobDescription:jobDescription];
            }
            
            if (shouldPrint) {
//                [document printShowingPrintPanel:NO];
                [document close];
            } else {
                if (shouldJumpToLine) {
                    if (columnToGoTo!=-1) {
                        NSRange lineRange = [(FoldableTextStorage *)[(PlainTextDocument *)document textStorage] findLine:lineToGoTo];
                        [(PlainTextDocument *)document selectRange:NSMakeRange(lineRange.location+columnToGoTo,selectionLength)];
                    } else {
                        [(PlainTextDocument *)document gotoLine:lineToGoTo];
                    }
                }
                [documents addObject:document];
            }
        }
    }
    
    NSString *identifier = [NSString UUIDString];

    if (isPipingOut) {
        [I_pipingSeeScriptCommands addObject:identifier];
    }
    
    if (shouldWait) {
        int count = [documents count];
        if (count > 0) {
            [command suspendExecution];
            [I_suspendedSeeScriptCommands setObject:command forKey:identifier];
            [I_waitingDocuments setObject:documents forKey:identifier];
            [I_refCountsOfSeeScriptCommands setObject:[NSNumber numberWithInt:count] forKey:identifier];
        }
    }
    if (openIn) {
        [[NSUserDefaults standardUserDefaults] setBool:previousOpenSetting forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
    }    
    return nil;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma pack(push, 2)
struct ModificationInfo
{
    FSSpec theFile; // identifies the file
    long theDate; // the date/time the file was last modified
    short saved; // set this to zero when replying
};
#pragma pack(pop)

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"handleAppleEvent: %@, withReplyEvent: %@", [event description], [replyEvent description]);
    OSErr err;
    
    if ([event eventClass] == kKAHL && [event eventID] == kMOD) {
        NSAppleEventDescriptor *listDesc = [NSAppleEventDescriptor listDescriptor];
        NSArray *documents = [self documents];
        NSDocument *document;
        for (document in documents) {
            if ([document isDocumentEdited]) {
				NSURL *fileURL = [document fileURL];
                if (fileURL != nil) {
                    FSRef fileRef;
                    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
                    FSSpec fsSpec;
                    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
                    if (err == noErr) {
                        struct ModificationInfo modificationInfo;
                        modificationInfo.theFile = fsSpec;
                        modificationInfo.theDate = 0;
                        modificationInfo.saved = 0;
                        NSAppleEventDescriptor *modificationInfoDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeChar bytes:&modificationInfo length:sizeof(struct ModificationInfo)];
                        [listDesc insertDescriptor:modificationInfoDesc atIndex:0];
                    }
                }
            }
        }
        [replyEvent setDescriptor:listDesc forKeyword:keyDirectObject];
    }
}
#pragma clang diagnostic pop


#pragma mark - Closing documents

- (IBAction)closeAllDocuments:(id)sender {
    [self closeAllDocumentsWithDelegate:nil didCloseAllSelector:NULL contextInfo:NULL];
}

- (void)closeDocumentsStartingWith:(PlainTextDocument *)doc shouldClose:(BOOL)shouldClose closeAllContext:(void *)closeAllContext
{
    // Iterate over unsaved documents, preserve closeAllContext to invoke it after the last document
    __autoreleasing NSArray *windows = [[NSApp orderedWindows] copy];
    for (NSWindow *window in windows) {
        NSWindowController *controller = [window windowController];
        if ([controller isKindOfClass:[PlainTextWindowController class]]) {
            NSArray *documents = [(PlainTextWindowController *)controller documents];
            unsigned count = [documents count];
            while (count--) {
                PlainTextDocument *document = [documents objectAtIndex:count];
                if ([document isDocumentEdited]) {
                    PlainTextWindowController *controller = [document topmostWindowController];
                    (void)[controller selectTabForDocument:document];
                    [document canCloseDocumentWithDelegate:self
                                       shouldCloseSelector:@selector(reviewedDocument:shouldClose:contextInfo:)
                                               contextInfo:closeAllContext];
                    return;
                }
                
                [document close];
            }
        }
    }

    // Invoke invocation after reviewing all documents
    if (closeAllContext) {
        NSInvocation *invocation = (__bridge_transfer NSInvocation *)closeAllContext;
        [invocation invoke];
    }
}

- (void)reviewedDocument:(PlainTextDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo
{
    PlainTextWindowController *windowController = [doc topmostWindowController];
    NSWindow *sheet = [[windowController window] attachedSheet];
    if (sheet) [sheet orderOut:self];
    
    if (shouldClose) {
        NSArray *windowControllers = [doc windowControllers];
        NSUInteger windowControllerCount = [windowControllers count];
        if (windowControllerCount > 1) {
            [windowController documentWillClose:doc];
            [windowController close];
        } else {
            [doc close];
        }
        [self closeDocumentsStartingWith:nil shouldClose:shouldClose closeAllContext:contextInfo];
    }  else {
        [NSApp replyToApplicationShouldTerminate:NO];
    }
}

- (void)closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo
{
    NSInvocation *invocation = nil;

    if (delegate != nil && didCloseAllSelector != NULL) {
        NSMethodSignature *methodSignature = [delegate methodSignatureForSelector:didCloseAllSelector];
        unsigned numberOfArguments = [methodSignature numberOfArguments];

		__unsafe_unretained id unsaveSelf = self;
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setSelector:didCloseAllSelector];
        [invocation setTarget:delegate];
        if (numberOfArguments > 2) [invocation setArgument:&unsaveSelf atIndex:2];
        if (numberOfArguments > 3) { BOOL flag = YES; [invocation setArgument:&flag atIndex:3]; }
        if (numberOfArguments > 4) [invocation setArgument:&contextInfo atIndex:4];
    }
    [self closeDocumentsStartingWith:nil shouldClose:YES closeAllContext:(__bridge_retained void *)invocation];
}

- (void)removeDocument:(NSDocument *)document {
    int i;
    NSArray *keys = [I_waitingDocuments allKeys];
    int count = [keys count];
    for (i = count - 1; i >=0; i--) {
        NSString *key = [keys objectAtIndex:i];
        NSMutableArray *documents = [I_waitingDocuments objectForKey:key];
        if ([documents containsObject:document]) {
            BOOL isPiping = [I_pipingSeeScriptCommands containsObject:key];
            int refCount = [[I_refCountsOfSeeScriptCommands objectForKey:key] intValue];
            refCount--;
            if (refCount < 1) {
                NSMutableArray *fileNames = [NSMutableArray array];
                NSEnumerator *enumerator = [documents objectEnumerator];
                NSDocument *doc;
                while ((doc = [enumerator nextObject])) {
                    if (isPiping) {
                        NSString *fileName = tempFileName();
                        NSError *error = nil;
                        BOOL result = [doc writeToURL:[NSURL fileURLWithPath:fileName] ofType:@"public.plain-text" error:&error];
                        if (result) {
                            [fileNames addObject:fileName];
                        } else {
                            NSLog(@"%s %@",__FUNCTION__,error);
                        }
                    }
                }
                NSScriptCommand *command = [I_suspendedSeeScriptCommands objectForKey:key];
                [command resumeExecutionWithResult:fileNames];
                [I_suspendedSeeScriptCommands removeObjectForKey:key];
                [I_waitingDocuments removeObjectForKey:key];
                [I_refCountsOfSeeScriptCommands removeObjectForKey:key];
                [I_pipingSeeScriptCommands removeObject:key];
            } else {
                [I_refCountsOfSeeScriptCommands setObject:[NSNumber numberWithInt:refCount] forKey:key];
            }
        }
    }

    [super removeDocument:document];
    if ([[self documents] count]==0) {
        NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:ModeMenuTag] submenu];
        // remove all items that don't belong here anymore
        int index = [modeMenu indexOfItemWithTag:ReloadModesMenuItemTag];
        index+=1;
        while (index < [modeMenu numberOfItems]) {
            [modeMenu removeItemAtIndex:index];
        }
    }
}


#pragma mark -

- (void)openModeFile:(NSString *)fileName
{
	return; // remove this again to install modes

    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening mode file: %@", fileName);
    NSBundle *modeBundle = [NSBundle bundleWithPath:fileName];
    NSString *versionString = [modeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", [fileName lastPathComponent], versionString];
    [O_modeInstallerMessageTextField setObjectValue:[NSString stringWithFormat:NSLocalizedString(@"Do you want to install the mode \"%@\"?", nil), name]];
    [O_modeInstallerDomainMatrix selectCellAtRow:0 column:0];

    NSString *modeIdentifier = [modeBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
    if (mode) {
        NSBundle *installedModeBundle = [mode bundle];
        NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *installedModeFileName = [installedModeBundle bundlePath];

        NSString *userDomainPath = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil] URLByStandardizingPath] path];
        NSString *localDomainPath = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSLocalDomainMask appropriateForURL:nil create:NO error:nil] URLByStandardizingPath] path];
        NSString *networkDomainPath = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSNetworkDomainMask appropriateForURL:nil create:NO error:nil] URLByStandardizingPath] path];

		NSSearchPathDomainMask domain = 0;
        BOOL isKnownDomain = YES;
        if (userDomainPath != nil && [installedModeFileName hasPrefix:userDomainPath]) {
            domain = NSUserDomainMask;
        } else if (localDomainPath != nil && [installedModeFileName hasPrefix:localDomainPath]) {
            domain = NSLocalDomainMask;
        } else if (networkDomainPath != nil && [installedModeFileName hasPrefix:networkDomainPath]) {
            domain = NSNetworkDomainMask;
        } else {
            isKnownDomain = NO;
        }

        NSString *installedModeName = [NSString stringWithFormat:@"%@ (%@)", [installedModeFileName lastPathComponent], versionStringOfInstalledMode];
        NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"Mode \"%@\" is already installed in \"%@\".", nil), installedModeName, installedModeFileName];

        if (!isKnownDomain || domain == NSNetworkDomainMask || domain == NSLocalDomainMask) {
            informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will override the installed mode.", nil)];
        } else if (domain == NSUserDomainMask) {
            informativeText = [informativeText stringByAppendingFormat:@" %@", NSLocalizedString(@"You will replace the installed mode.", nil)];
        }

        [O_modeInstallerInformativeTextField setObjectValue:informativeText];
    } else {
        [O_modeInstallerInformativeTextField setObjectValue:@""];
    }

    I_currentModeFileName = fileName;
    int result = [NSApp runModalForWindow:O_modeInstallerPanel];
    [O_modeInstallerPanel orderOut:self];
    I_currentModeFileName = nil;
    if (result == NSRunStoppedResponse) {
        BOOL success = NO;

        NSSearchPathDomainMask domain = 0;
        int tag = [[O_modeInstallerDomainMatrix selectedCell] tag];
        if (tag == 0) {
            domain = NSUserDomainMask;
        } else if (tag == 1) {
            domain = NSLocalDomainMask;
        }

		NSURL *appSupportURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:domain appropriateForURL:nil create:NO error:nil];
		NSURL *destinationURL = [appSupportURL URLByAppendingPathComponent:@"SubEthaEdit"];
		destinationURL = [destinationURL URLByAppendingPathComponent:@"Modes"];
		destinationURL = [destinationURL URLByAppendingPathComponent:[fileName lastPathComponent]];
		NSString *destination  = [destinationURL path];

		if (![fileName isEqualToString:destination]) {
			if (domain == NSUserDomainMask) {
				// TODO: check errors here and present alert which is currently in fileManager:shouldProceedAfterError:
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ([fileManager fileExistsAtPath:destination]) {
					(void)[fileManager removeItemAtPath:destination error:nil];
				}
				success = [fileManager copyItemAtPath:fileName toPath:destination error:nil];
			} else {

				success = NO;

//				OSStatus err;
//				CFURLRef tool = NULL;
//				AuthorizationRef auth = NULL;
//				NSDictionary *request = nil;
//				CFDictionaryRef response = nil;
//
//				err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
//				if (err == noErr) {
//					static const char *kRightName = "de.codingmonkeys.SubEthaEdit.HelperTool";
//					static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults
//					| kAuthorizationFlagInteractionAllowed
//					| kAuthorizationFlagExtendRights
//					| kAuthorizationFlagPreAuthorize;
//					AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
//					AuthorizationRights rights = { 1, &right };
//
//					err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
//				}
//
//				if (err == noErr) {
//					err = MoreSecCopyHelperToolURLAndCheckBundled(
//																  CFBundleGetMainBundle(),
//																  CFSTR("SubEthaEditHelperToolTemplate"),
//																  kApplicationSupportFolderType,
//																  CFSTR("SubEthaEdit"),
//																  CFSTR("SubEthaEditHelperTool"),
//																  &tool);
//
//					// If the home directory is on an volume that doesn't support
//					// setuid root helper tools, ask the user whether they want to use
//					// a temporary tool.
//
//					if (err == kMoreSecFolderInappropriateErr) {
//						err = MoreSecCopyHelperToolURLAndCheckBundled(
//																	  CFBundleGetMainBundle(),
//																	  CFSTR("SubEthaEditHelperToolTemplate"),
//																	  kTemporaryFolderType,
//																	  CFSTR("SubEthaEdit"),
//																	  CFSTR("SubEthaEditHelperTool"),
//																	  &tool);
//					}
//				}
//
//				// Create the request dictionary for copying the mode
//
//				if (err == noErr) {
//
//                    NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH)];
//                    NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
//												 filePermissions, NSFilePosixPermissions,
//												 @"root", NSFileOwnerAccountName,
//												 @"admin", NSFileGroupOwnerAccountName,
//												 nil];
//
//					request = [NSDictionary dictionaryWithObjectsAndKeys:
//							   @"CopyFiles", @"CommandName",
//							   fileName, @"SourceFile",
//							   destination, @"TargetFile",
//							   targetAttrs, @"TargetAttributes",
//							   nil];
//				}
//
//				// Go go gadget helper tool!
//
//				if (err == noErr) {
//					err = MoreSecExecuteRequestInHelperTool(tool, auth, (__bridge CFDictionaryRef)request, &response);
//				}
//
//				// Extract information from the response.
//
//				if (err == noErr) {
//					//NSLog(@"response: %@", response);
//
//					err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
//					if (err == noErr) {
//						success = YES;
//					}
//				}
//
//				// Clean up after second call of helper tool.
//				if (response) {
//					CFRelease(response);
//				}
//
//
//				if (tool) CFRelease(tool);
//				if (auth != NULL) {
//					(void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
//				}
			}
		} else {
			success = YES;
		}

        [[DocumentModeManager sharedInstance] reloadDocumentModes:self];

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        if (success) {
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The mode \"%@\" has been installed successfully.", nil), name]];
        } else {
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Installation of mode \"%@\" failed.", nil), name]];
        }
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
    }
}

- (void)openDirectory:(NSString *)fileName
{
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening directory: %@", fileName);
}

static NSString *tempFileName() {
    static int sequenceNumber = 0;
    NSString *origPath = [[NSApp sandboxContainerURL].path stringByAppendingPathComponent:@"see"];
    NSString *name;
    do {
        sequenceNumber++;
        name = [NSString stringWithFormat:@"SEE-%d-%d-%d", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber];
        name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);
    return name;
}


#pragma mark - NSServicesHandling

// note the "setServicesProvider:" in the applicationWillFinishLaunching method

- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    PlainTextDocument *document = (PlainTextDocument *)[self openUntitledDocumentAndDisplay:YES error:nil];
    [[[[document plainTextEditors] objectAtIndex:0] textView] readSelectionFromPasteboard:pboard];
    // Workaround for when only RTF is on the drag pasteboard (e.g. when dragging text from safari on the SubEthaEditApplicationIcon)
    NSTextStorage *ts = [document textStorage];
    [ts removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0,[ts length])];
    [ts removeAttribute:NSLinkAttributeName range:NSMakeRange(0,[ts length])];
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:@"" withContentString:[ts string]];
    [(PlainTextDocument *)document setDocumentMode:mode];
    [document clearChangeMarks:self];
}

@end
