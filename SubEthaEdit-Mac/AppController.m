//
//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <TCMPortMapper/TCMPortMapper.h>

#import "TCMFoundation.h"
#import "TCMBEEP.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "AppController.h"
#import "TCMPreferenceController.h"
#import "PlainTextDocument.h"
#import "UndoManager.h"
#import "GenericSASLProfile.h"

#import "SEEConnectionManager.h"
#import "SEEDocumentListWindowController.h"

#import "AdvancedPreferences.h"
#import "EditPreferences.h"
#import "GeneralPreferences.h"
#import "StylePreferences.h"
#import "PrecedencePreferences.h"
#import "SEECollaborationPreferenceModule.h"

#import "HandshakeProfile.h"
#import "SessionProfile.h"
#import "DocumentModeManager.h"
#import "SEEDocumentController.h"
#import "PlainTextEditor.h"
#import "TextOperation.h"
#import "SelectionOperation.h"
#import "UserChangeOperation.h"
#import "EncodingManager.h"
#import "SEETextView.h"

#import "URLDataProtocol.h"

#import "FontAttributesToStringValueTransformer.h"
#import "HueToColorValueTransformer.h"
#import "SaturationToColorValueTransformer.h"
#import "PointsToDisplayValueTransformer.h"
#import "ThousandSeparatorValueTransformer.h"
#import "NSMenuTCMAdditions.h"

#import "ScriptWrapper.h"
#import "SEEStyleSheetEditorWindowController.h"

#ifndef TCM_NO_DEBUG
#import "Debug/DebugPreferences.h"
#import "Debug/DebugController.h"
#endif

int const AppMenuTag = 200;
int const EnterSerialMenuItemTag = 201;
int const FileMenuTag = 100;
int const EditMenuTag = 1000;
int const FileNewMenuItemTag = 101;
int const FileNewAlternateMenuItemTag = 102;
int const FileOpenMenuItemTag = 111;
int const FileOpenAlternateMenuItemTag = 112;
int const CutMenuItemTag = 1;
int const CopyMenuItemTag = 2;
int const CopyXHTMLMenuItemTag = 5;
int const CopyStyledMenuItemTag = 6;
int const PasteMenuItemTag = 3;
int const BlockeditMenuItemTag = 4;
int const SpellingMenuItemTag = 10;
int const SpeechMenuItemTag = 11;
int const SubstitutionsMenuItemTag = 12;
int const TransformationsMenuItemTag = 13;
int const FormatMenuTag = 2000;
int const FontMenuItemTag = 1;
int const FileEncodingsMenuItemTag = 2001;
int const WindowMenuTag = 3000;
int const ViewMenuTag = 5000;
int const FoldingSubmenuTag = 4400;
int const FoldingFoldSelectionMenuTag = 4441;
int const FoldingFoldCurrentBlockMenuTag = 4442;
int const FoldingFoldAllCurrentBlockMenuTag = 4443;
int const GotoTabMenuItemTag = 3042;
int const ModeMenuTag = 50;
int const SwitchModeMenuTag = 10;
int const ReloadModesMenuItemTag = 20;
int const ScriptMenuTag = 4000;



NSString * const AddressHistory = @"AddressHistory";
NSString * const SetupDonePrefKey = @"SetupDone";
NSString * const SetupVersionPrefKey = @"SetupVersion";
NSString * const SerialNumberPrefKey = @"SerialNumberPrefKey";
NSString * const LicenseeNamePrefKey = @"LicenseeNamePrefKey";
NSString * const LicenseeOrganizationPrefKey = @"LicenseeOrganizationPrefKey";

NSString * const GlobalScriptsDidReloadNotification = @"GlobalScriptsDidReloadNotification";

NSString * const kSEEPasteBoardTypeConnection = @"SEEPasteBoardTypeConnection";

    
@interface AppController ()

- (void)setupFileEncodingsSubmenu;
- (void)setupScriptMenu;
- (void)setupDocumentModeSubmenu;
- (void)setupTextViewContextMenu;

@end

#pragma mark -

static AppController *sharedInstance = nil;

@implementation AppController

+ (void)initialize {
	if (self == [AppController class]) {
		[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
		[NSURLProtocol registerClass:[URLDataProtocol class]];
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:[NSNumber numberWithInt:SUBETHAEDIT_DEFAULT_PORT] forKey:DefaultPortNumber];
		[defaults setObject:[NSNumber numberWithInt:[[SEEDocumentController sharedDocumentController] maximumRecentDocumentCount]] forKey:@"NSRecentDocumentsLimit"];
		[defaults setObject:[NSMutableArray array] forKey:AddressHistory];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:ProhibitInboundInternetSessions];
		[defaults setObject:[NSNumber numberWithDouble:60.] forKey:NetworkTimeoutPreferenceKey];
		[defaults setObject:[NSNumber numberWithDouble:30.] forKey:@"AutoSavingDelay"]; // use same autosave delay as textedit
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:VisibilityPrefKey];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:AutoconnectPrefKey];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:@"GoIntoBundlesPrefKey"];
	#ifdef TCM_NO_DEBUG
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:@"EnableBEEPLogging"];
	#endif
		[defaults setObject:[NSNumber numberWithInt:800*1024] forKey:@"StringLengthToStopHighlightingAndWrapping"];
		[defaults setObject:[NSNumber numberWithInt:800*1024] forKey:@"StringLengthToStopSymbolRecognition"];
		[defaults setObject:[NSNumber numberWithInt:4096*1024] forKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
		
		//
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:VisibilityPrefKey];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadWindowPositionKey];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadTabSettingKey 	  ];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadWrapSettingKey   ];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadDocumentModeKey  ];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadSelectionKey 	  ];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentStateSaveAndLoadFoldingStateKey  ];
		
		[defaults setObject:[NSNumber numberWithBool:floor(NSAppKitVersionNumber) > 824.] forKey:@"SaveSeeTextPreview"];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:ShouldAutomaticallyMapPort];

		[defaults setObject:[NSNumber numberWithBool:NO] forKey:kSEEDefaultsKeyEnableTLS];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:kSEEDefaultsKeyUseTemporaryKeychainForTLS]; // no more temporary keychain in 10.6 and up builds
		
		defaults[MyEmailPreferenceKey] = @"";
		defaults[MyAIMPreferenceKey] = @"";

		NSDictionary *sequelProDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PreferenceDefaults" ofType:@"plist"]];
		
		[defaults addEntriesFromDictionary:sequelProDefaults];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		[[TCMMMTransformator sharedInstance] registerTransformationTarget:[TextOperation class] selector:@selector(transformTextOperation:serverTextOperation:) forOperationId:[TextOperation operationID] andOperationID:[TextOperation operationID]];
		[[TCMMMTransformator sharedInstance] registerTransformationTarget:[SelectionOperation class] selector:@selector(transformOperation:serverOperation:) forOperationId:[SelectionOperation operationID] andOperationID:[TextOperation operationID]];
		[UserChangeOperation class];
		[TCMMMNoOperation class];
        
	}
}

+ (AppController *)sharedInstance {
    return sharedInstance;
}
    
- (id)init
    {
        self = [super init];
        if (self) {
#if BETA
            [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"f6d8d69c0803df397e1a47872ffc2348" delegate:self];
#else
            [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"893da3588e5f78e26b48286f3b15e8d7" delegate:self];
#endif
        }
        return self;
    }

- (void)awakeFromNib {
    sharedInstance = self;
}

- (void)registerTransformers {
    FontAttributesToStringValueTransformer *fontTrans=[[FontAttributesToStringValueTransformer new] autorelease];
    [NSValueTransformer setValueTransformer:fontTrans
                                    forName:@"FontAttributesToString"];
    [NSValueTransformer setValueTransformer:[[HueToColorValueTransformer new] autorelease]
                                    forName:@"HueToColor"];
    [NSValueTransformer setValueTransformer:[[PointsToDisplayValueTransformer new] autorelease]
                                    forName:@"PointsToDisplay"];
    [NSValueTransformer setValueTransformer:[[ThousandSeparatorValueTransformer new] autorelease]
                                    forName:@"AddThousandSeparators"];
    SaturationToColorValueTransformer *satTrans=[[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor blackColor]] autorelease];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToBlackColor"];
    satTrans=[[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor whiteColor]] autorelease];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToWhiteColor"];
}

- (void)addMe {
	// add self as user
    TCMMMUser *me = [TCMMMUser new];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    NSString *myName = nil;
    NSString *myAIM = nil;
    NSString *myEmail = nil;
    
    NSString *userID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserID"];
	
    if (!userID) {
        // first run
        userID = [NSString UUIDString];
	
        CFStringRef appID = (CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        // Set up the preference.
        CFPreferencesSetValue(CFSTR("UserID"), (CFStringRef)userID, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        // Write out the preference data.
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    
	// set random color
    if (![defaults stringForKey:SelectedMyColorPreferenceKey]) {
		// TODO: check SelectedMyColorPreferenceKey for if still needed
        int colorHues[]={0,3300/360,6600/360,10900/360,18000/360,22800/360,26400/360,31700/360};
        sranddev();
        int selectedNumber=(int)((double)rand() / ((double)RAND_MAX + 1) * 8);
        [defaults setObject:[NSNumber numberWithInt:selectedNumber]
                     forKey:SelectedMyColorPreferenceKey];

        [defaults setObject:[NSNumber numberWithFloat:colorHues[selectedNumber]]
                     forKey:MyColorHuePreferenceKey];
    }
	
	// get basic user data
	// name
	myName  = [defaults stringForKey:MyNamePreferenceKey];
	if (!myName) {
		myName = NSFullUserName();
		[defaults setObject:myName forKey:MyNamePreferenceKey];
	}
	
	// email
	myEmail = [defaults stringForKey:MyEmailPreferenceKey];
	
	// aim
	myAIM = [defaults stringForKey:MyAIMPreferenceKey];
	
	// set basic user data
    
    [me setUserID:userID];
    [me setName:myName];
    [[me properties] setObject:myEmail forKey:@"Email"];
    [[me properties] setObject:myAIM forKey:@"AIM"];
    [me setUserHue:[defaults objectForKey:MyColorHuePreferenceKey]];

	// image - setting that last as it uses the initials - fails silently and sets the default image if error or no picture
	[me readImageFromUrl:[TCMMMUser applicationSupportURLForUserImage]];
		
    TCMMMUserManager *userManager = [TCMMMUserManager sharedInstance];
    [userManager setMe:[me autorelease]];
}

#define MODEMENUNAMETAG 20 

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {

    // test for compression...
//    int i=0;
//    for (i=1;i<400096;i=i*2) {
//        NSData *data = [[@"1234567890" stringByPaddingToLength:i withString:@"1234567890" startingAtIndex:0] dataUsingEncoding:NSMacOSRomanStringEncoding];
//        NSData *compressedData = [data compressedDataWithLevel:Z_DEFAULT_COMPRESSION];
//        if (!compressedData) NSLog(@"%d compression failed with data of length: %d",i,[data length]);
//    }

    // FIXME "Termination has to be removed before release!"
    //if ([[NSDate dateWithString:@"2007-02-21 12:00:00 +0000"] timeIntervalSinceNow] < 0) {
    //    [NSApp terminate:self];
    //    return;
    //}
    
    [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
    
    [[NSScriptCoercionHandler sharedCoercionHandler] registerCoercer:[DocumentMode class]
                                                            selector:@selector(coerceValue:toClass:)
                                                  toConvertFromClass:[DocumentMode class]
                                                             toClass:[NSString class]]; 

	
	[[NSScriptCoercionHandler sharedCoercionHandler] registerCoercer:[PlainTextDocument class]
                                                            selector:@selector(coerceValue:toClass:)
                                                  toConvertFromClass:[PlainTextDocument class]
                                                             toClass:[NSString class]];
	[[NSScriptCoercionHandler sharedCoercionHandler] registerCoercer:[PlainTextDocument class]
                                                            selector:@selector(coerceValue:toClass:)
                                                  toConvertFromClass:[PlainTextDocument class]
                                                             toClass:[FoldableTextStorage class]];

    [self registerTransformers];
    [self addMe];
    [[TCMPortMapper sharedInstance] hashUserID:[TCMMMUserManager myUserID]];

    [self setupFileEncodingsSubmenu];
    [self setupDocumentModeSubmenu];
    [self setupScriptMenu];

    [[[[NSApp mainMenu] itemWithTag:EditMenuTag] submenu] setDelegate:self];

    GeneralPreferences *generalPrefs = [[GeneralPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:generalPrefs];
    EditPreferences *editPrefs = [[EditPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:editPrefs];

	 SEECollaborationPreferenceModule *collabPrefs = [[SEECollaborationPreferenceModule new] autorelease];
	 [TCMPreferenceController registerPrefModule:collabPrefs];
	
    [TCMPreferenceController registerPrefModule:[[StylePreferences new] autorelease]];
    [TCMPreferenceController registerPrefModule:[[PrecedencePreferences new] autorelease]];
    [TCMPreferenceController registerPrefModule:[[AdvancedPreferences new] autorelease]];
    
#ifndef TCM_NO_DEBUG
    [[DebugController sharedInstance] enableDebugMenu:[[NSUserDefaults standardUserDefaults] boolForKey:@"EnableDebugMenu"]];
    DebugPreferences *debugPrefs = [[DebugPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:debugPrefs];
#endif
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:[NSDocumentController sharedDocumentController]
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kKAHL
                                                        andEventID:kMOD];
                                                                                                                
    [self setupTextViewContextMenu];
    [NSApp setServicesProvider:[SEEDocumentController sharedDocumentController]];
    [[SEEDocumentController sharedDocumentController] setAutosavingDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"AutoSavingDelay"]];


    // set up beep profiles
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];
    [TCMBEEPChannel setClass:[GenericSASLProfile class] forProfileURI:TCMBEEPSASLPLAINProfileURI];
	
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
    // set up listening for is ready notificaiton
    [defaultCenter addObserver:self selector:@selector(sessionManagerIsReady:) name:TCMMMBEEPSessionManagerIsReadyNotification object:nil];
	
	// bring up singletons - order is important
    TCMMMBEEPSessionManager *sm = [TCMMMBEEPSessionManager sharedInstance];
	[TCMMMPresenceManager sharedInstance]; // initialize it
	
    // set up default greetings
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
	
	// also for TLS although TLS is temporarily disabled
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];

}
    
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // this is actually after the opening of the first untitled document window!
    
    // set up beep profiles
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];
    [TCMBEEPChannel setClass:[GenericSASLProfile class] forProfileURI:TCMBEEPSASLPLAINProfileURI];
	
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
    // set up listening for is ready notificaiton
    [defaultCenter addObserver:self selector:@selector(sessionManagerIsReady:) name:TCMMMBEEPSessionManagerIsReadyNotification object:nil];

	// bring up singletons - order is important
    TCMMMBEEPSessionManager *sm = [TCMMMBEEPSessionManager sharedInstance];
	TCMMMPresenceManager *presenceManager = [TCMMMPresenceManager sharedInstance];
	
    // set up default greetings
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];

	// also for TLS although TLS is temporarily disabled
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];

	[SEEConnectionManager sharedInstance];
    [presenceManager startRendezvousBrowsing];
    
    [defaultCenter addObserver:self selector:@selector(updateApplicationIcon) name:TCMMMSessionPendingInvitationsDidChange object:nil];
    [defaultCenter addObserver:self selector:@selector(updateApplicationIcon) name:TCMMMSessionPendingUsersDidChangeNotification object:nil];

    [defaultCenter addObserver:self selector:@selector(documentModeListDidChange:) name:@"DocumentModeListChanged" object:nil];

	// start crash reporting
    [[BITHockeyManager sharedHockeyManager] startManager];
}

- (void)sessionManagerIsReady:(NSNotification *)aNotification {
    [[TCMMMBEEPSessionManager sharedInstance] validateListener];
    [[TCMMMPresenceManager sharedInstance] setVisible:[[NSUserDefaults standardUserDefaults] boolForKey:VisibilityPrefKey]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // reset dock icon to normal
    [NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];

    [[TCMPortMapper sharedInstance] stopBlocking];
    [[TCMMMPresenceManager sharedInstance] setVisible:NO]; // will validate so listening so has to be before stopping listening
    [[TCMMMBEEPSessionManager sharedInstance] stopListening];    
    [[TCMMMPresenceManager sharedInstance] stopRendezvousBrowsing];
}

- (void)updateApplicationIcon {
    static NSDictionary *s_attributes=nil;
    if (!s_attributes) {
        float fontsize = 26.;
        NSFont *font=[NSFont fontWithName:@"Helvetica-Bold" size:fontsize];
        if (!font) font=[NSFont systemFontOfSize:fontsize];
//        NSShadow *shadow=[[NSShadow new] autorelease];
//        [shadow setShadowColor:[NSColor blackColor]];
//        [shadow setShadowOffset:NSMakeSize(0.,-2.)];
//        [shadow setShadowBlurRadius:4.];
        
        s_attributes=[[NSDictionary dictionaryWithObjectsAndKeys:
                       font,NSFontAttributeName,
                       [NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSForegroundColorAttributeName,
//                       shadow,NSShadowAttributeName,
                       nil] retain];
    }


    // get the badge count
    int badgeCount = 0;
    NSEnumerator      *documents=[[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    PlainTextDocument *document = nil;
    while ((document=[documents nextObject])) {
		if ([document isKindOfClass:[PlainTextDocument class]]) {
			badgeCount += [[[document session] pendingUsers] count];
			if ([document isPendingInvitation]) {
				badgeCount++;
			}
		}
    }

	[[NSApp dockTile] setBadgeLabel:badgeCount > 0 ? @(badgeCount).stringValue : @""];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)theApplication {
    BOOL result = [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];
    return result;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
	[[SEEDocumentController sharedDocumentController] showDocumentListWindow:sender];
	return YES; // Avoids Untitled Document path of DocumentController
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    static NSMenu *dockMenu=nil;
    if (!dockMenu) {
        dockMenu=[NSMenu new];
		
        NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File",@"New File Dock Menu Item") action:@selector(newDocument:) keyEquivalent:@""] autorelease];
        DocumentModeMenu *menu=[[DocumentModeMenu new] autorelease];
        [dockMenu addItem:item];
        [item setSubmenu:menu];
        [item setTarget:[SEEDocumentController sharedDocumentController]];
        [item setAction:@selector(newDocumentFromDock:)];
        [menu configureWithAction:@selector(newDocumentWithModeMenuItemFromDock:) alternateDisplay:NO];

        item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open File...",@"Open File Dock Menu Item") action:@selector(openNormalDocument:) keyEquivalent:@""] autorelease];
        [dockMenu addItem:item];
        item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"All Tabs",@"all tabs Dock Menu Item") action:NULL keyEquivalent:@""] autorelease];
        [item setSubmenu:[[NSMenu new] autorelease]];
        [item setTarget:[SEEDocumentController sharedDocumentController]];
        [item setAction:@selector(menuValidationNoneAction:)];
        [item setTag:GotoTabMenuItemTag];
        [dockMenu addItem:item];
    }
    return dockMenu;
}

#pragma mark - show mode bundle
- (IBAction)showModeBundleContents:(id)aSender {
	[self showModeBundleForTag:[aSender tag] jumpIntoContentFolder:YES];
}

- (IBAction)showModeBundle:(id)aSender {
	[self showModeBundleForTag:[aSender tag] jumpIntoContentFolder:NO];
}

- (void)showModeBundleForTag:(NSInteger)aModeTag jumpIntoContentFolder:(BOOL)aJumpIntoContentFolder {
    DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
    NSString *modeIdentifier = [modeManager documentModeIdentifierForTag:aModeTag];
    if (modeIdentifier) {
		DocumentMode *mode = [modeManager documentModeForIdentifier:modeIdentifier];
		[modeManager revealModeInFinder:mode jumpIntoContentFolder:aJumpIntoContentFolder];
    }
}

#pragma mark
- (void)addDocumentNewSubmenuEntriesToMenu:(NSMenu *)aMenu {
	BOOL inTabs = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
    NSMenu *menu=[[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
	
	NSArray *inWindowsItems = [[[menu itemWithTag:FileNewMenuItemTag] submenu] itemArray];
	NSArray *inTabsItems = [[[menu itemWithTag:FileNewAlternateMenuItemTag] submenu] itemArray];
	
	NSArray *normalItems = inTabs ? inTabsItems : inWindowsItems;
	NSArray *alternateItems = inTabs ? inWindowsItems : inTabsItems;
	
	[normalItems enumerateObjectsUsingBlock:^(NSMenuItem *normalItem, NSUInteger idx, BOOL *stop) {
		BOOL isSelectedModeItem = NO;
		[aMenu addItem:({
			NSMenuItem *item = [[normalItem copy] autorelease];
			if (![item.keyEquivalent isEqualToString:@""]) {
				isSelectedModeItem = YES;
			}
			item.keyEquivalent = @"";
			if (isSelectedModeItem) {
				item.state = NSOnState;
			}
			item;
		})];
		if (!normalItem.isSeparatorItem) {
			NSMenuItem *alternateItem = [[alternateItems[idx] copy] autorelease];
			[alternateItem setAlternate:YES];
			[alternateItem setKeyEquivalent:@""];
			[alternateItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
			[alternateItem setTitle:[NSString stringWithFormat:NSLocalizedString(!inTabs?@"MODE_IN_NEW_TAB_CONTEXT_MENU_TEXT":@"MODE_IN_NEW_WINDOW_CONTEXT_MENU_TEXT",@""),[normalItem title]]];
			if (isSelectedModeItem) {
				alternateItem.state = NSOnState;
			}
			[aMenu addItem:alternateItem];
			
		}
	}];
	
}

- (void)addShortcutToModeForNewDocumentsEntry {
    NSMenu *menu=[[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
    NSMenuItem *menuItem=[menu itemWithTag:FileNewMenuItemTag];
    menu = [menuItem submenu];
    NSEnumerator *menuItems = [[menu itemArray] objectEnumerator];
    NSMenuItem *item = nil;
    while ((item=[menuItems nextObject])) {
        [item setKeyEquivalent:@""];
    }
    item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];
    [item setKeyEquivalentModifierMask:NSCommandKeyMask];
    [item setKeyEquivalent:@"n"];
    
    [menuItem setRepresentedObject:item];
}

- (void)addShortcutToModeForNewAlternateDocumentsEntry {
    NSMenu *menu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
    NSMenuItem *menuItem = [menu itemWithTag:FileNewAlternateMenuItemTag];
    menu = [menuItem submenu];
    NSEnumerator *menuItems = [[menu itemArray] objectEnumerator];
    NSMenuItem *item = nil;
    while ((item=[menuItems nextObject])) {
        [item setKeyEquivalent:@""];
    }
    item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];
    [item setKeyEquivalentModifierMask:NSCommandKeyMask];
    [item setKeyEquivalent:@"t"];
    
    [menuItem setRepresentedObject:item];
}

- (void)documentModeListDidChange:(NSNotification *)aNotification {
    // fix file->new menu
    [self performSelector:@selector(addShortcutToModeForNewDocumentsEntry)          withObject:nil afterDelay:0.0];
    [self performSelector:@selector(addShortcutToModeForNewAlternateDocumentsEntry) withObject:nil afterDelay:0.0];
}

- (void)setupDocumentModeSubmenu {
    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"%@",[[DocumentModeManager sharedInstance] description]);
    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Found modes: %@",[[[DocumentModeManager sharedInstance] availableModes] description]);

    NSMenu *modeMenu = [[[NSApp mainMenu] itemWithTag:ModeMenuTag] submenu];

	NSMenuItem *switchModesMenuItem = ({ // Mode -> Switch Mode
		NSMenuItem *menuItem = [modeMenu itemWithTag:SwitchModeMenuTag]; // from the xib

		DocumentModeMenu *documentModeMenu = [[DocumentModeMenu new] autorelease];
		[documentModeMenu configureWithAction:@selector(chooseMode:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];
		menuItem;
	});

	NSMenuItem *revealModesMenuItem = ({ // Mode -> Show In Finder (ALT)
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal in Finder",@"Reveal in Finder - menu entry") action:nil keyEquivalent:@""];
		[menuItem setAlternate:YES];
		[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		
		DocumentModeMenu *documentModeMenu = [[DocumentModeMenu new] autorelease];
		[documentModeMenu configureWithAction:@selector(showModeBundle:) alternateDisplay:YES];
		[menuItem setSubmenu:documentModeMenu];
		menuItem;
	});
    [modeMenu insertItem:revealModesMenuItem atIndex:[modeMenu indexOfItem:switchModesMenuItem]+1];
    [revealModesMenuItem release];

	NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu]; // from the xib
	{ // File -> New in window
		NSMenuItem *menuItem = [fileMenu itemWithTag:FileNewMenuItemTag]; // from the xib
		[menuItem setKeyEquivalent:@""];

		DocumentModeMenu *documentModeMenu = [[DocumentModeMenu new] autorelease];
		[documentModeMenu configureWithAction:@selector(newDocumentWithModeMenuItem:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];
		
		[self addShortcutToModeForNewDocumentsEntry];
	}
    
	{ // File -> New in tab
		NSMenuItem *menuItem = [fileMenu itemWithTag:FileNewAlternateMenuItemTag]; // from the xib
		[menuItem setKeyEquivalent:@""];
		
		DocumentModeMenu *documentModeMenu = [[DocumentModeMenu new] autorelease];
		[documentModeMenu configureWithAction:@selector(newAlternateDocumentWithModeMenuItem:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];

		[self addShortcutToModeForNewAlternateDocumentsEntry];
	}
}

- (void)setupFileEncodingsSubmenu {
    NSMenuItem *formatMenu = [[NSApp mainMenu] itemWithTag:FormatMenuTag];
    NSMenuItem *fileEncodingsMenuItem = [[formatMenu submenu] itemWithTag:FileEncodingsMenuItemTag];
    
    EncodingMenu *fileEncodingsSubmenu = [[EncodingMenu new] autorelease];
    [fileEncodingsMenuItem setSubmenu:fileEncodingsSubmenu];

    [fileEncodingsSubmenu configureWithAction:@selector(selectEncoding:)];
}

- (void)reloadScriptMenu {
    NSMenu *scriptMenu=[[[NSApp mainMenu] itemWithTag:ScriptMenuTag] submenu];
    while ([scriptMenu numberOfItems]) {
        [scriptMenu removeItemAtIndex:0];
    }
    
    NSMenuItem *item=nil;
    
    // load scripts and do stuff
    [I_scriptsByFilename release];
    I_scriptsByFilename = [NSMutableDictionary new];
    
    [I_contextMenuItemArray release];
    I_contextMenuItemArray = [NSMutableArray new];
    
    // make sure Basic directories have been created
    [DocumentModeManager sharedInstance];
    
	NSArray *scriptURLs = nil;
    NSURL *userScriptsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	if (userScriptsDirectory) {
		scriptURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:userScriptsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
		for (NSURL *scriptURL in scriptURLs)
		{
			if (! [scriptURL.lastPathComponent isEqualToString:@"SubEthaEdit_AuthenticatedSave.scpt"]) {
				ScriptWrapper *script = [ScriptWrapper scriptWrapperWithContentsOfURL:scriptURL];
				if (script) {
					[I_scriptsByFilename setObject:script forKey:[[[scriptURL path] stringByStandardizingPath] stringByDeletingPathExtension]];
				}
			}
		}
    }
    NSURL *applicationScriptsDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Scripts"];
    scriptURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:applicationScriptsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for (NSURL *scriptURL in scriptURLs)
    {
        ScriptWrapper *script = [ScriptWrapper scriptWrapperWithContentsOfURL:scriptURL];
        if (script) {
            [I_scriptsByFilename setObject:script forKey:[[[scriptURL path] stringByStandardizingPath] stringByDeletingPathExtension]];
        }
    }
    
    [I_scriptOrderArray release];
    I_scriptOrderArray = [[[I_scriptsByFilename allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
    
    for (NSString *filename in I_scriptOrderArray) {
        ScriptWrapper *script=[I_scriptsByFilename objectForKey:filename];
        NSDictionary *settingsDictionary = [script settingsDictionary];
        NSString *displayName = filename;
        if (settingsDictionary && [settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey]) {
            displayName = [settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey];
        }
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:displayName
                                                      action:@selector(performScriptAction:)
                                               keyEquivalent:@""];
        [item setTarget:script];
        if (settingsDictionary) {
            [item setKeyEquivalentBySettingsString:[settingsDictionary objectForKey:ScriptWrapperKeyboardShortcutSettingsKey]];
            if ([[[settingsDictionary objectForKey:ScriptWrapperInContextMenuSettingsKey] lowercaseString] isEqualToString:@"yes"]) {
                [I_contextMenuItemArray addObject:[item autoreleasedCopy]];
            }
        }
        [scriptMenu addItem:[item autorelease]];
        
		/* legacy note: the toobar items were loaded here in the past*/
    }
    // add final entries
    [scriptMenu addItem:[NSMenuItem separatorItem]];
    item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload Scripts", @"Reload Scripts MenuItem in Script Menu")
                                     action:@selector(reloadScriptMenu) keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [scriptMenu addItem:item];
    item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Script Folder", @"Open Script Folder MenuItem in Script Menu")
                                     action:@selector(showScriptFolder:) keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [scriptMenu addItem:item];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GlobalScriptsDidReloadNotification object:self];
}

- (void)reportAppleScriptError:(NSDictionary *)anErrorDictionary {
    NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert setMessageText:[anErrorDictionary objectForKey:@"NSAppleScriptErrorBriefMessage"] ? [anErrorDictionary objectForKey:@"NSAppleScriptErrorBriefMessage"] : @"Unknown AppleScript Error"];
    [newAlert setInformativeText:[NSString stringWithFormat:@"%@ (%d)", [anErrorDictionary objectForKey:@"NSAppleScriptErrorMessage"], [[anErrorDictionary objectForKey:@"NSAppleScriptErrorNumber"] intValue]]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    NSWindow *alertWindow=nil;
    NSArray *documents=[NSApp orderedDocuments];
    if ([documents count]>0) alertWindow=[[documents objectAtIndex:0] windowForSheet];
    [newAlert beginSheetModalForWindow:alertWindow
                         modalDelegate:nil
                        didEndSelector:nil
                           contextInfo:NULL];
}

- (IBAction)showScriptFolder:(id)aSender {
    //create Directories
    NSURL *userScriptsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    [[NSWorkspace sharedWorkspace] openURL:userScriptsDirectory];
}

- (void)setupScriptMenu {
    int indexOfWindowMenu = [[NSApp mainMenu] indexOfItemWithTag:WindowMenuTag];
    if (indexOfWindowMenu != -1) {
        NSMenuItem *scriptMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        [scriptMenuItem setImage:[NSImage imageNamed:@"ScriptMenu"]];
        [scriptMenuItem setTag:ScriptMenuTag];
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        [scriptMenuItem setSubmenu:menu];
        [[NSApp mainMenu] insertItem:scriptMenuItem atIndex:indexOfWindowMenu + 1];
        [scriptMenuItem release];
        [self reloadScriptMenu];
    }
}

- (void)setupTextViewContextMenu {
    NSMenu *mainMenu=[NSApp mainMenu];
    NSMenu *EditMenu=[[mainMenu itemWithTag:EditMenuTag] submenu];
    NSMenu *FormatMenu=[[mainMenu itemWithTag:FormatMenuTag] submenu];
    NSMenu *FoldingMenu=[[[[mainMenu itemWithTag:ViewMenuTag] submenu] itemWithTag:FoldingSubmenuTag] submenu];

    NSMenu *defaultMenu=[[NSMenu new] autorelease];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:CutMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:CopyMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:CopyXHTMLMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:CopyStyledMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:PasteMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:BlockeditMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldSelectionMenuTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldCurrentBlockMenuTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldAllCurrentBlockMenuTag] copy] autorelease]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *scriptsSubmenuItem=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Scripts",@"Scripts entry for contextual menu") action:nil keyEquivalent:@""] autorelease];
    NSMenu *menu = [[NSMenu new] autorelease];
    [scriptsSubmenuItem setImage:[NSImage imageNamed:@"ScriptMenuItemIcon"]];
    [scriptsSubmenuItem setTag:12345];
    [menu addItem:[[[NSMenuItem alloc] initWithTitle:@"DummyEntry" action:nil keyEquivalent:@""] autorelease]];
    [scriptsSubmenuItem setSubmenu:menu];
    [defaultMenu addItem:scriptsSubmenuItem];

    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:SpellingMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[FormatMenu itemWithTag:FontMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:SubstitutionsMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:TransformationsMenuItemTag] copy] autorelease]];
    [defaultMenu addItem:[[(NSMenuItem *)[EditMenu itemWithTag:SpeechMenuItemTag] copy] autorelease]];
//    NSLog(@"%s default menu:%@",__FUNCTION__,defaultMenu);
    [SEETextView setDefaultMenu:defaultMenu];
}

- (NSArray *)contextMenuItemArray {
    return I_contextMenuItemArray;
}

// trigger update so keyequivalents match the situation
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action {
    [menu update];
    return NO;
}
    
#pragma mark - BITHockeyManagerDelegate

// needs to be implemente because its required by the protocol
- (void) showMainApplicationWindowForCrashManager:(BITCrashManager *)crashManager
{
}


#pragma mark - IBActions

- (IBAction)undo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document && [document isKindOfClass:[PlainTextDocument class]]) {
        [document undo:aSender];
    } else {
        NSUndoManager *undoManager=[(id)[[NSApp mainWindow] delegate] undoManager];
        [undoManager undo];
    }
}

- (IBAction)redo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document && [document isKindOfClass:[PlainTextDocument class]]) {
        [document redo:aSender];
    } else {
        NSUndoManager *undoManager=[(id)[[NSApp mainWindow] delegate] undoManager];
        [undoManager redo];
    }
}

- (IBAction)reloadDocumentModes:(id)aSender {
    [[DocumentModeManager sharedInstance] reloadDocumentModes:aSender];
}

- (IBAction)showStyleSheetEditorWindow:(id)aSender {
    static SEEStyleSheetEditorWindowController *editorWindowController = nil;
    if (!editorWindowController) {
		editorWindowController = [SEEStyleSheetEditorWindowController new];
	}
    if (![[editorWindowController window] isVisible]) {
		[editorWindowController showWindow:aSender];
    } else {
		[[editorWindowController window] performClose:self];
    }
}

#pragma mark - Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    id undoManager = nil;
    PlainTextDocument *currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if (currentDocument && [currentDocument isKindOfClass:[PlainTextDocument class]]) {
        undoManager = [currentDocument documentUndoManager];
    } else {
        undoManager = [(id)[[NSApp mainWindow] delegate] undoManager];
    }
    
    if (selector == @selector(undo:)) {
        NSString *title = [undoManager undoMenuItemTitle];
        if (title == nil) title = NSLocalizedString(@"&Undo", nil);
        [menuItem setTitle:title];   
        return [undoManager canUndo];
    } else if (selector == @selector(redo:)) {
        NSString *title = [undoManager redoMenuItemTitle];
        if (title == nil) title = NSLocalizedString(@"&Redo", nil);
        [menuItem setTitle:title];
        return [undoManager canRedo];
    }
    return YES;
}

- (void)TCM_showPlainTextFile:(NSString *)fileName {

    NSEnumerator *enumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    NSDocument *doc;
    while ((doc = [enumerator nextObject])) {
        if ([[doc displayName] isEqualToString:[fileName lastPathComponent]]) {
            [doc showWindows];
            return;
        }
    }
    
    NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
    [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:@"utf-8"]
                   forKeyword:'Encd'];                

    ProcessSerialNumber psn = {0, kCurrentProcess};
    NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Hdra' eventID:'See ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];

        [appleEvent setParamDescriptor:propRecord
                            forKeyword:keyAEPropData];
        [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:fileName]
                            forKeyword:'Stdi'];
        [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:[fileName lastPathComponent]]
                       forKeyword:'Pipe'];
        AppleEvent reply;
        (void)AESendMessage([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
    }
}

- (IBAction)showRegExHelp:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"RE" ofType:@"txt"];
    [self TCM_showPlainTextFile:path];
}

- (IBAction)showReleaseNotes:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReleaseNotes" ofType:@"txt"];
    [self TCM_showPlainTextFile:path];
}

- (IBAction)showAcknowledgements:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Acknowledgements" ofType:@"txt"];
    [self TCM_showPlainTextFile:path];
}

- (IBAction)visitWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"http://www.subethaedit.net/",@"WebSite Link")]];
}

- (IBAction)additionalModes:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"http://www.subethaedit.net/modes.html",@"WebSite Mode Link")]];
}

- (IBAction)reportBug:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:NSLocalizedString(@"http://www.subethaedit.net/bugs/?version=%@",@"BugTracker Deep Link"),[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]]];
}

- (IBAction)provideFeedback:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"http://www.subethaedit.net/feedback.html",@"Feedback Link")]];
}

- (void)changeFont:(id)aSender {
    NSEnumerator *orderedWindowEnumerator=[[NSApp orderedWindows] objectEnumerator];
    NSWindow *window;
    while ((window=[orderedWindowEnumerator nextObject])) {
        if ([[window windowController] document]) {
            [[[window windowController] document] changeFont:aSender];
            break;
        }
    }
}


@end
