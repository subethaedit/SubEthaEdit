//
//  DocumentModeManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ModeSettings.h"
#import "DocumentModeManager.h"
#import "DocumentController.h"
#import "PlainTextDocument.h"
#import "GeneralPreferences.h"
#import "SyntaxStyle.h"
#import <OgreKit/OgreKit.h>


#define MODEPATHCOMPONENT @"Application Support/SubEthaEdit/Modes/"

@interface DocumentModeManager (DocumentModeManagerPrivateAdditions)
- (void)TCM_findModes;
- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateDisplay:(BOOL)aFlag;
- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode;
@end

@implementation DocumentModePopUpButton

/* Replace the cell, sign up for notifications.
*/
- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        I_automaticMode = NO;
    }
    return self;
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    [[DocumentModeManager sharedInstance] setupPopUp:self selectedModeIdentifier:BASEMODEIDENTIFIER automaticMode:I_automaticMode];
}

- (void)setHasAutomaticMode:(BOOL)aFlag {
    I_automaticMode = aFlag;
    [self documentModeListChanged:[NSNotification notificationWithName:@"DocumentModeListChanged" object:self]];
}

- (NSString *)selectedModeIdentifier {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    return [manager documentModeIdentifierForTag:[[self selectedItem] tag]];
}

- (void)setSelectedModeIdentifier:(NSString *)aModeIdentifier {
    int tag=[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:aModeIdentifier];
    [self selectItemAtIndex:[[self menu] indexOfItemWithTag:tag]];
}

- (DocumentMode *)selectedMode {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    return [manager documentModeForIdentifier:[manager documentModeIdentifierForTag:[[self selectedItem] tag]]];
}

- (void)setSelectedMode:(DocumentMode *)aMode {
    int tag=[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[aMode bundle] bundleIdentifier]];
    [self selectItemAtIndex:[[self menu] indexOfItemWithTag:tag]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

/* Update contents based on encodings list customization
*/
- (void)documentModeListChanged:(NSNotification *)notification {
    NSString *selectedModeIdentifier=[self selectedModeIdentifier];
    if (![[DocumentModeManager sharedInstance] documentModeAvailableModeIdentifier:selectedModeIdentifier]) {
        selectedModeIdentifier=BASEMODEIDENTIFIER;
    }
    [[DocumentModeManager sharedInstance] setupPopUp:self selectedModeIdentifier:selectedModeIdentifier automaticMode:I_automaticMode];
    [self setSelectedModeIdentifier:selectedModeIdentifier];
}

@end


@implementation DocumentModeMenu
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)documentModeListChanged:(NSNotification *)notification {
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateDisplay:I_alternateDisplay];
}

- (void)configureWithAction:(SEL)aSelector alternateDisplay:(BOOL)aFlag {
    I_action = aSelector;
    I_alternateDisplay = aFlag;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateDisplay:aFlag];
}

@end

@implementation DocumentModeManager

+ (DocumentModeManager *)sharedInstance {
    static DocumentModeManager *sharedInstance=nil;
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (DocumentMode *)baseMode {
    return [[DocumentModeManager sharedInstance] baseMode];
}

+ (NSString *)xmlFileRepresentationOfAllStyles {
    DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSMutableString *result=[NSMutableString string];
    NSDictionary *availableModes=[modeManager availableModes];
    NSEnumerator *identifiers=[[[availableModes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
    NSString *identifier=nil;
    while ((identifier=[identifiers nextObject])) {
        DocumentMode *mode=[modeManager documentModeForIdentifier:identifier];
        [result appendString:[[mode syntaxStyle] xmlRepresentation]];
    }
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<seestyle>\n%@</seestyle>\n",result];
}

- (id)init {
    self = [super init];
    if (self) {
        I_modeBundles=[NSMutableDictionary new];
        I_documentModesByIdentifier =[NSMutableDictionary new];
		I_modeIdentifiersByExtension=[NSMutableDictionary new];
		I_modeIdentifiersByFilename =[NSMutableDictionary new];
		I_modeIdentifiersByRegex    =[NSMutableDictionary new];
		I_modeIdentifiersTagArray   =[NSMutableArray new];
		[I_modeIdentifiersTagArray addObject:@"-"];
		[I_modeIdentifiersTagArray addObject:AUTOMATICMODEIDENTIFIER];
		[I_modeIdentifiersTagArray addObject:BASEMODEIDENTIFIER];
        [self TCM_findModes];
    }
    return self;
}

- (void)dealloc {
    [I_modeBundles release];
    [I_documentModesByIdentifier release];
	[I_modeIdentifiersByExtension release];
	[I_modeIdentifiersByFilename release];
	[I_modeIdentifiersByRegex release];
    [super dealloc];
}

- (void)TCM_findModes {
    NSString *file;
    NSString *path;
    
    //create Directories
    NSArray *userDomainPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSEnumerator *enumerator = [userDomainPaths objectEnumerator];
    while ((path = [enumerator nextObject])) {
        NSString *fullPath = [path stringByAppendingPathComponent:MODEPATHCOMPONENT];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] attributes:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
        }
    }

        
    NSMutableArray *allPaths = [NSMutableArray array];
    NSArray *allDomainsPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    enumerator = [allDomainsPaths objectEnumerator];
    while ((path = [enumerator nextObject])) {
        [allPaths addObject:[path stringByAppendingPathComponent:MODEPATHCOMPONENT]];
    }
    
    [allPaths addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Modes/"]];
    
    enumerator = [allPaths reverseObjectEnumerator];
    while ((path = [enumerator nextObject])) {
        NSEnumerator *dirEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
        while ((file = [dirEnumerator nextObject])) {
			//NSLog(@"%@",file);
            if ([[file pathExtension] isEqualToString:@"mode"]) {
                NSBundle *bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:file]];
                if (bundle && [bundle bundleIdentifier]) {
                    ModeSettings *modeSettings = [[ModeSettings alloc] initWithFile:[bundle pathForResource:@"ModeSettings" ofType:@"xml"]];
                    NSEnumerator *extensions, *filenames, *regexes;
                    if (modeSettings) {
                        extensions = [[modeSettings recognizedExtensions] objectEnumerator];
                        filenames = [[modeSettings recognizedFilenames] objectEnumerator];
                        regexes = [[modeSettings recognizedRegexes] objectEnumerator];
                    } else {
                        CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)[bundle bundlePath], kCFURLPOSIXPathStyle, 1);
                        CFDictionaryRef infodict = CFBundleCopyInfoDictionaryInDirectory(url);
                        NSDictionary *infoDictionary = (NSDictionary *) infodict;
					    extensions = [[infoDictionary objectForKey:@"TCMModeExtensions"] objectEnumerator];
					    filenames = [[infoDictionary objectForKey:@"TCMModeFilenames"] objectEnumerator];
					    regexes = [[infoDictionary objectForKey:@"TCMModeRegex"] objectEnumerator];
                        CFRelease(url);
                        CFRelease(infodict);
                    }
                    
					NSString *extension = nil;
					while ((extension = [extensions nextObject])) {
						[I_modeIdentifiersByExtension setObject:[bundle bundleIdentifier] forKey:extension];
					}
					
					NSString *filename = nil;
					while ((filename = [filenames nextObject])) {
						[I_modeIdentifiersByFilename setObject:[bundle bundleIdentifier] forKey:filename];
					}
					
					NSString *regex = nil;
					while ((regex = [regexes nextObject])) {
                        if ([OGRegularExpression isValidExpressionString:regex]) {
						[I_modeIdentifiersByRegex setObject:[bundle bundleIdentifier] forKey:[[[OGRegularExpression alloc] initWithString:regex options:OgreFindNotEmptyOption]autorelease]];
				        }
					}
					
                    [I_modeBundles setObject:bundle forKey:[bundle bundleIdentifier]];
                    if (![I_modeIdentifiersTagArray containsObject:[bundle bundleIdentifier]]) {
                        [I_modeIdentifiersTagArray addObject:[bundle bundleIdentifier]];
                    }
                }
            }
        }
    }
}

- (IBAction)reloadDocumentModes:(id)aSender {
    // write all preferences
    [[I_documentModesByIdentifier allValues] makeObjectsPerformSelector:@selector(writeDefaults)];

    // reload all modes
    [I_modeBundles                removeAllObjects];
    [I_documentModesByIdentifier  removeAllObjects];
    [I_modeIdentifiersByExtension removeAllObjects];
    [I_modeIdentifiersByFilename removeAllObjects];
    [I_modeIdentifiersByRegex removeAllObjects];
    [self TCM_findModes];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DocumentModeListChanged" object:self];
    
    // replace the DocumentModes in the documents
    NSEnumerator      *documents = [[[DocumentController sharedDocumentController] documents] objectEnumerator];
    PlainTextDocument *document = nil;
    while ((document=[documents nextObject])) {
        DocumentMode *oldMode = [document documentMode];
        DocumentMode *newMode = [self documentModeForIdentifier:[oldMode documentModeIdentifier]];
        [document setDocumentMode:newMode];
    }
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DocumentModeManager, FoundModeBundles:%@",[I_modeBundles description]];
}

- (DocumentMode *)documentModeForName:(NSString *)aName {
    NSString *identifier;
    if ([aName hasPrefix:@"SEEMode."]) {
        identifier = aName;
    } else {
        identifier = [NSString stringWithFormat:@"SEEMode.%@", aName];
    }
    DocumentMode *mode = [self documentModeForIdentifier:identifier];
    
    if (!mode) {
        NSEnumerator *keyEnumerator = [[self availableModes] keyEnumerator];
        NSString *key;
        while ((key = [keyEnumerator nextObject])) {
            if ([identifier caseInsensitiveCompare:key] == NSOrderedSame) {
                mode = [self documentModeForIdentifier:key];
                break;
            }
        }
    }
    
    return mode;
}

- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier {
	NSBundle *bundle=[I_modeBundles objectForKey:anIdentifier];
	if (bundle) {
        DocumentMode *mode=[I_documentModesByIdentifier objectForKey:anIdentifier];
        if (!mode) {
            mode = [[[DocumentMode alloc] initWithBundle:bundle] autorelease];
            if (mode)
                [I_documentModesByIdentifier setObject:mode forKey:anIdentifier];
        }
        return mode;
	} else {
        return nil;
    }
}

- (DocumentMode *)baseMode {
    return [self documentModeForIdentifier:BASEMODEIDENTIFIER];
}

- (DocumentMode *)modeForNewDocuments {
    DocumentMode *returnValue=[self documentModeForIdentifier:[[NSUserDefaults standardUserDefaults] objectForKey:ModeForNewDocumentsPreferenceKey]];
    if (!returnValue) {
        returnValue=[self baseMode];
    }
    return returnValue;
}

- (DocumentMode *)documentModeForExtension:(NSString *)anExtension {
    NSString *identifier=[I_modeIdentifiersByExtension objectForKey:anExtension];
    if (identifier) {
        return [self documentModeForIdentifier:identifier];
	} else {
        return [self baseMode];
	}
}

- (DocumentMode *)documentModeForFilename:(NSString *)aFilename {
    NSString *identifier=[I_modeIdentifiersByFilename objectForKey:aFilename];
    if (identifier) {
        return [self documentModeForIdentifier:identifier];
	} else {
        return [self baseMode];
	}
}

- (DocumentMode *)documentModeForContent:(NSString *)aString {
    NSEnumerator *regexes = [I_modeIdentifiersByRegex keyEnumerator];
    id regex;
    OGRegularExpressionMatch *match;
    while (regex = [regexes nextObject]) {
        match = [regex matchInString:aString];
        if ([match count]>0) return [self documentModeForIdentifier:[I_modeIdentifiersByRegex objectForKey:regex]];
     }

    return [self baseMode];
}


/*"Returns an NSDictionary with Key=Identifier, Value=ModeName"*/
- (NSDictionary *)availableModes {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSEnumerator *modeIdentifiers=[I_modeBundles keyEnumerator];
    NSString *identifier = nil;
    while ((identifier=[modeIdentifiers nextObject])) {
        [result setObject:[[I_modeBundles objectForKey:identifier] objectForInfoDictionaryKey:@"CFBundleName"] 
                   forKey:identifier];
    }
    return result;
}

- (NSString *)documentModeIdentifierForTag:(int)aTag {
    if (aTag>0 && aTag<[I_modeIdentifiersTagArray count]) {
        return [I_modeIdentifiersTagArray objectAtIndex:aTag];
    } else {
        return nil;
    }
}

- (BOOL)documentModeAvailableModeIdentifier:(NSString *)anIdentifier {
    return [I_modeBundles objectForKey:anIdentifier]!=nil;
}

- (int)tagForDocumentModeIdentifier:(NSString *)anIdentifier {
    return [I_modeIdentifiersTagArray indexOfObject:anIdentifier];
}


- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateDisplay:(BOOL)aFlag {

    // Remove all menu items
    int count = [aMenu numberOfItems];
    while (count) {
        [aMenu removeItemAtIndex:count - 1];
        count = [aMenu numberOfItems];
    }
    

    static NSImage *s_alternateImage=nil;
    static NSDictionary *s_menuDefaultStyleAttributes, *s_menuSmallStyleAttributes;
    if (aFlag && !s_alternateImage) {
//        s_alternateImage=[[[NSImage imageNamed:@"Mode.icns"] resizedImageWithSize:NSMakeSize(15,15)] retain];
        s_alternateImage=[[[[NSImage imageNamed:@"Mode.icns"] copy] retain] autorelease];
        [s_alternateImage setScalesWhenResized:YES];
        [s_alternateImage setSize:NSMakeSize(16,16)];
        s_menuDefaultStyleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont menuFontOfSize:0],NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
        s_menuSmallStyleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont menuFontOfSize:9.],NSFontAttributeName,[NSColor darkGrayColor], NSForegroundColorAttributeName, nil];
    }

    // Add modes
    DocumentMode *baseMode=[self baseMode];
    
    NSMutableArray *menuEntries=[NSMutableArray array];
    NSEnumerator *modeIdentifiers=[I_modeBundles keyEnumerator];
    NSString *identifier = nil;
    while ((identifier=[modeIdentifiers nextObject])) {
        if (![identifier isEqualToString:BASEMODEIDENTIFIER]) {
            NSBundle *modeBundle=[I_modeBundles objectForKey:identifier];
            NSString *additionalText=nil;
            NSString *bundlePath=[modeBundle bundlePath];
            NSMutableAttributedString *attributedTitle=[[NSMutableAttributedString alloc] initWithString:[bundlePath lastPathComponent] attributes:s_menuDefaultStyleAttributes];
            if ([bundlePath hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
                additionalText=[NSString stringWithFormat:@"SubEthaEdit %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            } else if ([bundlePath hasPrefix:@"/Library"]) {
                additionalText=@"/Library";
            } else if ([bundlePath hasPrefix:NSHomeDirectory()?NSHomeDirectory():@"/Users"]) {
                additionalText=@"~/Library";
            } else if ([bundlePath hasPrefix:NSHomeDirectory()?NSHomeDirectory():@"/Network"]) {
                additionalText=@"/Network";
            }

            [attributedTitle appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@ v%@, %@)",identifier,[[modeBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"],additionalText] attributes:s_menuSmallStyleAttributes] autorelease]];
            
            [menuEntries 
                addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:identifier,@"Identifier",[modeBundle objectForInfoDictionaryKey:@"CFBundleName"],@"Name",attributedTitle,@"AttributedTitle",nil]];
            [attributedTitle release];
        }
    }

    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[[baseMode bundle] objectForInfoDictionaryKey:@"CFBundleName"]
                                                      action:aSelector
                                               keyEquivalent:@""];
    [menuItem setTag:[self tagForDocumentModeIdentifier:BASEMODEIDENTIFIER]];
    [aMenu addItem:menuItem];
    [menuItem release];

    count=[menuEntries count];
    if (count > 0) {
        [aMenu addItem:[NSMenuItem separatorItem]];
        
        // sort
        NSArray *sortedEntries=[menuEntries sortedArrayUsingDescriptors:
                        [NSArray arrayWithObjects:
                            [[[NSSortDescriptor alloc] initWithKey:@"Name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease],
                            [[[NSSortDescriptor alloc] initWithKey:@"Identifier" ascending:YES] autorelease],nil]];
        
        int index=0;
        for (index=0;index<count;index++) {
            NSDictionary *entry=[sortedEntries objectAtIndex:index];
            NSMenuItem *menuItem =[[NSMenuItem alloc] initWithTitle:[entry objectForKey:@"Name"]
                                                             action:aSelector
                                                      keyEquivalent:@""];
            [menuItem setTag:[self tagForDocumentModeIdentifier:[entry objectForKey:@"Identifier"]]];
            if (aFlag) {
                [menuItem setAttributedTitle:[entry objectForKey:@"AttributedTitle"]];
                [menuItem setImage:s_alternateImage];
            }
            [aMenu addItem:menuItem];
            [menuItem release];
            
        }
    }
    if (aFlag) {
        [aMenu addItem:[NSMenuItem separatorItem]];
        menuItem = [[NSMenuItem alloc] 
            initWithTitle:NSLocalizedString(@"Open User Modes Folder", @"Menu item in alternate mode menu for opening the user modes folder.")
                   action:@selector(revealModesFolder:)
            keyEquivalent:@""];
        [menuItem setTag:2];
        [menuItem setTarget:self];
        [aMenu addItem:menuItem];
        [menuItem release];

        menuItem = [[NSMenuItem alloc] 
            initWithTitle:NSLocalizedString(@"Open System Modes Folder",@"Menu item in alternate mode menu for opening the system modes folder.")
                   action:@selector(revealModesFolder:)
            keyEquivalent:@""];
        [menuItem setTag:1];
        [menuItem setTarget:self];
        [aMenu addItem:menuItem];
        [menuItem release];

        menuItem = [[NSMenuItem alloc] 
            initWithTitle:NSLocalizedString(@"Open SubEthaEdit Modes Folder",@"Menu item in alternate mode menu for opening the SubEthaEdit modes folder.")
                   action:@selector(revealModesFolder:)
            keyEquivalent:@""];
        [menuItem setTag:0];
        [menuItem setTarget:self];
        [aMenu addItem:menuItem];
        [menuItem release];
    }
}

- (IBAction)revealModesFolder:(id)aSender {
    NSString *directoryString = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Modes/"];
    switch ([aSender tag]) {
        case 2: {
            NSArray *userDomainPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString *path=[userDomainPaths lastObject];
            directoryString = [path stringByAppendingPathComponent:MODEPATHCOMPONENT]; }
            break;
        case 1: {
            NSArray *systemDomainPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);
            NSString *path=[systemDomainPaths lastObject];
            directoryString = [path stringByAppendingPathComponent:MODEPATHCOMPONENT];
            }
            break;
    }
    NSLog(@"%@",directoryString);
    if (![[NSWorkspace sharedWorkspace] openFile:directoryString]) NSBeep();;
}

- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode {
    [aPopUp removeAllItems];
    NSMenu *tempMenu=[[NSMenu new] autorelease];
    [self setupMenu:tempMenu action:@selector(none:) alternateDisplay:NO];
    if (hasAutomaticMode) {
        NSMenuItem *menuItem=[[[tempMenu itemArray] objectAtIndex:0] copy];
        [menuItem setTag:[self tagForDocumentModeIdentifier:AUTOMATICMODEIDENTIFIER]];
        [menuItem setTitle:NSLocalizedString(@"Automatic Mode", @"Foo")];
        [tempMenu insertItem:menuItem atIndex:0];
        [menuItem release];
    }
    NSEnumerator *menuItems=[[tempMenu itemArray] objectEnumerator];
    NSMenuItem *item=nil;
    while ((item=[menuItems nextObject])) {
        if (![item isSeparatorItem]) {
            [aPopUp addItemWithTitle:[item title]];
            [[aPopUp lastItem] setTag:[item tag]];
            [[aPopUp lastItem] setEnabled:YES];
        }     
    }
    if (hasAutomaticMode) {
        [[aPopUp menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
    }
    [aPopUp setSelectedModeIdentifier:aModeIdentifier];
}

@end
