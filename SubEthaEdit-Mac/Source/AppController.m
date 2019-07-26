//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.

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
#import "AboutPanelController.h"


#ifndef TCM_NO_DEBUG
#import "Debug/DebugPreferences.h"
#import "Debug/DebugController.h"
#endif

#ifdef INCLUDE_SPARKLE
#import <Sparkle/Sparkle.h>
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
NSString * const SEEAppEffectiveAppearanceDidChangeNotification = @"SEEAppEffectiveAppearanceDidChangeNotification";

NSString * const kSEEPasteBoardTypeConnection = @"SEEPasteBoardTypeConnection";

    
@interface AppController ()
#ifdef FULL
<SPUUpdaterDelegate>
#endif

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

- (void)awakeFromNib {
    sharedInstance = self;
}

- (void)registerTransformers {
    FontAttributesToStringValueTransformer *fontTrans=[FontAttributesToStringValueTransformer new];
    [NSValueTransformer setValueTransformer:fontTrans
                                    forName:@"FontAttributesToString"];
    [NSValueTransformer setValueTransformer:[HueToColorValueTransformer new]
                                    forName:@"HueToColor"];
    [NSValueTransformer setValueTransformer:[PointsToDisplayValueTransformer new]
                                    forName:@"PointsToDisplay"];
    [NSValueTransformer setValueTransformer:[ThousandSeparatorValueTransformer new]
                                    forName:@"AddThousandSeparators"];
    SaturationToColorValueTransformer *satTrans=[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor blackColor]];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToBlackColor"];
    satTrans=[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor whiteColor]];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToWhiteColor"];
}

- (BOOL)didShowFirstUseWindowHelp {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"SEE4_DID_SHOW_FIRST_USE_HELP"];
}

- (void)setDidShowFirstUseWindowHelp:(BOOL)didShowFirstUseWindowHelp {
	[[NSUserDefaults standardUserDefaults] setBool:didShowFirstUseWindowHelp forKey:@"SEE4_DID_SHOW_FIRST_USE_HELP"];
	[[NSUserDefaults standardUserDefaults] synchronize];
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
	
        CFStringRef appID = (__bridge CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
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
    [userManager setMe:me];
}

#define MODEMENUNAMETAG 20 

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	// For first use testing
	// [self setDidShowFirstUseWindowHelp:NO];

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

    GeneralPreferences *generalPrefs = [GeneralPreferences new];
    [TCMPreferenceController registerPrefModule:generalPrefs];
    EditPreferences *editPrefs = [EditPreferences new];
    [TCMPreferenceController registerPrefModule:editPrefs];

	 SEECollaborationPreferenceModule *collabPrefs = [SEECollaborationPreferenceModule new];
	 [TCMPreferenceController registerPrefModule:collabPrefs];
	
    [TCMPreferenceController registerPrefModule:[StylePreferences new]];
    [TCMPreferenceController registerPrefModule:[PrecedencePreferences new]];
    [TCMPreferenceController registerPrefModule:[AdvancedPreferences new]];
    
#ifndef TCM_NO_DEBUG
    [[DebugController sharedInstance] enableDebugMenu:[[NSUserDefaults standardUserDefaults] boolForKey:@"EnableDebugMenu"]];
    DebugPreferences *debugPrefs = [DebugPreferences new];
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
    [defaultCenter addObserver:self selector:@selector(updateApplicationIcon) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:nil];

    [defaultCenter addObserver:self selector:@selector(documentModeListDidChange:) name:@"DocumentModeListChanged" object:nil];

    [self localizeAppMenu];
    
	// check built in mode versions
	[self performSelector:@selector(checkUserModesForUpdateAfterVersionBump) withObject:nil afterDelay:0.0];
    
    if (@available(macOS 10.14, *)) {
        // Observe the app's effective appearance
        [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [[NSNotificationCenter defaultCenter] postNotificationName:SEEAppEffectiveAppearanceDidChangeNotification object:NSApp];
}

#pragma mark
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL result = NO;
	BOOL shouldOpenUntitledFile = [defaults boolForKey:OpenUntitledDocumentOnStartupPreferenceKey];
	BOOL shouldOpenDocumentHub = [defaults boolForKey:OpenDocumentHubOnStartupPreferenceKey];
	
	if (shouldOpenDocumentHub || shouldOpenUntitledFile) {
		result = YES;
	}
	
    return result;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL result = YES; // Avoids Untitled Document path of DocumentController
	BOOL shouldOpenUntitledFile = [defaults boolForKey:OpenUntitledDocumentOnStartupPreferenceKey];
	BOOL shouldOpenDocumentHub = [defaults boolForKey:OpenDocumentHubOnStartupPreferenceKey];
	if (shouldOpenDocumentHub) {
		if (shouldOpenUntitledFile) {
			[[SEEDocumentController sharedDocumentController] showDocumentListWindow:self]; // avoids closing of document hub untitled file window opens
		} else {
			[[SEEDocumentController sharedDocumentController] showDocumentListWindow:sender];
		}
	}

	if (shouldOpenUntitledFile) {
		result = NO;
	}
	
	self.lastShouldOpenUntitledFile = shouldOpenUntitledFile;
	
	return result;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    static NSMenu *dockMenu=nil;
    if (!dockMenu) {
        dockMenu=[NSMenu new];
		
        NSMenuItem *item=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File",@"New File Dock Menu Item") action:@selector(newDocument:) keyEquivalent:@""];
        DocumentModeMenu *menu=[DocumentModeMenu new];
        [dockMenu addItem:item];
        [item setSubmenu:menu];
        [item setTarget:[SEEDocumentController sharedDocumentController]];
        [item setAction:@selector(newDocumentFromDock:)];
        [menu configureWithAction:@selector(newDocumentWithModeMenuItemFromDock:) alternateDisplay:NO];

        item=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open File...",@"Open File Dock Menu Item") action:@selector(openNormalDocument:) keyEquivalent:@""];
        [dockMenu addItem:item];
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"All Tabs",@"all tabs Dock Menu Item") action:NULL keyEquivalent:@""];
    }
    return dockMenu;
}

#pragma mark - check for mode updates
- (void)checkUserModesForUpdateAfterVersionBump {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastKnownBundleVersion = [defaults stringForKey:kSEELastKnownBundleVersion];
	NSString *currentBundleVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
	
	BOOL currentVersionIsHigher;
	
	if (lastKnownBundleVersion) {
		currentVersionIsHigher = ([lastKnownBundleVersion compare:currentBundleVersion options:NSNumericSearch] == NSOrderedAscending);
	} else {
		currentVersionIsHigher = YES;
	}
	
	if (currentVersionIsHigher) {
		// check for modes with higher bundle version
		NSDictionary *builtInModesDict = @{
										   @"SEEMode.ActionScript" : @"ActionScript",
										   @"SEEMode.Base" : @"Base",
										   @"SEEMode.C" : @"C",
										   @"SEEMode.CPP" : @"C++",
										   @"SEEMode.CSS" : @"CSS",
										   @"SEEMode.Conference" : @"Conference",
										   @"SEEMode.Diff" : @"Diff",
										   @"SEEMode.ERB" : @"ERB",
										   @"SEEMode.Erlang" : @"erlang",
										   @"SEEMode.HTML" : @"HTML",
										   @"SEEMode.Java" : @"Java",
										   @"SEEMode.Javascript" : @"Javascript",
										   @"SEEMode.LaTeX" : @"LaTeX",
										   @"SEEMode.Lua" : @"Lua",
										   @"SEEMode.Objective-C" : @"Objective-C",
										   @"SEEMode.PHP-HTML" : @"PHP-HTML",
										   @"SEEMode.Perl" : @"Perl",
										   @"SEEMode.Python" : @"Python",
										   @"SEEMode.Ruby" : @"Ruby",
										   @"SEEMode.Swift" : @"Swift",
										   @"SEEMode.XML" : @"XML",
										   @"SEEMode.bash" : @"bash",
										   @"SEEMode.go" : @"go"
										   };
		
		DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSMutableArray *updatableModeURLs = [NSMutableArray array];
		NSMutableArray *updatableModeNames = [NSMutableArray array];
		for (NSString *string in [builtInModesDict allKeys]) {
			BOOL isAvailable = [modeManager documentModeAvailableModeIdentifier:string];
			if (isAvailable) {
				DocumentMode *installedMode = [modeManager documentModeForIdentifier:string];
				NSBundle *installedModeBundle = [installedMode bundle];
				NSString *installedModeFileName = [installedModeBundle bundlePath];
				BOOL installedModeIsBuiltIn = [installedModeFileName hasPrefix:[[NSBundle mainBundle] bundlePath]];
				
				if (!installedModeIsBuiltIn) {
					NSString *versionStringOfInstalledMode = [installedModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
					
					NSBundle *builtinModeBundle = [NSBundle bundleWithURL:[mainBundle URLForResource:builtInModesDict[string] withExtension:MODE_EXTENSION subdirectory:@"Modes"]];
					NSString *versionStringOfBuiltinMode = [builtinModeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
					
					BOOL builtinVersionIsHigher = ([versionStringOfInstalledMode compare:versionStringOfBuiltinMode options:NSNumericSearch] == NSOrderedAscending);
					if (builtinVersionIsHigher) {
						[updatableModeURLs addObject:[installedModeBundle bundleURL]];
						[updatableModeNames addObject:[NSString stringWithFormat:
													   NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_MODE_STRING", nil, [NSBundle mainBundle], @"* Mode for %@ v%@ (currently v%@)", nil),
													   [installedMode displayName],
													   versionStringOfBuiltinMode,
													   versionStringOfInstalledMode]];
					}
				}
			}
		}
		
		if ([updatableModeURLs count] > 0) {
			
			NSString *intro = NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_INFO_INTRO", nil, [NSBundle mainBundle], @"This version of SubEthaEdit comes with newer versions of the following user installed modes: \n\n", nil);
			NSString *modeNames = [updatableModeNames componentsJoinedByString:@"\n"];
			NSString *information = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_INFO_TEXT", nil, [NSBundle mainBundle],
																								 @"\n\nUsing the updated versions removes custom changes you might have made to your mode.\n\nIf you only want to use specific new modes choose 'Show in Finder', delete the modes without modifications and reload the modes from the mode menu in SubEthaEdit.", nil)];
			
            NSAlert *installAlert = [[NSAlert alloc] init];

            installAlert.messageText = NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_MESSAGE", nil, [NSBundle mainBundle], @"Newer Modes available", nil);
            installAlert.informativeText = [NSString stringWithFormat:@"%@%@%@\n", intro, modeNames, information];

            [installAlert addButtonWithTitle:NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_OK_BUTTON", nil, [NSBundle mainBundle], @"Use Updated Modes", nil)];
            [installAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [installAlert addButtonWithTitle:NSLocalizedStringWithDefaultValue(@"MODE_UPDATE_REVEAL_IN_FINDER", nil, [NSBundle mainBundle], @"Show Outdated Modes", nil)];

            NSModalResponse result = [installAlert runModal];

            if (result == NSAlertThirdButtonReturn) { // show in finder
                [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:updatableModeURLs];
            } else if (result == NSAlertFirstButtonReturn) { // ok was selected
                NSFileManager *fileManager = [NSFileManager defaultManager];
                for (NSURL *url in updatableModeURLs) {
                    NSURL *urlInTrash = nil;
                    NSError *deletionError = nil;
                    //                    BOOL deletionSuccess = [fileManager trashItemAtURL:destinationURL resultingItemURL:&urlInTrash error:&deletionError];
                    [fileManager trashItemAtURL:url resultingItemURL:&urlInTrash error:&deletionError];
                }
                [[DocumentModeManager sharedInstance] reloadDocumentModes:self];
            }
		}
		
		[defaults setObject:currentBundleVersion forKey:kSEELastKnownBundleVersion];
//		[defaults removeObjectForKey:kSEELastKnownBundleVersion]; // debug
		[defaults synchronize];
	} // else: do nothing.
//	[defaults removeObjectForKey:kSEELastKnownBundleVersion]; // debug
}

#pragma mark - show mode bundle
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
  // TODO: refactor
	BOOL inTabs = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
    NSMenu *menu=[[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
	
	NSArray *inWindowsItems = [[[menu itemWithTag:FileNewMenuItemTag] submenu] itemArray];
	NSArray *inTabsItems = [[[menu itemWithTag:FileNewAlternateMenuItemTag] submenu] itemArray];
	
	NSArray *normalItems = inTabs ? inTabsItems : inWindowsItems;
	NSArray *alternateItems = inTabs ? inWindowsItems : inTabsItems;
	
	[normalItems enumerateObjectsUsingBlock:^(NSMenuItem *normalItem, NSUInteger idx, BOOL *stop) {
		BOOL isSelectedModeItem = NO;
		[aMenu addItem:({
			NSMenuItem *item = [normalItem copy];
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
			NSMenuItem *alternateItem = [alternateItems[idx] copy];
			[alternateItem setAlternate:YES];
			[alternateItem setKeyEquivalent:@""];
			[alternateItem setKeyEquivalentModifierMask:NSEventModifierFlagOption];
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
    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
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
    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
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

		DocumentModeMenu *documentModeMenu = [DocumentModeMenu new];
		[documentModeMenu configureWithAction:@selector(chooseMode:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];
		menuItem;
	});

	NSMenuItem *revealModesMenuItem = ({ // Mode -> Show In Finder (ALT)
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal in Finder",@"Reveal in Finder - menu entry") action:nil keyEquivalent:@""];
		[menuItem setAlternate:YES];
		[menuItem setKeyEquivalentModifierMask:NSEventModifierFlagOption];
		
		DocumentModeMenu *documentModeMenu = [DocumentModeMenu new];
		[documentModeMenu configureWithAction:@selector(showModeBundle:) alternateDisplay:YES];
		[menuItem setSubmenu:documentModeMenu];
		menuItem;
	});
    [modeMenu insertItem:revealModesMenuItem atIndex:[modeMenu indexOfItem:switchModesMenuItem]+1];

	NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu]; // from the xib
	{ // File -> New in window
		NSMenuItem *menuItem = [fileMenu itemWithTag:FileNewMenuItemTag]; // from the xib
		[menuItem setKeyEquivalent:@""];

		DocumentModeMenu *documentModeMenu = [DocumentModeMenu new];
		[documentModeMenu configureWithAction:@selector(newDocumentWithModeMenuItem:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];
		
		[self addShortcutToModeForNewDocumentsEntry];
	}
    
	{ // File -> New in tab
		NSMenuItem *menuItem = [fileMenu itemWithTag:FileNewAlternateMenuItemTag]; // from the xib
		[menuItem setKeyEquivalent:@""];
		
		DocumentModeMenu *documentModeMenu = [DocumentModeMenu new];
		[documentModeMenu configureWithAction:@selector(newAlternateDocumentWithModeMenuItem:) alternateDisplay:NO];
		[menuItem setSubmenu:documentModeMenu];

		[self addShortcutToModeForNewAlternateDocumentsEntry];
	}
}

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SEE_APP_PRODUCT_NAME_STRING @ STRINGIZE2(SEE_APP_PRODUCT_NAME)

+ (NSString *)localizedApplicationName {
    return SEE_APP_PRODUCT_NAME_STRING;
}

- (void)localizeAppMenu {
    NSMenu *appMenu = [[[NSApp mainMenu] itemWithTag:AppMenuTag] submenu];
    NSString *appName = AppController.localizedApplicationName;
    for (NSMenuItem *item in appMenu.itemArray) {
        if ([item.target isKindOfClass:[AboutPanelController class]]) {
            item.title = [NSString stringWithFormat:NSLocalizedString(@"SEE_APP_MENU_ABOUT", nil), appName];
        } else if (item.action == @selector(hide:)) {
            item.title = [NSString stringWithFormat:NSLocalizedString(@"SEE_APP_MENU_HIDE", nil), appName];
        } else if (item.action == @selector(terminate:)) {
            item.title = [NSString stringWithFormat:NSLocalizedString(@"SEE_APP_MENU_QUIT", nil), appName];
        }
    }
    
#ifdef INCLUDE_SPARKLE
    
    
    static SPUStandardUpdaterController *updaterController = nil; updaterController = updaterController ?: [[SPUStandardUpdaterController alloc] initWithUpdaterDelegate:self userDriverDelegate:nil];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"SEE_APP_MENU_CHECK_FOR_UPDATES", nil) action:@selector(checkForUpdates:) keyEquivalent:@""];
    menuItem.target = updaterController;
    [appMenu insertItem:menuItem atIndex:1];
#endif
    
}

#ifdef INCLUDE_SPARKLE
- (NSString *)feedURLStringForUpdater:(SPUUpdater *)updater {
    return @"https://" SEE_APPCAST_FEED_URL;
}
#endif

- (void)setupFileEncodingsSubmenu {
    NSMenuItem *formatMenu = [[NSApp mainMenu] itemWithTag:FormatMenuTag];
    NSMenuItem *fileEncodingsMenuItem = [[formatMenu submenu] itemWithTag:FileEncodingsMenuItemTag];
    
    EncodingMenu *fileEncodingsSubmenu = [EncodingMenu new];
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
    I_scriptsByFilename = [NSMutableDictionary new];
    
    I_contextMenuItemArray = [NSMutableArray new];
    
    // make sure Basic directories have been created
    [DocumentModeManager sharedInstance];
    
	NSArray *scriptURLs = nil;
    NSURL *userScriptsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString *basePath;
    basePath = [[userScriptsDirectory path] stringByStandardizingPath];
	if (userScriptsDirectory) {
		scriptURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:userScriptsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
		for (NSURL *scriptURL in scriptURLs)
		{
			if (! [scriptURL.lastPathComponent isEqualToString:@"SubEthaEdit_AuthenticatedSave.scpt"]) {
				ScriptWrapper *script = [ScriptWrapper scriptWrapperWithContentsOfURL:scriptURL];
				if (script) {
                    NSString *filename = [[scriptURL path] stringByStandardizingPath];
                    if ([filename hasPrefix:basePath]) {
                        filename = [filename substringFromIndex:basePath.length];
                    }
					[I_scriptsByFilename setObject:script forKey:filename];
				}
			}
		}
    }
    NSURL *applicationScriptsDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Scripts"];
    basePath = [[applicationScriptsDirectory path] stringByStandardizingPath];
    scriptURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:applicationScriptsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for (NSURL *scriptURL in scriptURLs) {
        NSString *filename = [[scriptURL path] stringByStandardizingPath];
        if ([filename hasPrefix:basePath]) {
            filename = [filename substringFromIndex:basePath.length];
        }
        if (!I_scriptsByFilename[filename]) {
            ScriptWrapper *script = [ScriptWrapper scriptWrapperWithContentsOfURL:scriptURL];
            if (script) {
                [I_scriptsByFilename setObject:script forKey:filename];
            }
        }
    }
    
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
        [scriptMenu addItem:item];
        
		/* legacy note: the toobar items were loaded here in the past*/
    }
    // add final entries
    [scriptMenu addItem:[NSMenuItem separatorItem]];
    item=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload Scripts", @"Reload Scripts MenuItem in Script Menu")
                                     action:@selector(reloadScriptMenu) keyEquivalent:@""];
    [item setTarget:self];
    [scriptMenu addItem:item];
    item=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Script Folder", @"Open Script Folder MenuItem in Script Menu")
                                     action:@selector(showScriptFolder:) keyEquivalent:@""];
    [item setTarget:self];
    [scriptMenu addItem:item];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GlobalScriptsDidReloadNotification object:self];
}

- (void)reportAppleScriptError:(NSDictionary *)anErrorDictionary {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(reportAppleScriptError:) withObject:anErrorDictionary waitUntilDone:NO];
    } else {
        NSAlert *newAlert = [[NSAlert alloc] init];
      [newAlert setAlertStyle:NSAlertStyleCritical];
        [newAlert setMessageText:[anErrorDictionary objectForKey:@"NSAppleScriptErrorBriefMessage"] ? [anErrorDictionary objectForKey:@"NSAppleScriptErrorBriefMessage"] : @"Unknown AppleScript Error"];
        [newAlert setInformativeText:[NSString stringWithFormat:@"%@ (%d)", [anErrorDictionary objectForKey:@"NSAppleScriptErrorMessage"], [[anErrorDictionary objectForKey:@"NSAppleScriptErrorNumber"] intValue]]];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        NSWindow *alertWindow=nil;
        NSArray *documents=[NSApp orderedDocuments];
        if ([documents count]>0) alertWindow=[[documents objectAtIndex:0] windowForSheet];
        [newAlert beginSheetModalForWindow:alertWindow
                         completionHandler:nil];
    }
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
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [scriptMenuItem setSubmenu:menu];
        [[NSApp mainMenu] insertItem:scriptMenuItem atIndex:indexOfWindowMenu + 1];
        [self reloadScriptMenu];
    }
}

- (void)setupTextViewContextMenu {
    NSMenu *mainMenu=[NSApp mainMenu];
    NSMenu *EditMenu=[[mainMenu itemWithTag:EditMenuTag] submenu];
    NSMenu *FormatMenu=[[mainMenu itemWithTag:FormatMenuTag] submenu];
    NSMenu *FoldingMenu=[[[[mainMenu itemWithTag:ViewMenuTag] submenu] itemWithTag:FoldingSubmenuTag] submenu];

    NSMenu *defaultMenu=[NSMenu new];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CutMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyXHTMLMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyStyledMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:PasteMenuItemTag] copy]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:BlockeditMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldSelectionMenuTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldCurrentBlockMenuTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[FoldingMenu itemWithTag:FoldingFoldAllCurrentBlockMenuTag] copy]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *scriptsSubmenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Scripts",@"Scripts entry for contextual menu") action:nil keyEquivalent:@""];
    NSMenu *menu = [NSMenu new];
    [scriptsSubmenuItem setImage:[NSImage imageNamed:@"ScriptMenuItemIcon"]];
    [scriptsSubmenuItem setTag:12345];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"DummyEntry" action:nil keyEquivalent:@""]];
    [scriptsSubmenuItem setSubmenu:menu];
    [defaultMenu addItem:scriptsSubmenuItem];

    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:SpellingMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[FormatMenu itemWithTag:FontMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:SubstitutionsMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:TransformationsMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:SpeechMenuItemTag] copy]];
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

#pragma mark - IBActions

- (IBAction)undo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document && [document isKindOfClass:[PlainTextDocument class]]) {
        [document undo:aSender];
    } else {
        NSUndoManager *undoManager=[(id)[[NSApp mainWindow] firstResponder] undoManager];
        [undoManager undo];
    }
}

- (IBAction)redo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document && [document isKindOfClass:[PlainTextDocument class]]) {
        [document redo:aSender];
    } else {
        NSUndoManager *undoManager=[(id)[[NSApp mainWindow] firstResponder] undoManager];
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
        undoManager = [currentDocument TCM_undoManagerToUse];
    } else {
        undoManager = [(id)[[NSApp mainWindow] firstResponder] undoManager];
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


- (void)showPlainTextTemplate:(NSString *)fileName replacements:(NSDictionary<NSString *, NSString *> *)replacements {
    
    NSMutableString *string = [NSMutableString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
    [replacements enumerateKeysAndObjectsUsingBlock:^(NSString *pattern, NSString *replacement, BOOL *_stop) {
        [string replaceOccurrencesOfString:[NSString stringWithFormat:@"{%@}", pattern] withString:replacement options:0 range:[string TCM_fullLengthRange]];
    }];
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName.lastPathComponent];
    [[string dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tempPath atomically:YES];
    
    
    NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
    [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:@"utf-8"]
                   forKeyword:'Encd'];
    
    ProcessSerialNumber psn = {0, kCurrentProcess};
    NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Hdra' eventID:'See ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        
        [appleEvent setParamDescriptor:propRecord
                            forKeyword:keyAEPropData];
        [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:tempPath]
                            forKeyword:'Stdi'];
        [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:[fileName lastPathComponent]]
                       forKeyword:'Pipe'];
        AppleEvent reply;
        (void)AESendMessage([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
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
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Acknowledgements" ofType:@"md"];
    [self TCM_showPlainTextFile:path];
}

- (IBAction)visitFAQWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"WEBSITE_FAQ",@"FAQ WebSite Link")]];
}

- (IBAction)additionalModes:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"WEBSITE_ADDITIONAL_MODES",@"WebSite Mode Link")]];
}

- (IBAction)showModeCreationDocumentation:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"WEBSITE_MODE_CREATION_DOCU",@"WebSite Mode Creation Docu")]];
}

+ (NSString *)localizedVersionString {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionString = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"Marketing version followed by build version e.g. Version 2.0 (739)"),
                               [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                               [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    return versionString;
}

- (IBAction)reportAnIssue:(id)sender {
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *hardwareInfo = ({
        NSString *result = [NSString stringWithFormat:@"Hardware: \n Cores: %lu\n Memory: %lu MB\n", (unsigned long)NSProcessInfo.processInfo.activeProcessorCount, (unsigned long)NSProcessInfo.processInfo.physicalMemory / 1024 / 1024 ];
        @try {
            NSTask *task = [NSTask new];
            task.launchPath = @"/usr/bin/env";
            task.arguments = @[@"system_profiler",
                               @"SPHardwareDataType"];
            NSPipe *standardOutput = [NSPipe new];
            task.standardOutput = standardOutput;
            [task launch];
            [task waitUntilExit];
            result = [NSString stringWithData:[standardOutput.fileHandleForReading readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        }
        @catch (NSException *exception) {
        }
        result;
    });
    
    NSString *path = [bundle pathForResource:@"Bug Report" ofType:@"md"];
    [self showPlainTextTemplate:path replacements:@{
        @"SEE_APP_PRODUCT_NAME" : AppController.localizedApplicationName,
        @"SEE_VERSION_STRING" : AppController.localizedVersionString,
        @"SEE_MACOS_VERSION" : NSProcessInfo.processInfo.operatingSystemVersionString,
        @"SEE_HARDWARE" : hardwareInfo,
        @"SEE_LANGUAGE" : bundle.preferredLocalizations.firstObject,
    }];
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

- (IBAction)revealInstallCommandInFinder:(id)sender {
    // Reveal tool installation script in finder
    NSURL *scriptFileURL = self.URLOfInstallCommand;
    //            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[scriptFileURL]];
    NSString *scriptFilePath = [scriptFileURL path];
    [[NSWorkspace sharedWorkspace] selectFile:scriptFilePath inFileViewerRootedAtPath:[scriptFilePath stringByDeletingLastPathComponent]];
}
- (NSURL *)URLOfInstallCommand {
    NSURL *result = [[[NSBundle mainBundle] sharedSupportURL] URLByAppendingPathComponent:@"bin/install.command"];
    return result;
}


@end
