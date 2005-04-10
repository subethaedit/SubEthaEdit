//
//  DocumentModeManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentModeManager.h"
#import "GeneralPreferences.h"
#import "SyntaxStyle.h"

#define MODEPATHCOMPONENT @"Application Support/SubEthaEdit/Modes/"

@interface DocumentModeManager (DocumentModeManagerPrivateAdditions)
- (void)TCM_findModes;
- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateAction:(SEL)anotherSelector;
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
    [[DocumentModeManager sharedInstance] setupPopUp:self selectedModeIdentifier:[self selectedModeIdentifier] automaticMode:I_automaticMode];
}

@end


@implementation DocumentModeMenu
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)documentModeListChanged:(NSNotification *)notification {
    //int tag = [[self selectedItem] tag];
    //if (tag != 0 && tag != NoStringEncoding) defaultEncoding = tag;
    //[[EncodingManager sharedInstance] setupPopUp:self selectedEncoding:defaultEncoding withDefaultEntry:hasDefaultEntry lossyEncodings:[NSArray array]];
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateAction:I_alternateAction];
}

- (void)configureWithAction:(SEL)aSelector alternateAction:(SEL)anotherSelector {
    I_action = aSelector;
    I_alternateAction = anotherSelector;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    [[DocumentModeManager sharedInstance] setupMenu:self action:I_action alternateAction:anotherSelector];
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
					NSEnumerator *extensions = [[[bundle infoDictionary] objectForKey:@"TCMModeExtensions"] objectEnumerator];
					NSString *extension = nil;
					while ((extension = [extensions nextObject])) {
						[I_modeIdentifiersByExtension setObject:[bundle bundleIdentifier] forKey:extension];
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


/*"Returns an NSDictionary with Key=Identifier, Value=ModeName"*/
- (NSDictionary *)availableModes {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSEnumerator *modeIdentifiers=[I_modeBundles keyEnumerator];
    NSString *identifier = nil;
    while ((identifier=[modeIdentifiers nextObject])) {
        [result setObject:[[[I_modeBundles objectForKey:identifier] localizedInfoDictionary] objectForKey:@"CFBundleName"] 
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

- (int)tagForDocumentModeIdentifier:(NSString *)anIdentifier {
    return [I_modeIdentifiersTagArray indexOfObject:anIdentifier];
}


- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateAction:(SEL)anotherSelector {

    // Remove all menu items
    int count = [aMenu numberOfItems];
    while (count) {
        [aMenu removeItemAtIndex:count - 1];
        count = [aMenu numberOfItems];
    }
    

    static NSImage *s_alternateImage=nil;
    static NSDictionary *s_menuDefaultStyleAttributes, *s_menuSmallStyleAttributes;
    if (anotherSelector && !s_alternateImage) {
//        s_alternateImage=[[[NSImage imageNamed:@"Mode.icns"] resizedImageWithSize:NSMakeSize(15,15)] retain];
        s_alternateImage=[[[[NSImage imageNamed:@"Mode.icns"] copy] retain] autorelease];
        [s_alternateImage setScalesWhenResized:YES];
        [s_alternateImage setSize:NSMakeSize(16,16)];
        s_alternateImage=[[s_alternateImage resizedImageWithSize:NSMakeSize(16,16)] retain];
        [s_alternateImage setScalesWhenResized:NO];
        [s_alternateImage setSize:NSMakeSize(15,15)];
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
            NSString *bundlePath=[[I_modeBundles objectForKey:identifier] bundlePath];
            NSString *additionalText=nil;
            NSMutableAttributedString *attributedTitle=[[NSMutableAttributedString alloc] initWithString:[[bundlePath lastPathComponent] stringByDeletingPathExtension] attributes:s_menuDefaultStyleAttributes];
            if ([bundlePath hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
                additionalText=[NSString stringWithFormat:@" (SEE %@)",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            } else if ([bundlePath hasPrefix:@"/Library"]) {
                additionalText=@" (/Library)";
            } else if ([bundlePath hasPrefix:NSHomeDirectory()?NSHomeDirectory():@"/Users"]) {
                additionalText=@" (~/Library)";
            }
            
            if (additionalText) {
                [attributedTitle appendAttributedString:[[[NSAttributedString alloc] initWithString:additionalText attributes:s_menuSmallStyleAttributes] autorelease]];
            }
            
            [menuEntries 
                addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:identifier,@"Identifier",[[[I_modeBundles objectForKey:identifier] localizedInfoDictionary] objectForKey:@"CFBundleName"],@"Name",[attributedTitle autorelease],@"AlternateTitle",nil]];
        }
    }

    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[[[baseMode bundle] localizedInfoDictionary] objectForKey:@"CFBundleName"]
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
            [aMenu addItem:menuItem];
            [menuItem release];
            
            if (anotherSelector) {
                menuItem =[[NSMenuItem alloc] initWithTitle:[[entry objectForKey:@"AlternateTitle"] string]
                                                                 action:anotherSelector
                                                          keyEquivalent:@""];
                [menuItem setTag:[self tagForDocumentModeIdentifier:[entry objectForKey:@"Identifier"]]];
                [menuItem setAlternate:YES];
                [menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
                [menuItem setImage:s_alternateImage];
                [menuItem setAttributedTitle:[entry objectForKey:@"AlternateTitle"]];
                [aMenu addItem:menuItem];
                [menuItem release];
            }
        }
    }
}

- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode {
    [aPopUp removeAllItems];
    NSMenu *tempMenu=[[NSMenu new] autorelease];
    [self setupMenu:tempMenu action:@selector(none:) alternateAction:nil];
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
