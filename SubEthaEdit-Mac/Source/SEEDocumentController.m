//  SEEDocumentController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//	ARCified by Michael Ehrmann on Thu Mar 27 2014

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
#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"
#import "SEEOpenPanelAccessoryViewController.h"
#import "SEEDocumentListWindowController.h"
#import "NSApplicationTCMAdditions.h"
#import "SEEScopedBookmarkManager.h"

#import <objc/objc-runtime.h>			// for objc_msgSend

NSString *const RecentDocumentsDidChangeNotification = @"RecentDocumentsDidChangeNotification";

NSString * const kSEETypeSEEText = @"de.codingmonkeys.subethaedit.seetext";
NSString * const kSEETypeSEEMode = @"de.codingmonkeys.subethaedit.seemode";


@interface SEEDocumentController ()

@property (nonatomic, strong) SEEDocumentListWindowController *documentListWindowController;

@property (nonatomic) BOOL isOpeningInTab;
@property (nonatomic) NSUInteger filesToOpenCount;
@property (nonatomic) BOOL isOpeningUsingAlternateMenuItem;
@property (nonatomic, strong) NSMutableDictionary *documentCreationFlagsLookupDict;
@property (nonatomic, strong) NSMutableArray *filenamesFromLastRunOpenPanel;

@property (nonatomic, copy) NSURL *locationForNextOpenPanel;
@property (nonatomic, readwrite, nonatomic) NSStringEncoding encodingFromLastRunOpenPanel;
@property (nonatomic, readwrite, copy) NSString *modeIdentifierFromLastRunOpenPanel;

@end


@implementation SEEDocumentController

+ (SEEDocumentController *)sharedInstance {
    return (SEEDocumentController *)[NSDocumentController sharedDocumentController];
}

+ (NSArray *)allTagsOfTagClass:(CFStringRef)aTagClass forUTI:(NSString *)aType {
	NSArray *result = nil;
	/*
	2014-06-24 11:58:53.184 SubEthaEdit[64737:303] -[DocumentModeManager reloadPrecedences] public.php-script
	{
		UTTypeConformsTo = "public.shell-script";
		UTTypeDescription = "PHP script";
		UTTypeIdentifier = "public.php-script";
		UTTypeTagSpecification =     {
			"public.filename-extension" =         (
												   php,
												   php3,
												   php4,
												   ph3,
												   ph4,
												   phtml
												   );
			"public.mime-type" =         (
										  "text/php",
										  "text/x-php-script",
										  "application/php"
										  );
		};
	}
	 */
	// TODO: use 10_10 api if available
	NSDictionary *description = CFBridgingRelease(UTTypeCopyDeclaration((__bridge CFStringRef)aType));
	if (description) {
		NSDictionary *tagSpecification = description[@"UTTypeTagSpecification"];
		NSString *tagKey = (__bridge NSString *)aTagClass; // this is not really guaranteed by the public documentation, but makes sense, works in 10_9 and in 10_10 there is a public api for this anyways - so I forgo to make a if equals loop around the known tag classes
		NSArray *allTags = tagSpecification[tagKey];
		if (allTags && [allTags isKindOfClass:[NSArray class]]) {
			result = allTags;
		}
	}
		
	if (!result) {
		result = @[];
	}
	return result;
}

- (instancetype)init {
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

- (NSWindow *)documentListWindow {
	NSWindow *result = nil;
	if (self.documentListWindowController.isWindowLoaded) {
		result = self.documentListWindowController.window;
	}
	return result;
}

- (void)updateRestorableStateOfDocumentListWindow {
	if (I_windowControllers.count == 0) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		BOOL shouldOpenUntitledFile = [defaults boolForKey:OpenUntitledDocumentOnStartupPreferenceKey];
		BOOL shouldOpenDocumentHub = [defaults boolForKey:OpenDocumentHubOnStartupPreferenceKey];
		
		// update restorable state of document hud on last document window close.
		NSWindow *documentListWindow = self.documentListWindow;
		if (shouldOpenDocumentHub || shouldOpenUntitledFile) {
			documentListWindow.restorable = NO;
		} else {
			documentListWindow.restorable = YES;
		}
	}
}

- (SEEDocumentListWindowController *)ensuredDocumentListWindowController {
	if (!self.documentListWindowController) {
		SEEDocumentListWindowController *networkBrowser = [[SEEDocumentListWindowController alloc] initWithWindowNibName:@"SEEDocumentListWindowController"];
		self.documentListWindowController = networkBrowser;
	}
	return self.documentListWindowController;
}

- (IBAction)showDocumentListWindow:(id)sender {
	SEEDocumentListWindowController *controller = [self ensuredDocumentListWindowController];
	if (sender == NSApp) {
		controller.shouldCloseWhenOpeningDocument = YES;
		[controller showWindow:sender];
	} else if ([sender isKindOfClass:[AppController class]]) {
		controller.shouldCloseWhenOpeningDocument = NO;
		[controller showWindow:sender];
		controller.window.restorable = NO;
	} else {
		controller.shouldCloseWhenOpeningDocument = NO;
		[controller showWindow:sender];
	}
}

- (IBAction)copyReachabilityURL:(id)aSender {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[[self ensuredDocumentListWindowController] writeMyReachabiltyToPasteboard:pboard];
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
	if ([typeName isEqualToString:kSEETypeSEEText] && [documentClass class] != [PlainTextDocument class]) {
		documentClass = [PlainTextDocument class];
	} else if ([typeName isEqualToString:kSEETypeSEEMode] && [documentClass class] != [PlainTextDocument class]) {
		documentClass = [PlainTextDocument class];
	}

	return  documentClass;
}


#pragma mark - Tab menu

- (void)updateMenuWithTabMenuItems:(NSMenu *)aMenu {
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
                                   action:@selector(makeKeyAndOrderFront:)
                            keyEquivalent:@""];
        
        BOOL firstWindowController = YES;
        
        for(NSArray <NSWindowController*> *tabGroup  in [self tabGroups]) {
            if (!firstWindowController) {
                [aMenu addItem:[NSMenuItem separatorItem]];
            }
            firstWindowController = NO;
            
            for (PlainTextWindowController *windowController in tabGroup) {
                
                BOOL hasSheet = [[windowController window] attachedSheet] ? YES : NO;
                PlainTextDocument * document = windowController.document;
                
                [prototypeMenuItem setTarget:windowController.window];
                [prototypeMenuItem setTitle:[windowController windowTitleForDocumentDisplayName:[document displayName] document:document]];
                [prototypeMenuItem setRepresentedObject:document];
                [prototypeMenuItem setEnabled:!hasSheet];
                
                NSMenuItem *itemToAdd = [prototypeMenuItem copy];
                [aMenu addItem:itemToAdd];
                [itemToAdd setMark:[document isDocumentEdited]];
                
            }
        }
        [menusCurrentlyUpdating removeObject:aMenu];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];

    if (selector == @selector(concealAllDocuments:)) {
        return [[[TCMMMPresenceManager sharedInstance] announcedSessions] count]>0;
    } else if (selector == @selector(openAlternateDocument:)) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab]) {
            [menuItem setTitle:NSLocalizedString(@"Open in New Window...", @"Menu Entry for opening files in a new window.")];
        } else {
            [menuItem setTitle:NSLocalizedString(@"Open in Front Window...", @"Menu Entry for opening files in the front window.")];
        }
        return YES;
    } else if (selector == @selector(copyReachabilityURL:)) {
		return (![[TCMMMBEEPSessionManager sharedInstance] isNetworkingDisabled]);
	}
    return [super validateMenuItem:menuItem];
}


- (IBAction)menuValidationNoneAction:(id)aSender {

}



- (NSMenu *)documentMenu {
    NSMenu *documentMenu = [NSMenu new];
    [self updateMenuWithTabMenuItems:documentMenu];
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
  
    PlainTextWindowController *activeWindowController = nil;
  
    while (--count >= 0) {
        PlainTextWindowController *controller = [I_windowControllers objectAtIndex:count];
        if (![[controller window] attachedSheet]) {
            activeWindowController = controller;
            if ([[controller window] isMainWindow]) break;
        }
    }
  
    return activeWindowController;
}

- (void)addWindowController:(id)aWindowController {
    [I_windowControllers addObject:aWindowController];
}

- (void)removeWindowController:(id)aWindowController {
	__autoreleasing id autoreleasedWindowController = aWindowController;
    [I_windowControllers removeObject:autoreleasedWindowController];
	
	[self updateRestorableStateOfDocumentListWindow];
}

+ (BOOL)shouldAlwaysShowTabBar {
    BOOL alwaysShowTabBar = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar];
    return alwaysShowTabBar;
}

+ (void)setShouldAlwaysShowTabBar:(BOOL)flag {
    BOOL currentValue = self.shouldAlwaysShowTabBar;
    if ((currentValue && !flag) ||
        (!currentValue && flag)) {
        [[NSUserDefaults standardUserDefaults] setBool:flag forKey:kSEEDefaultsKeyAlwaysShowTabBar];
        [[self sharedInstance] ensureShouldAlwaysShowTabBar:flag];
    }
}

- (void)ensureShouldAlwaysShowTabBar:(BOOL)shouldBeVisible {
    // Collect NSTabGroups
    NSMutableSet *tabGroups = [NSMutableSet new];
    for (NSWindowController *wc in I_windowControllers) {
        if ([wc isKindOfClass:[PlainTextWindowController class]]) {
            [tabGroups addObject:wc.window.tabGroup];
        }
    }
    
    for (NSWindowTabGroup *group in tabGroups) {
        if (group.windows.count == 1) {
            id window = group.windows.firstObject;
            if ([window isKindOfClass:[PlainTextWindow class]]) {
                [window ensureTabBarVisiblity:shouldBeVisible];
            }
        }
    }
}

- (NSArray <NSArray <NSWindowController *> *> *)tabGroups {
    NSMutableArray *tabGroups = [NSMutableArray new];
    NSMutableArray *windowTabGroups = [NSMutableArray new];
    
    for (NSWindowController *wc in I_windowControllers) {
        NSWindow *window = wc.window;
        NSArray *tabbedWindows = window.tabbedWindows;
        
        if (tabbedWindows && ![windowTabGroups containsObject:tabbedWindows]) {
            [windowTabGroups addObject:tabbedWindows];
            NSMutableArray * tabGroup = [NSMutableArray new];
            for (NSWindow *window in tabbedWindows) {
                NSWindowController *wc = window.windowController;
                if (wc) {
                    [tabGroup addObject:wc];
                }
            }
            [tabGroups addObject:tabGroup];
        } else if (!tabbedWindows && window) {
            // If tabbedWindows is nil the window has no visible tab bar.
            [tabGroups addObject:@[wc]];
        }
    }
    
    return tabGroups;
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

			[document autosaveForStateRestore];
        }
    }
}


- (IBAction)newDocument:(id)aSender {
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

// Responder Method to be called when user clicks on the plus button
- (IBAction)newWindowForTab:(id)sender {
    // Sender always seems to be a window, but lets be safe here
    if ([sender isKindOfClass:[NSWindow class]]) {
        // Need to do this so cmd-clicks on background windows open the new document in that window too
        @synchronized(self.documentCreationFlagsLookupDict) {
            SEEDocumentCreationFlags *creationFlags = [[SEEDocumentCreationFlags alloc] init];
            creationFlags.openInTab = YES;
            creationFlags.tabWindow = sender;
            creationFlags.isAlternateAction = ([NSApp currentEvent].modifierFlags | NSEventModifierFlagOption);
            self.documentCreationFlagsLookupDict[@"MakeUntitledDocument"] = creationFlags;
        }
        
        [self newDocumentWithModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]];

    } else {
        [self newDocumentInTab:sender];
    }
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
	NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
	if ([eventDesc eventClass] == 'Hdra' && [eventDesc eventID] == 'See ') {
		self.isOpeningUntitledDocument = NO;
	} else {
		self.isOpeningUntitledDocument = YES;
	}
	id result = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
	self.isOpeningUntitledDocument = NO;
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

	[super beginOpenPanel:openPanel forTypes:inTypes completionHandler:^(NSModalResponse result) {
		[self setModeIdentifierFromLastRunOpenPanel:[openPanelAccessoryViewController.modePopUpButtonOutlet selectedModeIdentifier]];
		[self setEncodingFromLastRunOpenPanel:[[openPanelAccessoryViewController.encodingPopUpButtonOutlet selectedItem] tag]];

		if (result == NSModalResponseOK) {
			NSString *modeExtension = MODE_EXTENSION;
			for (NSURL *URL in openPanel.URLs) {
				if ([URL isFileURL]) {
					NSString *fileName = [URL path];
					BOOL isDir = NO;
					BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fileName];
					NSString *extension = [fileName pathExtension];
					if (isFilePackage && [extension isEqualToString:modeExtension]) {
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
    if (isFilePackage && [extension isEqualToString:MODE_EXTENSION]) {
        [self openModeFile:filename];

		if (completionHandler) {
			completionHandler(nil, NO, nil);
		}
    } else if (!isFilePackage && isDirectory) {
		[self openDirectory:url];

		if (completionHandler) {
			completionHandler(nil, NO, nil);
		}
    } else {
        NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        NSDictionary *parsed = [PlainTextDocument parseOpenDocumentEvent:eventDesc];
		[super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error)
		 {
			 if (document && [document isKindOfClass:PlainTextDocument.class] && displayDocument) {
				 [(PlainTextDocument *)document handleParsedOpenDocumentEvent:parsed];
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
				PlainTextWindowControllerTabContext *tabContext = [windowController windowControllerTabContextForDocument:plainTextDocument];
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
										PlainTextWindowControllerTabContext *tabContext = [windowController windowControllerTabContextForDocument:plainTextDocument];
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
									PlainTextWindowControllerTabContext *tabContext = [windowController windowControllerTabContextForDocument:plainTextDocument];
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
											   postingStyle:NSPostWhenIdle
											   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
												   forModes:@[NSRunLoopCommonModes]];
}

- (IBAction)clearRecentDocuments:(id)sender {
	[super clearRecentDocuments:sender];

	NSNotification *recentDocumentsDidChangeNotification = [NSNotification notificationWithName:RecentDocumentsDidChangeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:recentDocumentsDidChangeNotification
											   postingStyle:NSPostWhenIdle
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

    NSString *modeExtension = MODE_EXTENSION;
    for (NSString *filename in files) {
		BOOL isSEEStdinTempFile = [[filename pathExtension] isEqualToString:@"seetmpstdin"];
		if (isSEEStdinTempFile) continue;
        BOOL isDir = NO;
        BOOL isFilePackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename];
        NSString *extension = [filename pathExtension];
        if (isFilePackage && [extension isEqualToString:modeExtension]) {
            [self openModeFile:filename];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir] && isDir && !isFilePackage) {
            [self openDirectory:[NSURL fileURLWithPath:filename]];
        } else {
            [I_propertiesForOpenedFiles setObject:properties forKey:filename];
			if (!isFilePackage) {
				[[SEEScopedBookmarkManager sharedManager] startAccessingScriptedFileURL:[NSURL fileURLWithPath:filename]];
			}
			[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
				if (error) {
					[self presentError:error];
				}
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
				[document printDocumentWithSettings:@{} showPrintPanel:NO delegate:nil didPrintSelector:NULL contextInfo:NULL];
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
    
	NSString *identifier = [NSString UUIDString];

	NSMutableArray *documents = [NSMutableArray array];

	// Existing Files
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

			if (shouldWait) {  // if shouldWait is true we need to make sure the command is suspended and resumed at correct times
				[command suspendExecution]; // call suspend for every document, resume and suspend do not need to be balanced.
				[I_suspendedSeeScriptCommands setObject:command forKey:identifier];
				I_refCountsOfSeeScriptCommands[identifier] = @([I_refCountsOfSeeScriptCommands[identifier] integerValue] + 1); // increment by one for this document
			}

			[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:fileName] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
				if (document) {
					if (shouldWait) {
						NSArray *waitingDocuments = self->I_waitingDocuments[identifier];
						if (waitingDocuments) {
							waitingDocuments = [waitingDocuments arrayByAddingObject:document];
						} else {
							waitingDocuments = @[document];
						}
						[self->I_waitingDocuments setObject:waitingDocuments forKey:identifier];
					}

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
					}
				} else {
					if (shouldWait) { // if opening the document failed
						self->I_refCountsOfSeeScriptCommands[identifier] = @([self->I_refCountsOfSeeScriptCommands[identifier] integerValue] - 1); // decrement refCount for this document

						if ([self->I_refCountsOfSeeScriptCommands[identifier] integerValue] < 1) { // if this was the last document we need to cleanup and resume
							[self->I_suspendedSeeScriptCommands removeObjectForKey:identifier];
							[self->I_refCountsOfSeeScriptCommands removeObjectForKey:identifier];
							[command resumeExecutionWithResult:@[fileName]];
						}
					}
					NSLog(@"%@",error);
				}
			}];
		}
    }

	// New Files
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
        
// Standard In
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
            [document readFromURL:[NSURL fileURLWithPath:standardInputFile] ofType:(NSString *)kUTTypePlainText error:NULL];

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
    

    if (isPipingOut) {
        [I_pipingSeeScriptCommands addObject:identifier];
    }
    
    if (shouldWait) { // this is for new documents and pipes, existing documents are handled above
        NSUInteger count = [documents count];
        if (count > 0) {
            [command suspendExecution];
            [I_suspendedSeeScriptCommands setObject:command forKey:identifier]; // this may replace the command added by existing documents earlier, but is the same command anyway.
            [I_waitingDocuments setObject:[documents copy] forKey:identifier]; // this is save because, the completion handlers of existing documents get executed afterwards.
			I_refCountsOfSeeScriptCommands[identifier] = @(count);
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

- (void)closeDocumentsStartingWith:(PlainTextDocument *)doc shouldClose:(BOOL)shouldClose closeAllContext:(void *)closeAllContext {
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

- (void)reviewedDocument:(PlainTextDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
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

- (void)closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo {
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
                        BOOL result = [doc writeToURL:[NSURL fileURLWithPath:fileName] ofType:(NSString *)kUTTypePlainText error:&error];
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

- (void)openModeFile:(NSString *)fileName {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening mode file: %@", fileName);
    NSBundle *modeBundle = [NSBundle bundleWithPath:fileName];
    NSString *versionString = [modeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", [fileName lastPathComponent], versionString];
	
	NSString *titleText = [NSString stringWithFormat:
						   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_TITLE_TEXT", nil, [NSBundle mainBundle],
															 @"Do you want to install the mode \"%@\"?", nil),
						   name];
	
	NSString *modeIdentifier = [modeBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	
	// check if that mode already exists - make info text
	NSString *informativeText = @"";
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
    if (mode) {
        NSBundle *installedModeBundle = [mode bundle];
        NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
		
        NSString *installedModeFileName = [installedModeBundle bundlePath];
        BOOL installedModeIsBuiltIn = [installedModeFileName hasPrefix:[[NSBundle mainBundle] bundlePath]];
		
        NSString *installedModeName = [NSString stringWithFormat:@"%@ (%@)", [installedModeFileName lastPathComponent], versionStringOfInstalledMode];
		
		informativeText = [NSString stringWithFormat:
						   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_INFO_STRING_BASE", nil, [NSBundle mainBundle],
															 @"Mode \"%@\" is already installed.", nil),
						   installedModeName];
		
		if (installedModeIsBuiltIn) {
			informativeText = [informativeText stringByAppendingFormat:@" %@",
							   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_INFO_STRING_OVERRIDE", nil, [NSBundle mainBundle],
																 @"You will override the installed mode.", nil)];
		} else {
			informativeText = [informativeText stringByAppendingFormat:@" %@",
							   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_INFO_STRING_REPLACE", nil, [NSBundle mainBundle],
																 @"You will replace the installed mode.", nil)];
		}
	}

	// show alert
    NSAlert *installAlert = [[NSAlert alloc] init];

    installAlert.messageText = titleText;
    installAlert.informativeText = informativeText;

    [installAlert addButtonWithTitle:NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_OK_BUTTON", nil, [NSBundle mainBundle], @"Install", nil)];
    [installAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [installAlert addButtonWithTitle:NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_SHOW_CONTENT_BUTTON", nil, [NSBundle mainBundle], @"Show Package Contents", nil)];

	NSModalResponse result = [installAlert runModal];

    if (result == NSAlertThirdButtonReturn) { // show package contents
		NSString *resourcePath = [modeBundle resourcePath];
		if (resourcePath) {
			[[NSWorkspace sharedWorkspace] selectFile:resourcePath inFileViewerRootedAtPath:[resourcePath stringByDeletingLastPathComponent]];
		}
	
	} else if (result == NSAlertFirstButtonReturn) { // ok was selected
        BOOL success = NO;

		NSURL *destinationURL = [[DocumentModeManager sharedInstance] urlForWritingModeWithName:[modeBundle objectForInfoDictionaryKey:@"CFBundleName"]];
		NSString *destinationPath = [destinationURL path];
		
		if (![fileName isEqualToString:destinationPath]) {
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSError *error = nil;
			BOOL modeExists = [fileManager fileExistsAtPath:destinationPath];
			if (modeExists) {
				NSURL *installURL = [destinationURL URLByAppendingPathExtension:@"install"];
				NSError *installUrlError = nil;
				BOOL moveSuccess = [fileManager copyItemAtPath:fileName toPath:[installURL path] error:&installUrlError];
				if (moveSuccess) {
					NSURL *urlInTrash = nil;
					NSError *deletionError = nil;
//					BOOL deletionSuccess = [fileManager trashItemAtURL:destinationURL resultingItemURL:&urlInTrash error:&deletionError];
					[fileManager trashItemAtURL:destinationURL resultingItemURL:&urlInTrash error:&deletionError];
					success = [fileManager moveItemAtURL:installURL toURL:destinationURL error:&error];
				}
			} else {
				success = [fileManager copyItemAtPath:fileName toPath:destinationPath error:&error];
			}
				
		} else {
			success = YES;
		}
		
        [[DocumentModeManager sharedInstance] reloadDocumentModes:self];
		
		NSString *messageText;
		if (success) {
			messageText = [NSString stringWithFormat:
						   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_ALERT_SUCCESS", nil, [NSBundle mainBundle],
															 @"The mode \"%@\" has been installed successfully.", nil),
						   name];
		} else {
			messageText = [NSString stringWithFormat:
						   NSLocalizedStringWithDefaultValue(@"MODE_INSTALL_ALERT_FAIL", nil, [NSBundle mainBundle],
															 @"Installation of mode \"%@\" failed.", nil),
						   name];
		}

        NSAlert *infoAlert = [[NSAlert alloc] init];

        infoAlert.messageText = messageText;

        [infoAlert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];

        [infoAlert setAlertStyle:NSAlertStyleInformational];
        [infoAlert runModal];
    }
}

- (void)openDirectory:(NSURL *)aURL {
	[self setLocationForNextOpenPanel:aURL];
	[self performSelector:@selector(openDocument:) withObject:nil afterDelay:0.0];

    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Opening directory: %@", aURL);
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
