//
//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <TCMBEEP/TCMBEEP.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "AppController.h"
#import "TCMPreferenceController.h"
#import "RendezvousBrowserController.h"
#import "InternetBrowserController.h"
#import "PlainTextDocument.h"
#import "UndoManager.h"
#import "SetupController.h"
#import "TCMIdleTimer.h"

#import "AdvancedPreferences.h"
#import "EditPreferences.h"
#import "GeneralPreferences.h"
#import "StylePreferences.h"
#import "PrintPreferences.h"

#import "HandshakeProfile.h"
#import "SessionProfile.h"
#import "DocumentModeManager.h"
#import "DocumentController.h"
#import "PlainTextEditor.h"
#import "TextOperation.h"
#import "SelectionOperation.h"
#import "UserChangeOperation.h"
#import "EncodingManager.h"
#import "TextView.h"

#import "URLDataProtocol.h"

#import "FontAttributesToStringValueTransformer.h"
#import "HueToColorValueTransformer.h"
#import "SaturationToColorValueTransformer.h"
#import "PointsToDisplayValueTransformer.h"

#ifndef TCM_NO_DEBUG
#import "Debug/DebugPreferences.h"
#import "Debug/DebugController.h"
#endif

int const EditMenuTag   = 1000;
int const CutMenuItemTag   = 1;
int const CopyMenuItemTag  = 2;
int const CopyXHTMLMenuItemTag = 5;
int const CopyStyledMenuItemTag = 6;
int const PasteMenuItemTag = 3;
int const BlockeditMenuItemTag = 4;
int const SpellingMenuItemTag = 10;
int const SpeechMenuItemTag   = 11;
int const FormatMenuTag = 2000;
int const FontMenuItemTag = 1;
int const FileEncodingsMenuItemTag = 2001;
int const WindowMenuTag = 3000;

static int s_isRegistered=NO;

int abcde() {
    return s_isRegistered;
}


NSString * const DefaultPortNumber = @"port";
NSString * const AddressHistory = @"AddressHistory";
NSString * const SetupDonePrefKey = @"SetupDone";
NSString * const SetupVersionPrefKey = @"SetupVersion";
NSString * const SerialNumberPrefKey = @"SerialNumberPrefKey";
NSString * const LicenseeNamePrefKey = @"LicenseeNamePrefKey";
NSString * const LicenseeOrganizationPrefKey = @"LicenseeOrganizationPrefKey";


@interface AppController (AppControllerPrivateAdditions)

- (void)setupFileEncodingsSubmenu;
- (void)setupScriptMenu;
- (void)setupDocumentModeSubmenu;
- (void)setupTextViewContextMenu;

@end

#pragma mark -

static AppController *sharedInstance = nil;

@implementation AppController

+ (void)initialize {
    [NSURLProtocol registerClass:[URLDataProtocol class]];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setObject:[NSNumber numberWithInt:6942] forKey:DefaultPortNumber];
    [defaults setObject:[NSMutableArray array] forKey:AddressHistory];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:ProhibitInboundInternetSessions];
    [defaults setObject:[NSNumber numberWithDouble:60.] forKey:NetworkTimeoutPreferenceKey];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:VisibilityPrefKey];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"GoIntoBundlesPrefKey"];
#ifdef TCM_NO_DEBUG
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:@"EnableBEEPLogging"];
#endif
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    [[TCMMMTransformator sharedInstance] registerTransformationTarget:[TextOperation class] selector:@selector(transformTextOperation:serverTextOperation:) forOperationId:[TextOperation operationID] andOperationID:[TextOperation operationID]];
    [[TCMMMTransformator sharedInstance] registerTransformationTarget:[SelectionOperation class] selector:@selector(transformOperation:serverOperation:) forOperationId:[SelectionOperation operationID] andOperationID:[TextOperation operationID]];
    [UserChangeOperation class];
    [TCMMMNoOperation class];
}

+ (AppController *)sharedInstance {
    return sharedInstance;
}

- (void)awakeFromNib {
    sharedInstance = self;
    I_lastShouldOpenUntitledFile = NO;
}

- (void)registerTransformers {
    FontAttributesToStringValueTransformer *fontTrans=[[FontAttributesToStringValueTransformer new] autorelease];
    [NSValueTransformer setValueTransformer:fontTrans
                                    forName:@"FontAttributesToString"];
    [NSValueTransformer setValueTransformer:[[HueToColorValueTransformer new] autorelease]
                                    forName:@"HueToColor"];
    [NSValueTransformer setValueTransformer:[[PointsToDisplayValueTransformer new] autorelease]
                                    forName:@"PointsToDisplay"];
    SaturationToColorValueTransformer *satTrans=[[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor blackColor]] autorelease];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToBlackColor"];
    satTrans=[[[SaturationToColorValueTransformer alloc] initWithColor:[NSColor whiteColor]] autorelease];
    [NSValueTransformer setValueTransformer:satTrans 
                                    forName:@"SaturationToWhiteColor"];
}

- (void)addMe {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

    ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];

    // add self as user 
    TCMMMUser *me=[TCMMMUser new];
    NSString *myName =nil;
    NSString *myAIM  =nil;
    NSString *myEmail=nil;
    NSImage *myImage =nil;
    NSImage *scaledMyImage;

    
    NSString *userID=[[NSUserDefaults standardUserDefaults] stringForKey:@"UserID"];
    if (!userID) {
        // first run
        userID=[NSString UUIDString];
        
        CFStringRef appID = (CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        // Set up the preference.
        CFPreferencesSetValue(CFSTR("UserID"), (CFStringRef)userID, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        // Write out the preference data.
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    
    if ([defaults stringForKey:SelectedMyColorPreferenceKey]==nil) {           
        // select random color
        // set basic user data 
        if (meCard) {
            NSString *firstName = [meCard valueForProperty:kABFirstNameProperty];
            NSString *lastName  = [meCard valueForProperty:kABLastNameProperty];            
    
            if ((firstName!=nil) && (lastName!=nil)) {
                myName=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
            } else if (firstName!=nil) {
                myName=firstName;
            } else if (lastName!=nil) {
                myName=lastName;
            } else {
                myName=NSFullUserName();
            }
            
            ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
            NSString *primaryIdentifier=[emails primaryIdentifier];
            if (primaryIdentifier) {
                [defaults setObject:primaryIdentifier forKey:MyEmailIdentifierPreferenceKey];
                myEmail=[emails valueAtIndex:[emails indexForIdentifier:primaryIdentifier]];
            }

            ABMultiValue *aims=[meCard valueForProperty:kABAIMInstantProperty];
            primaryIdentifier=[aims primaryIdentifier];
            if (primaryIdentifier) {
                [defaults setObject:primaryIdentifier forKey:MyAIMIdentifierPreferenceKey];
                myAIM=[aims valueAtIndex:[aims indexForIdentifier:primaryIdentifier]];
            }
        } else {
            myName=NSFullUserName();
            myEmail=@"";
            myAIM=@"";
        }
        if (!myEmail) myEmail=@"";
        if (!myAIM)   myAIM  =@"";
        [defaults setObject:myEmail forKey:MyEmailPreferenceKey];
        [defaults setObject:myAIM forKey:MyAIMPreferenceKey];
        
        int colorHues[]={0,3300/360,6600/360,10900/360,18000/360,22800/360,26400/360,31700/360};
        sranddev();
        int selectedNumber=(int)((double)rand() / ((double)RAND_MAX + 1) * 8);
        [defaults setObject:[NSNumber numberWithInt:selectedNumber]
                     forKey:SelectedMyColorPreferenceKey];
        [defaults setObject:[NSNumber numberWithFloat:colorHues[selectedNumber]] 
                     forKey:MyColorHuePreferenceKey];
    } else {
        // not first run so fill in the stuff
        myAIM  =[defaults stringForKey:MyAIMPreferenceKey];
        myName =[defaults stringForKey:MyNamePreferenceKey];
        myEmail=[defaults stringForKey:MyEmailPreferenceKey];

        NSString *identifier=[defaults stringForKey:MyAIMIdentifierPreferenceKey];
        if (identifier) {
            ABMultiValue *aims=[meCard valueForProperty:kABAIMInstantProperty];
            int index=[aims indexForIdentifier:identifier];
            if (index!=NSNotFound) {
                if (![myAIM isEqualToString:[aims valueAtIndex:index]]) {
                    myAIM=[aims valueAtIndex:index];
                    [defaults setObject:myAIM forKey:MyAIMPreferenceKey];
                }
            }
        }

        identifier=[defaults stringForKey:MyEmailIdentifierPreferenceKey];
        if (identifier) {
            ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
            int index=[emails indexForIdentifier:identifier];
            if (index!=NSNotFound) {
                if (![myEmail isEqualToString:[emails valueAtIndex:index]]) {
                    myEmail=[emails valueAtIndex:index];
                    [defaults setObject:myEmail forKey:MyEmailPreferenceKey];
                }
            }
        }

    }

    if (!myName) {
        myName=NSFullUserName();
    }

    if (meCard) {
        NSData  *imageData;
        if ((imageData=[meCard imageData])) {
            myImage=[[NSImage alloc] initWithData:imageData];
            [myImage setCacheMode:NSImageCacheNever];
        } 
    }
    
    if (!myImage) {
        myImage=[[NSImage imageNamed:@"DefaultPerson.tiff"] retain];
    }
    
    if (!myEmail) myEmail=@"";
    if (!myAIM)   myAIM  =@"";
    
    // resizing the image
    scaledMyImage=[myImage resizedImageWithSize:NSMakeSize(64.,64.)];
//    [myImage setScalesWhenResized:YES];
//    NSSize originalSize=[myImage size];
//    NSSize newSize=NSMakeSize(64.,64.);
//    if (originalSize.width>originalSize.height) {
//        newSize.height=(int)(originalSize.height/originalSize.width*newSize.width);
//        if (newSize.height<=0) newSize.height=1;
//    } else {
//        newSize.width=(int)(originalSize.width/originalSize.height*newSize.height);            
//        if (newSize.width <=0) newSize.width=1;
//    }
//    [myImage setSize:newSize];
//    scaledMyImage=[[NSImage alloc] initWithSize:newSize];
//    [scaledMyImage setCacheMode:NSImageCacheNever];
//    [scaledMyImage lockFocus];
//    NSGraphicsContext *context=[NSGraphicsContext currentContext];
//    NSImageInterpolation oldInterpolation=[context imageInterpolation];
//    [context setImageInterpolation:NSImageInterpolationHigh];
//    [NSColor clearColor];
//    NSRectFill(NSMakeRect(0.,0.,newSize.width,newSize.height));
//    [myImage compositeToPoint:NSMakePoint(0.,0.) operation:NSCompositeCopy];
//    [context setImageInterpolation:oldInterpolation];
//    [scaledMyImage unlockFocus];
    
    NSData *pngData=[scaledMyImage TIFFRepresentation];
    pngData=[[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    // do this because my resized Images don't behave right on setFlipped:, initWithData ones do!
    scaledMyImage=[[[NSImage alloc] initWithData:pngData] autorelease];
    [me setUserID:userID];

    [me setName:myName];
    [[me properties] setObject:myEmail forKey:@"Email"];
    [[me properties] setObject:myAIM forKey:@"AIM"];
    [[me properties] setObject:scaledMyImage forKey:@"Image"];
    [[me properties] setObject:pngData forKey:@"ImageAsPNG"];
    [me setUserHue:[defaults objectForKey:MyColorHuePreferenceKey]];

    [myImage       release];
//    [scaledMyImage release];
    [me prepareImages];
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    [userManager setMe:[me autorelease]];
}

#define MODEMENUTAG 50
#define SWITCHMODEMENUTAG 10
#define MODEMENUNAMETAG 20 

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {

    [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
    
    [self registerTransformers];
    [self addMe];
    [self setupFileEncodingsSubmenu];
    [self setupDocumentModeSubmenu];

    [[[[NSApp mainMenu] itemWithTag:EditMenuTag] submenu] setDelegate:self];

    GeneralPreferences *generalPrefs = [[GeneralPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:generalPrefs];
    EditPreferences *editPrefs = [[EditPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:editPrefs];
    [TCMPreferenceController registerPrefModule:[[StylePreferences new] autorelease]];
    [TCMPreferenceController registerPrefModule:[[PrintPreferences new] autorelease]];
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // this is actually after the opening of the first untitled document window!

    if ([SetupController shouldRun]) {
        SetupController *setupController = [SetupController sharedInstance];
        (int)[NSApp runModalForWindow:[setupController window]];
    }
    
    // set up beep profiles
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];

    [[TCMMMBEEPSessionManager sharedInstance] listen];
    [[TCMMMPresenceManager sharedInstance] startRendezvousBrowsing];
    [[TCMMMPresenceManager sharedInstance] setVisible:[[NSUserDefaults standardUserDefaults] boolForKey:VisibilityPrefKey]];

    [InternetBrowserController sharedInstance];


    I_idleTimer=[[TCMIdleTimer alloc] initWithBeginInterval:120. repeatInterval:100000000.];
    [I_idleTimer setDelegate:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
    NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
    if (name && [serial isValidSerial]) {
        s_isRegistered=YES;
    }

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

    [[TCMMMBEEPSessionManager sharedInstance] stopListening];    
    [[TCMMMPresenceManager sharedInstance] setVisible:NO];
    [[TCMMMPresenceManager sharedInstance] stopRendezvousBrowsing];
    //[[TCMMMBEEPSessionManager sharedInstance] terminateAllBEEPSessions];    
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)theApplication {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSetupDone = ([defaults objectForKey:SetupVersionPrefKey] != nil);
    if (!isSetupDone) {
        I_lastShouldOpenUntitledFile = NO;
        return NO;
    }
    BOOL result = [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];
    I_lastShouldOpenUntitledFile = result;
    return result;
}

- (BOOL)lastShouldOpenUntitledFile {
    return I_lastShouldOpenUntitledFile;
}

- (BOOL)applicationIsIdling {
    return [I_idleTimer isIdling];
}

- (void)setNeedsDisplayOnTextViews {
    NSEnumerator *documents=[[[DocumentController sharedInstance] documents] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document=[documents nextObject])) {
        NSEnumerator *editors=[[document plainTextEditors] objectEnumerator];
        PlainTextEditor *editor=nil;
        while ((editor=[editors nextObject])) {
            [[editor textView] setNeedsDisplay:YES];
        }
    }
}

- (void)idleTimerDidFire:(id)aSender {
    // make all textviews draw their background if not registered
    if (!abcde()) {
        [self setNeedsDisplayOnTextViews];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    if (!abcde()) {
        [self setNeedsDisplayOnTextViews];
    }
}

- (void)idleTimerDidStop:(id)aSender {
    // make all textviews draw their background if not registered
    if (!abcde() && [NSApp isActive]) {
        [self setNeedsDisplayOnTextViews];
    }
}


- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    static NSMenu *dockMenu=nil;
    if (!dockMenu) {
        dockMenu=[NSMenu new];
        NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File",@"New File Dock Menu Item") action:@selector(newDocument:) keyEquivalent:@""] autorelease];
        [dockMenu addItem:item];
        item=[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open File...",@"Open File Dock Menu Item") action:@selector(openDocument:) keyEquivalent:@""] autorelease];
        [dockMenu addItem:item];
    }
    return dockMenu;
}


- (void)setupDocumentModeSubmenu {
    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"%@",[[DocumentModeManager sharedInstance] description]);
    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Found modes: %@",[[[DocumentModeManager sharedInstance] availableModes] description]);

    NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:MODEMENUTAG] submenu];
    NSMenuItem *switchModesMenuItem=[modeMenu itemWithTag:SWITCHMODEMENUTAG];

    DocumentModeMenu *menu=[[DocumentModeMenu new] autorelease];
    [switchModesMenuItem setSubmenu:menu];
    [menu configureWithAction:@selector(chooseMode:)];
    
}

- (void)setupFileEncodingsSubmenu {
    NSMenuItem *formatMenu = [[NSApp mainMenu] itemWithTag:FormatMenuTag];
    NSMenuItem *fileEncodingsMenuItem = [[formatMenu submenu] itemWithTag:FileEncodingsMenuItemTag];
    
    EncodingMenu *fileEncodingsSubmenu = [[EncodingMenu new] autorelease];
    [fileEncodingsMenuItem setSubmenu:fileEncodingsSubmenu];

    [fileEncodingsSubmenu configureWithAction:@selector(selectEncoding:)];
}

- (void)setupScriptMenu {
    int indexOfWindowMenu = [[NSApp mainMenu] indexOfItemWithTag:WindowMenuTag];
    if (indexOfWindowMenu != -1) {
        NSMenuItem *scriptMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        [scriptMenuItem setImage:[NSImage imageNamed:@"ScriptMenu"]];
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        [scriptMenuItem setSubmenu:menu];
        [[NSApp mainMenu] insertItem:scriptMenuItem atIndex:indexOfWindowMenu + 1];
        [scriptMenuItem release];
    }
}

- (void)setupTextViewContextMenu {
    NSMenu *mainMenu=[NSApp mainMenu];
    NSMenu *EditMenu=[[mainMenu itemWithTag:EditMenuTag] submenu];
    NSMenu *FormatMenu=[[mainMenu itemWithTag:FormatMenuTag] submenu];

    NSMenu *defaultMenu=[NSMenu new];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CutMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyXHTMLMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:CopyStyledMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:PasteMenuItemTag] copy]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:BlockeditMenuItemTag] copy]];
    [defaultMenu addItem:[NSMenuItem separatorItem]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:SpellingMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[FormatMenu itemWithTag:FontMenuItemTag] copy]];
    [defaultMenu addItem:[(NSMenuItem *)[EditMenu itemWithTag:SpeechMenuItemTag] copy]];
    
    [TextView setDefaultMenu:defaultMenu];
}


// trigger update so keyequivalents match the situation
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action {
    [menu update];
    return NO;
}
#pragma mark ### IBActions ###

- (IBAction)undo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document) {
        [document undo:aSender];
    } else {
        NSUndoManager *undoManager=[[[NSApp mainWindow] delegate] undoManager];
        [undoManager undo];
    }
}

- (IBAction)redo:(id)aSender {
    id document=[[NSDocumentController sharedDocumentController] currentDocument];
    if (document) {
        [document redo:aSender];
    } else {
        NSUndoManager *undoManager=[[[NSApp mainWindow] delegate] undoManager];
        [undoManager redo];
    }
}

- (IBAction)purchaseSubEthaEdit:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.codingmonkeys.de/subethaedit/purchase/"]];
}

- (IBAction)enterSerialNumber:(id)sender {
    [[SetupController sharedInstance] showWindow:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    if (selector==@selector(undo:)) {
        PlainTextDocument *currentDocument=[[NSDocumentController sharedDocumentController] currentDocument];
        if (currentDocument) {
            return [[currentDocument documentUndoManager] canUndo];
        } else {
            NSUndoManager *undoManager=[[[NSApp mainWindow] delegate] undoManager];
            return [undoManager canUndo];
        }
    } else if (selector==@selector(redo:)) {
        PlainTextDocument *currentDocument=[[NSDocumentController sharedDocumentController] currentDocument];
        if (currentDocument) {
            return [[currentDocument documentUndoManager] canRedo];
        } else {
            NSUndoManager *undoManager=[[[NSApp mainWindow] delegate] undoManager];
            return [undoManager canRedo];
        }
    } else if (selector==@selector(purchaseSubEthaEdit:)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
        NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
        if (name && [serial isValidSerial]) {
            s_isRegistered=YES;
            return NO;
        }
    } else if (selector==@selector(enterSerialNumber:)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
        NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
        if (name && [serial isValidSerial]) {
            return NO;
        }
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

- (IBAction)showLicense:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    [[NSWorkspace sharedWorkspace] openFile:path];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.codingmonkeys.de/subethaedit/"]];
}

- (IBAction)reportBug:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.codingmonkeys.de/bugs/"]];
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
