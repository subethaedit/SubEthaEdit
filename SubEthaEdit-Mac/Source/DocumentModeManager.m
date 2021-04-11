//  DocumentModeManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.

#import "ModeSettings.h"
#import "DocumentModeManager.h"
#import "GeneralPreferences.h"
#import "SyntaxStyle.h"
#import "SyntaxDefinition.h"
#import "PlainTextDocument.h"
#import <OgreKit/OgreKit.h>
#import "LMPTOMLSerialization.h"
#import "SEEDocumentModePackage.h"

@interface DocumentModeManager () {
    NSRecursiveLock *I_documentModesByIdentifierLock; // (ifc - experimental locking for thread safety... TCM are putting in a real fix)

    NSMutableArray      *I_modeIdentifiersTagArray;
    
    // style sheet management
    NSMutableDictionary *I_styleSheetPathsByName;
    NSMutableDictionary *I_styleSheetsByName;
}
@property (nonatomic, strong) NSMutableDictionary<NSString *, SEEDocumentModePackage *> *modePackages;
@property (nonatomic, strong) NSMutableDictionary<NSString *, DocumentMode *> *modesByIdentifier;
@property (nonatomic, strong) NSMutableDictionary<NSString *, DocumentMode *> *modesByName;
@property (nonatomic, strong, readwrite) NSDictionary *changedScopeNameDict;
@property (nonatomic, strong) NSArray<NSURL *> *orderedModeSearchPathURLs;
@property (nonatomic, strong) NSArray<NSURL *> *orderedStyleSearchPathURLs;
@end

@interface DocumentModeManager (DocumentModeManagerPrivateAdditions)
- (void)TCM_findModes;
- (void)TCM_findStyles;
- (NSMutableArray *)reloadPrecedences;
- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateDisplay:(BOOL)aFlag;
- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode;
- (NSMutableArray *)modePrecedenceArray;
- (void)setModePrecedenceArray:(NSMutableArray *)anArray;
- (NSString *)pathForWritingStyleSheetWithName:(NSString *)aStyleSheetName;
@end

#pragma mark -

@interface DocumentModeManager ()
@property (nonatomic, strong) NSArray *allPathExtensions;
@end

@implementation DocumentModeManager
@synthesize changedScopeNameDict;

+ (instancetype)sharedInstance {
    return TCM_SINGLETON(DocumentModeManager);
}

+ (DocumentMode *)baseMode {
    return [[DocumentModeManager sharedInstance] baseMode];
}

+ (NSString *)defaultStyleSheetName {
    if ([NSApp SEE_effectiveAppearanceIsDark]) {
        return @"SubEthaEdit Dark";
    } else {
        return @"SubEthaEdit Bright";
    }
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

static void CommonInit(DocumentModeManager *self) {
    self->_modePackages = [NSMutableDictionary new];
    
    self->I_styleSheetPathsByName = [NSMutableDictionary new];
    self->I_styleSheetsByName     = [NSMutableDictionary new];
    
    self->_modesByIdentifier = [NSMutableDictionary new];
    self->_modesByName       = [NSMutableDictionary new];
    self->I_documentModesByIdentifierLock = [NSRecursiveLock new]; // ifc - experimental locking... awaiting real fix from TCM
    self->I_modeIdentifiersTagArray   = [@[
        @"-",
        AUTOMATICMODEIDENTIFIER,
        BASEMODEIDENTIFIER,
    ] mutableCopy];

    // Preference Handling
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#define BUNDLE_MODE_FOLDER_NAME @"Modes"
#define LIBRARY_MODE_FOLDER_NAME @"Modes"

#define BUNDLE_STYLE_FOLDER_NAME @"Modes/Styles"
#define LIBRARY_STYLE_FOLDER_NAME @"Styles"

/// Default App Singleton initializer
- (instancetype)init {
    if ((self = [super init])) {
        CommonInit(self);
        [self TCM_loadScopeNameChanges];

        [self ensureUserApplicationSupportDirectory];

        NSArray *allDomainsURLs = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSAllDomainsMask];
        _orderedModeSearchPathURLs = ({
            NSArray *urls = [ASTMap(allDomainsURLs, ^NSURL *(NSURL *url) {
                return [DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:url subDirectoryName:LIBRARY_MODE_FOLDER_NAME];
            }) arrayByAddingObject:[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:BUNDLE_MODE_FOLDER_NAME]];
            urls;
        });

        _orderedStyleSearchPathURLs = ({
            NSArray *urls = [ASTMap(allDomainsURLs, ^NSURL *(NSURL *url) {
                return [DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:url subDirectoryName:LIBRARY_STYLE_FOLDER_NAME];
            }) arrayByAddingObject:[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:BUNDLE_STYLE_FOLDER_NAME]];
            urls;
        });
        
        [self TCM_findStyles];
        
        [self reloadDocumentModes];
    }
    return self;
}

/// Custom

#pragma mark - Directories

+ (NSURL *)userApplicationSupportDirectory {
    NSArray *possibleURLs = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *result = possibleURLs.firstObject;
	return result;
}

+ (NSURL *)URLWithAddedBundleIdentifierDirectoryForURL:(NSURL *)anURL subDirectoryName:(NSString *)aSubDirectory {
	NSURL *url;
    if (anURL) {
        NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        url = [anURL URLByAppendingPathComponent:appBundleID];
		if (aSubDirectory) {
			url = [url URLByAppendingPathComponent:aSubDirectory];
		}
    }
	return url;
}

- (void)ensureUserApplicationSupportDirectory {
	NSURL *applicationSupport = [DocumentModeManager userApplicationSupportDirectory];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *fullPathStyles = [[DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:applicationSupport subDirectoryName:LIBRARY_STYLE_FOLDER_NAME] path];
	if (![fm fileExistsAtPath:fullPathStyles isDirectory:NULL]) {
		[fm createDirectoryAtPath:fullPathStyles withIntermediateDirectories:YES attributes:nil error:nil];
    }
	
	NSString *fullPathModes = [[DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:applicationSupport subDirectoryName:LIBRARY_MODE_FOLDER_NAME] path];
	if (![fm fileExistsAtPath:fullPathModes isDirectory:NULL]) {
		[fm createDirectoryAtPath:fullPathModes withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Stuff with Precedences
- (void)revalidatePrecedences {
    // Check for overriden Rules

    NSMutableArray *rulesSoFar = [NSMutableArray array];
    
    NSEnumerator *modes = [[self modePrecedenceArray] objectEnumerator];
    id mode;
    while ((mode = [modes nextObject])) {
        
        NSEnumerator *rules = [[mode objectForKey:@"Rules"] objectEnumerator];
        id rule;
        while ((rule = [rules nextObject])) {
            BOOL isOverridden = NO;
            NSMutableDictionary *ruleCopy = [rule mutableCopy];
            [ruleCopy setObject:[mode objectForKey:@"Name"] forKey:@"FromMode"];

            int typeRule = [[rule objectForKey:@"TypeIdentifier"] intValue];
            NSString *stringRule = [rule objectForKey:@"String"];
            
            // Check if overridden
            NSEnumerator *overridingRules = [rulesSoFar objectEnumerator];
            id override;
            while ((override = [overridingRules nextObject])) {
                int typeOverride = [[override objectForKey:@"TypeIdentifier"] intValue];
                NSString *stringOverride = [override objectForKey:@"String"];
                
                BOOL simpleOverride = ((typeOverride==typeRule) && ([stringRule isEqualToString:stringOverride]));
                BOOL caseOverride = (((typeRule==3)&&(typeOverride==0)) && ([[stringRule uppercaseString] isEqualToString:[stringOverride uppercaseString]]));
                
                if (simpleOverride||caseOverride) {
                    [rule setObject:@YES forKey:@"Overridden"];
                    [rule setObject:[NSString stringWithFormat:NSLocalizedString(@"Overriden by trigger in %@ mode",@"Mode Precedence Overriden Tooltip"), [override objectForKey:@"FromMode"]] forKey:@"OverriddenTooltip"];
                    isOverridden = YES;
                }   
                
            }
            
            if (!isOverridden) {
                [rule setObject:@NO forKey:@"Overridden"];
                [rule setObject:@"" forKey:@"OverriddenTooltip"];
            }
            
            if ([[rule objectForKey:@"Enabled"] boolValue]) [rulesSoFar addObject:ruleCopy];
        }
        
    }
}

- (NSMutableArray *)reloadPrecedences {
    
	NSMutableSet *allPathExtensionSet = [NSMutableSet set];
	
    NSArray *oldPrecedenceArray;
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    oldPrecedenceArray = [defaults objectForKey:@"ModePrecedences"];
    
    NSMutableArray *precendenceArray = [NSMutableArray array];
    
    
    NSMutableArray *modeOrder;
    if (oldPrecedenceArray) {
        //Recover order
        modeOrder = [NSMutableArray array];
        id oldMode;
        for (oldMode in oldPrecedenceArray) {
            if ([oldMode respondsToSelector:@selector(objectForKey:)]) {
                if ([oldMode objectForKey:@"Identifier"]) {
                    [modeOrder addObject:[oldMode objectForKey:@"Identifier"]];
                }
            } 
        }
    } else {
        // Default internal order
        modeOrder = [@[@"SEEMode.PHP-HTML",
                       @"SEEMode.ERB",
                       @"SEEMode.Ruby",
                       @"SEEMode.bash",
                       @"SEEMode.Objective-C",
                       @"SEEMode.C++",
                       @"SEEMode.C",
                       @"SEEMode.Diff",
                       @"SEEMode.HTML",
                       @"SEEMode.CSS",
                       @"SEEMode.Javascript",
                       @"SEEMode.SDEF",
                       @"SEEMode.XML",
                       @"SEEMode.Perl",
                       @"SEEMode.Pascal",
                       @"SEEMode.Lua",
                       @"SEEMode.AppleScript",
                       @"SEEMode.ActionScript",
                       @"SEEMode.LaTeX",
                       @"SEEMode.Java",
                       @"SEEMode.Python",
                       @"SEEMode.SQL",
                       @"SEEMode.Conference",
                       @"SEEMode.LassoScript-HTML",
                       @"SEEMode.Coldfusion"] mutableCopy];
    }
    
    NSInteger i;
    for(i=0;i<[modeOrder count];i++) {
        [precendenceArray addObject:[NSMutableDictionary dictionary]];
    }

    for (SEEDocumentModePackage *package in _modePackages.objectEnumerator) {
        
        ModeSettings *modeSettings = [package modeSettings];
		
        NSMutableArray *ruleArray = [NSMutableArray array];
        if (modeSettings) {
			NSMutableDictionary *modeDictionary = [NSMutableDictionary dictionary];
            NSEnumerator *extensions = [[modeSettings recognizedExtensions] objectEnumerator];
            NSEnumerator *casesensitiveExtensions = [[modeSettings recognizedCasesensitveExtensions] objectEnumerator];
            NSEnumerator *filenames = [[modeSettings recognizedFilenames] objectEnumerator];
            NSEnumerator *regexes = [[modeSettings recognizedRegexes] objectEnumerator];

            i = [modeOrder indexOfObject:package.modeIdentifier];
            if (i!=NSNotFound) {
                [precendenceArray replaceObjectAtIndex:i withObject:modeDictionary];
            } else [precendenceArray addObject:modeDictionary];

            [modeDictionary setObject:package.modeIdentifier forKey:@"Identifier"];
            [modeDictionary setObject:package.modeName forKey:@"Name"];
            [modeDictionary setObject:package.modeVersion forKey:@"Version"];
            NSString *packagePath = package.packageURL.path;
            NSString *location = NSLocalizedString(@"User Library", @"Location: User Library");
            if ([packagePath hasPrefix:@"/Library"]) location = NSLocalizedString(@"System Library", @"Location: System Library");
            if ([packagePath hasPrefix:@"/Network/Library"]) location = NSLocalizedString(@"Network Library", @"Location: Network Library");
            if ([packagePath hasPrefix:[[NSBundle mainBundle] bundlePath]]) location = NSLocalizedString(@"Application", @"Location: Application");
            [modeDictionary setObject:location forKey:@"Location"];

            [modeDictionary setObject:ruleArray forKey:@"Rules"];

			NSString *extension;
			NSString *casesensitiveExtension;
			NSString *filename;
			NSString *regex;

			while ((extension = [extensions nextObject])) {
				[ruleArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									  extension,@"String",
									  @YES,@"Enabled",
									  [NSNumber numberWithInt:0],@"TypeIdentifier",
									  @NO,@"Overridden",
									  @"",@"OverriddenTooltip",
									  @YES,@"ModeRule",
									  nil]];
				[allPathExtensionSet addObject:extension];
			}

			while ((casesensitiveExtension = [casesensitiveExtensions nextObject])) {
				[ruleArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									  casesensitiveExtension,@"String",
									  @YES,@"Enabled",
									  [NSNumber numberWithInt:3],@"TypeIdentifier",
									  @NO,@"Overridden",
									  @"",@"OverriddenTooltip",
									  @YES,@"ModeRule",
									  nil]];
				[allPathExtensionSet addObject:casesensitiveExtension];
			}

			while ((filename = [filenames nextObject])) {
				[ruleArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									  filename,@"String",
									  @YES,@"Enabled",
									  [NSNumber numberWithInt:1],@"TypeIdentifier",
									  @NO,@"Overridden",
									  @"",@"OverriddenTooltip",
									  @YES,@"ModeRule",
									  nil]];
			}

			while ((regex = [regexes nextObject])) {
				if ([OGRegularExpression isValidExpressionString:regex]) {
					[ruleArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  regex,@"String",
										  @YES,@"Enabled",
										  [NSNumber numberWithInt:2],@"TypeIdentifier",
										  @NO,@"Overridden",
										  @"",@"OverriddenTooltip",
										  @YES,@"ModeRule",
										  nil]];
				}
			}
		}

        // Enumerate rules from defaults to add user added rules back in
        for (NSDictionary *oldMode in oldPrecedenceArray) {
            if (![[oldMode objectForKey:@"Identifier"] isEqualToString:package.modeIdentifier]) continue;
            NSEnumerator *oldRules = [[oldMode objectForKey:@"Rules"] objectEnumerator];
            NSDictionary *oldRule;
            while ((oldRule = [oldRules nextObject])) {
                if (![[oldRule objectForKey:@"ModeRule"] boolValue]) {
                    [ruleArray addObject:[oldRule mutableCopy]];
                }
                
                NSEnumerator *newRulesEnumerator = [ruleArray objectEnumerator];
                id newRule;
                while ((newRule = [newRulesEnumerator nextObject])) {
                    if (([[oldRule objectForKey:@"String"] isEqualToString:[newRule objectForKey:@"String"]]) &&
                        ([[oldRule objectForKey:@"TypeIdentifier"] intValue] == [[newRule objectForKey:@"TypeIdentifier"] intValue]) &&
                        [oldRule objectForKey:@"Enabled"]) {
                        [newRule setObject:[oldRule objectForKey:@"Enabled"] forKey:@"Enabled"];
                    }
                }
            }
        }
    }
    
	for (i=[precendenceArray count]-1;i>=0;i--) {
		if (![[precendenceArray objectAtIndex:i] objectForKey:@"Identifier"]) [precendenceArray removeObjectAtIndex:i];
	}
	
    [defaults setObject:precendenceArray forKey:@"ModePrecedences"];
	
	// add all the types from the document class
    NSMutableSet *typeSet = [NSMutableSet setWithArray:[[[NSDocumentController sharedDocumentController] documentClassForType:[[NSDocumentController sharedDocumentController] defaultType]] writableTypes] ?: @[]];
	[typeSet removeObject:kSEETypeSEEText];
	[typeSet removeObject:kSEETypeSEEMode];
	for (NSString *type in typeSet) {
		NSArray *extensions = [DocumentModeManager allTagsOfTagClass:kUTTagClassFilenameExtension forUTI:type];
		//		NSLog(@"%s %@: %@",__FUNCTION__,type, extensions);
		[allPathExtensionSet addObjectsFromArray:extensions];
	}
	
	self.allPathExtensions = [[allPathExtensionSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    return precendenceArray;
}

+ (NSArray *)allTagsOfTagClass:(CFStringRef)aTagClass forUTI:(NSString *)aType {
    NSArray *result;
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

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:[self modePrecedenceArray] forKey:@"ModePrecedences"];
}

#pragma mark - Stuff with Styles
- (NSString *)pathForWritingStyleSheetWithName:(NSString *)aStyleSheetName {
	NSString *fullPath = [self.customStyleSheetFolderURL path];
    return [[fullPath stringByAppendingPathComponent:aStyleSheetName] stringByAppendingPathExtension:SEEStyleSheetFileExtension];
}

- (NSURL *)customStyleSheetFolderURL {
	[self ensureUserApplicationSupportDirectory];
	NSURL *folderURL = [DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:[DocumentModeManager userApplicationSupportDirectory] subDirectoryName:LIBRARY_STYLE_FOLDER_NAME];
	return folderURL;
}

- (void)TCM_loadScopeNameChanges {
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"Modes/ScopeChanges" withExtension:@"json"];
	NSData *data = [NSData dataWithContentsOfURL:url];
	NSError *error;
	NSDictionary *renamedScopesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	if (renamedScopesDict && !error) {
		[self setChangedScopeNameDict:renamedScopesDict];
	}
}

- (void)TCM_findStyles {
    for (NSURL *url in _orderedStyleSearchPathURLs) {
        NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
        for (NSURL *fileURL in dirEnumerator) {
            if ([[fileURL pathExtension] isEqualToString:SEEStyleSheetFileExtension]) {
	            [I_styleSheetPathsByName setObject:[fileURL path] forKey:[[fileURL lastPathComponent] stringByDeletingPathExtension]];
            } 
        } 
    }
//    NSLog(@"%s %@",__FUNCTION__, I_styleSheetPathsByName);
}

- (SEEStyleSheet *)styleSheetForName:(NSString *)aStyleSheetName {
	SEEStyleSheet *result = [I_styleSheetsByName objectForKey:aStyleSheetName];
	if (!result) {
		NSString *path = [I_styleSheetPathsByName objectForKey:aStyleSheetName];
		if (path) {
			result = [SEEStyleSheet new];
			result.styleSheetName = aStyleSheetName;
			NSURL *url = [NSURL fileURLWithPath:path];
			[result importStyleSheetAtPath:url];
			
			// check for coda changes - if coda changes -> update and save
			NSArray *changes = [result updateScopesWithChangesDictionary:self.changedScopeNameDict];
			if (changes) {
				// check if we can write files here
				if ([[NSFileManager defaultManager] isWritableFileAtPath:path]) {
					[result appendStyleSheetSnippetsForScopes:changes toSheetAtURL:url];

				} else {
					// if not: safe a copy to the application folder
					NSString *changedPath = [self pathForWritingStyleSheetWithName:aStyleSheetName];
					NSURL *changedURL = [NSURL fileURLWithPath:changedPath];

					NSError *readingError;
					NSError *writingError;

					NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&readingError];
					[data writeToURL:changedURL options:0 error:&writingError];
					
					if (!readingError && !writingError) {
						[result appendStyleSheetSnippetsForScopes:changes toSheetAtURL:changedURL];
					}
				}
			}

			[result markCurrentStateAsPersistent];
			[I_styleSheetsByName setObject:result forKey:aStyleSheetName];
		}
	}
	return result;
}

- (NSArray *)allStyleSheetNames {
	return [[I_styleSheetPathsByName allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)reloadAllStyles {
	[I_styleSheetsByName removeAllObjects];
	[I_styleSheetPathsByName removeAllObjects];
	[self TCM_findStyles];
	for (DocumentMode *mode in self.allLoadedDocumentModes) {
		[mode reloadStyleSheetSettings];
	}
	// trigger update in open documents
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StyleSheetsDidChange" object:self];
}

- (SEEStyleSheet *)duplicateStyleSheet:(SEEStyleSheet *)aStyleSheet {
	NSString *sheetName = [[aStyleSheet styleSheetName] stringByAppendingString:@" 2"];
	NSString *newPath = [self pathForWritingStyleSheetWithName:sheetName];
	int i = 3;
	while ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
		sheetName = [NSString stringWithFormat:@"%@ %d", [aStyleSheet styleSheetName], i];
		newPath = [self pathForWritingStyleSheetWithName:sheetName];
		i++;
	}
	[aStyleSheet exportStyleSheetToPath:[NSURL fileURLWithPath:newPath]];
	// this looses all the comments etc in the style sheet!
	[self TCM_findStyles];
	return [self styleSheetForName:sheetName];
}

- (void)saveStyleSheet:(SEEStyleSheet *)aStyleSheet {
	NSString *newPath = [self pathForWritingStyleSheetWithName:[aStyleSheet styleSheetName]];
	// this looses all the comments etc in the style sheet!
	[aStyleSheet exportStyleSheetToPath:[NSURL fileURLWithPath:newPath]];
	[I_styleSheetPathsByName setObject:newPath forKey:[aStyleSheet styleSheetName]];
	[aStyleSheet markCurrentStateAsPersistent];
}

- (void)revealStyleSheetInFinder:(SEEStyleSheet *)aStyleSheet {
	NSString *filePath = [I_styleSheetPathsByName objectForKey:[aStyleSheet styleSheetName]];
	NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:BUNDLE_STYLE_FOLDER_NAME];
	NSString *shortenedFilePath = [filePath stringByDeletingLastPathComponent];
	BOOL styleSheetIsBundleSheet = [bundlePath isEqualToString:shortenedFilePath];
	if (styleSheetIsBundleSheet) { // copy the style sheet to application support and open there
		[self saveStyleSheet:aStyleSheet]; // saves to user application support
		filePath = [I_styleSheetPathsByName objectForKey:[aStyleSheet styleSheetName]];
	}
	[[NSWorkspace sharedWorkspace] selectFile:filePath inFileViewerRootedAtPath:[filePath stringByDeletingLastPathComponent]];
}

#pragma mark - Stuff with modes
- (NSURL *)urlForWritingModeWithName:(NSString *)aModeName {
	NSString *fullPath = [self pathForWritingModeWithName:aModeName];
	NSURL *result = [NSURL fileURLWithPath:fullPath];
	return result;
}

- (NSString *)pathForWritingModeWithName:(NSString *)aModeName {
	[self ensureUserApplicationSupportDirectory];
	NSString *modeFolderPath = [[DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:[DocumentModeManager userApplicationSupportDirectory] subDirectoryName:LIBRARY_MODE_FOLDER_NAME] path];
	NSString *fullPath = [[modeFolderPath stringByAppendingPathComponent:aModeName] stringByAppendingPathExtension:MODE_EXTENSION];
    return fullPath;
}

- (NSString *)pathForWritingMode:(DocumentMode *)aMode {
	NSString *result = [self pathForWritingModeWithName:[aMode displayName]];
	return result;
}

- (void)revealModeInFinder:(DocumentMode *)aMode jumpIntoContentFolder:(BOOL)aJumpIntoContentFolder {
	NSBundle *modeBundle = [aMode bundle];
	NSString *modeBundlePath = [modeBundle bundlePath];

	BOOL modeIsInBundle = [modeBundlePath hasPrefix:[[NSBundle mainBundle] bundlePath]];
	if (modeIsInBundle) { // copy the mode bundle to application support and open there
		NSError *error;
		BOOL success = [[NSFileManager defaultManager] copyItemAtPath:modeBundlePath toPath:[self pathForWritingMode:aMode] error:&error];
		if(success != YES) {
			NSLog(@"Error: %@", error);
		}
		[self reloadDocumentModes:self]; // only reload if you actually change something about the mode
		modeBundle = [[self documentModeForIdentifier:[aMode documentModeIdentifier]] bundle]; // make sure the new bundle is used in case of copying
	}

	NSString *pathToOpen = aJumpIntoContentFolder? [modeBundle resourcePath] : [modeBundle bundlePath];
	[[NSWorkspace sharedWorkspace] selectFile:pathToOpen inFileViewerRootedAtPath:[pathToOpen stringByDeletingLastPathComponent]];
}

- (void)showIncompatibleModeErrorForBundle:(NSBundle *)aBundle {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert setMessageText:NSLocalizedString(@"Mode not compatible",@"Mode requires newer engine title")];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The mode '%@' was written for a newer version of SubEthaEngine and cannot be used with this application.", @"Mode requires newer engine Informative Text"), [aBundle bundleIdentifier]]];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
    [alert addButtonWithTitle:NSLocalizedString(@"Reveal in Finder",@"Reveal in Finder - menu entry")];
    [alert setDelegate:self];
    
    int returnCode = [alert runModal];
    
    if (returnCode == NSAlertSecondButtonReturn) {
        // Show mode in Finder
		NSString *bundlePath = [aBundle bundlePath];
		if (bundlePath) {
			[[NSWorkspace sharedWorkspace] selectFile:bundlePath inFileViewerRootedAtPath:[bundlePath stringByDeletingLastPathComponent]];
		}
    }
}

- (void)TCM_findModes {
    for (NSURL *url in _orderedModeSearchPathURLs) {
        NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:NULL];
        for (NSURL *fileURL in dirEnumerator) {
            NSError *error;
            // TODO: make package initialisation report errors that make it easy to decide if we want to report them
            SEEDocumentModePackage *package = [[SEEDocumentModePackage alloc] initWithURL:fileURL error:&error];
            
            if (package) {
                NSString *modeIdentifier = package.modeIdentifier;
                _modePackages[modeIdentifier] = package;
                if (![I_modeIdentifiersTagArray containsObject:modeIdentifier]) {
                    [I_modeIdentifiersTagArray addObject:modeIdentifier];
                }
            } else {
                // TODO: show error for incomaptible modes
                NSLog(@"%s could not create package at %@ error:%@", __PRETTY_FUNCTION__, fileURL, error);
            }
        }
    }
}

- (void)reloadDocumentModes {
    // must be here otherwise we might deadlock
    [I_documentModesByIdentifierLock lock]; // ifc - experimental
    
    // reload all modes
    [_modePackages       removeAllObjects];
    [_modesByIdentifier  removeAllObjects];
    [_modesByName         removeAllObjects];
    [self TCM_findModes];
    [I_documentModesByIdentifierLock unlock]; // ifc - experimental

    [NSOperationQueue TCM_performBlockOnMainQueue:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DocumentModeListChanged" object:self];
    } afterDelay:0.0];
    
    [self setModePrecedenceArray:[self reloadPrecedences]];
    [self revalidatePrecedences];

}

- (IBAction)reloadDocumentModes:(id)aSender {
    // write all preferences
    [[_modesByIdentifier allValues] makeObjectsPerformSelector:@selector(writeDefaults)];
    [[NSUserDefaults standardUserDefaults] setObject:[self modePrecedenceArray] forKey:@"ModePrecedences"];

    // actually reload
    [self reloadDocumentModes];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DocumentModeManager, FoundModeBundles:%@",[_modePackages description]];
}

- (DocumentMode *)documentModeForName:(NSString *)aName {
	DocumentMode *mode = [_modesByName objectForKey:aName];
	
	if (!mode) {
        NSString *identifier = [aName hasPrefix:@"SEEMode."] ? aName : [NSString stringWithFormat:@"SEEMode.%@", aName];
		mode = [self documentModeForIdentifier:identifier];
		
		if (!mode) {
			for (NSString *key in self.availableModes) {
				if ([identifier caseInsensitiveCompare:key] == NSOrderedSame) {
					mode = [self documentModeForIdentifier:key];
					break;
				}
			}
		}
        
        if (mode) {
			_modesByName[aName] = mode;
        }
	}
    
	return mode;
}

- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier {
    // if not on main thread bounce to main thread so mode loading only happens there.
    // TODO: replace with a proper semantic, either make it require main thread or make it thread safe
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(documentModeForIdentifier:) withObject:anIdentifier waitUntilDone:YES];
    }
    
	[I_documentModesByIdentifierLock lock]; // ifc - experimental
    DocumentMode *result;
    {
        SEEDocumentModePackage *package = [_modePackages objectForKey:anIdentifier];
        if (package) {
            result = _modesByIdentifier[anIdentifier];
            if (!result) {
                result = [[DocumentMode alloc] initWithPackage:package];
                if (result) {
                    // important that we do this first, so it is already in the dictionary when resolving the imported modes
                    _modesByIdentifier[anIdentifier] = result;
                    
                    // Load all depended modes
                    for (NSString *importedModeName in result.syntaxDefinition.importedModes) {
                        [self documentModeForName:importedModeName];
                    }
                }
            }
        }
    }
    [I_documentModesByIdentifierLock unlock]; // ifc - experimental
    return result;

}

- (NSArray *)allLoadedDocumentModes {
	return [_modesByIdentifier allValues];
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

- (DocumentMode *)documentModeForPath:(NSString *)path withContentData:(NSData *)content {
    // Convert data to ASCII, we don't know encoding yet at this point
    // FIXME Don't forget to handle UTF16/32
	DocumentMode *mode;
	@autoreleasepool {
		unsigned maxLength = [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
		NSString *contentString = [[NSString alloc] initWithBytesNoCopy:(void *)[content bytes] length:MIN([content length],maxLength) encoding:NSMacOSRomanStringEncoding freeWhenDone:NO];
		mode = [self documentModeForPath:path withContentString:contentString];
	}
    return mode;
}

- (DocumentMode *)documentModeForPath:(NSString *)path withContentString:(NSString *)contentString {
    NSString *filename = [path lastPathComponent];
    NSString *extension = [path pathExtension];
    NSEnumerator *modeEnumerator = [[self modePrecedenceArray] objectEnumerator];
    NSMutableDictionary *mode;
    while ((mode = [modeEnumerator nextObject])) {
		@autoreleasepool {
			NSEnumerator *ruleEnumerator = [[mode objectForKey:@"Rules"] objectEnumerator];
			NSMutableDictionary *rule;
			while ((rule = [ruleEnumerator nextObject])) {
				int ruleType = [[rule objectForKey:@"TypeIdentifier"] intValue];
				NSString *ruleString = [rule objectForKey:@"String"];
				
				if (ruleType == 0) { // Case insensitive extension
					if ([[ruleString uppercaseString] isEqualToString:[extension uppercaseString]]) return [self documentModeForIdentifier:[mode objectForKey:@"Identifier"]];
				}
				if (ruleType == 3) { // Case sensitive extension
					if ([ruleString isEqualToString:extension]) return [self documentModeForIdentifier:[mode objectForKey:@"Identifier"]];
				}
				if (ruleType == 1) {
					if ([ruleString isEqualToString:filename]) return [self documentModeForIdentifier:[mode objectForKey:@"Identifier"]];
				}
				if (ruleType == 2 && contentString) {
					if ([OGRegularExpression isValidExpressionString:ruleString]) {
						BOOL didMatch = NO;
						OGRegularExpressionMatch *match;
						OGRegularExpression *regex = [[OGRegularExpression alloc] initWithString:ruleString options:OgreFindNotEmptyOption|OgreMultilineOption];
						match = [regex matchInString:contentString];
						didMatch = [match count]>0;
						if (didMatch) return [self documentModeForIdentifier:[mode objectForKey:@"Identifier"]];
					} else {
						NSAlert *alert = [[NSAlert alloc] init];
						[alert setAlertStyle:NSAlertStyleWarning];
						[alert setMessageText:NSLocalizedString(@"Trigger not a regular expression",@"Trigger not a regular expression Title")];
						[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The trigger '%@' of the mode '%@' is not a valid regular expression and was ignored.", @"Trigger not a regular expression Informative Text"), ruleString, [mode objectForKey:@"Identifier"]]];
						[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
						[alert runModal];
					}
				}
			}
		}
    }

    return [self baseMode];
}


/*"Returns an NSDictionary with Key=Identifier, Value=ModeName"*/
- (NSDictionary *)availableModes {
    NSDictionary *result = ASTMap(_modePackages, ^id(SEEDocumentModePackage *package) {
        return package.modeName;
    });

    return result;
}

- (NSString *)documentModeIdentifierForTag:(NSInteger)aTag {
    if (aTag>0 && aTag<[I_modeIdentifiersTagArray count]) {
        return [I_modeIdentifiersTagArray objectAtIndex:aTag];
    } else {
        return nil;
    }
}

- (BOOL)documentModeAvailableModeIdentifier:(NSString *)anIdentifier {
    return [_modePackages objectForKey:anIdentifier]!=nil;
}

- (NSInteger)tagForDocumentModeIdentifier:(NSString *)anIdentifier {
    return [I_modeIdentifiersTagArray indexOfObject:anIdentifier];
}

#pragma mark
#define MENU_ITEM_TAG_BUNDLE_MODE_FOLDER 0
#define MENU_ITEM_TAG_USER_MODE_FOLDER 2
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
        s_alternateImage=[[NSImage imageNamed:@"file-mode"] copy];
        [s_alternateImage setSize:NSMakeSize(16,16)];
        s_menuDefaultStyleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont menuFontOfSize:0],NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
        s_menuSmallStyleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont menuFontOfSize:9.],NSFontAttributeName,[NSColor darkGrayColor], NSForegroundColorAttributeName, nil];
    }

    // Add modes
    DocumentMode *baseMode=[self baseMode];
    
    NSMutableArray *menuEntries=[NSMutableArray array];
    NSEnumerator *modeIdentifiers=[_modePackages keyEnumerator];
    NSString *identifier;
    while ((identifier=[modeIdentifiers nextObject])) {
        if (![identifier isEqualToString:BASEMODEIDENTIFIER]) {
            SEEDocumentModePackage *package = [_modePackages objectForKey:identifier];
            NSString *additionalText=nil;
            NSString *bundlePath=package.packageURL.path;
            NSMutableAttributedString *attributedTitle=[[NSMutableAttributedString alloc] initWithString:package.modeName attributes:s_menuDefaultStyleAttributes];
            if ([bundlePath hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
                additionalText=[NSString stringWithFormat:@"SubEthaEdit %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            } else if ([bundlePath hasPrefix:@"/Library"]) {
                additionalText=@"/Library";
            } else if ([bundlePath hasPrefix:NSHomeDirectory()?NSHomeDirectory():@"/Users"]) {
                additionalText=@"Application Support";
            } else if ([bundlePath hasPrefix:NSHomeDirectory()?NSHomeDirectory():@"/Network"]) {
                additionalText=@"/Network";
            }

            [attributedTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@ v%@, %@)",identifier,package.modeVersion,additionalText] attributes:s_menuSmallStyleAttributes]];
            
            [menuEntries 
                addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:identifier,@"Identifier",package.modeName,@"Name",attributedTitle,@"AttributedTitle",nil]];
        }
    }

    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[[baseMode bundle] objectForInfoDictionaryKey:@"CFBundleName"] action:aSelector keyEquivalent:@""];
    [menuItem setTag:[self tagForDocumentModeIdentifier:BASEMODEIDENTIFIER]];
    [aMenu addItem:menuItem];

    count=[menuEntries count];
    if (count > 0) {
        [aMenu addItem:[NSMenuItem separatorItem]];
        
        // sort
        NSArray *sortedEntries=[menuEntries sortedArrayUsingDescriptors:
                        [NSArray arrayWithObjects:
                            [[NSSortDescriptor alloc] initWithKey:@"Name" ascending:YES selector:@selector(caseInsensitiveCompare:)],
                            [[NSSortDescriptor alloc] initWithKey:@"Identifier" ascending:YES],nil]];
        
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
		}
    }

    if (aFlag) {
        [aMenu addItem:[NSMenuItem separatorItem]];
        menuItem = [[NSMenuItem alloc] 
            initWithTitle:NSLocalizedString(@"Open User Modes Folder", @"Menu item in alternate mode menu for opening the user modes folder.")
                   action:@selector(revealModesFolder:)
            keyEquivalent:@""];
        [menuItem setTag:MENU_ITEM_TAG_USER_MODE_FOLDER];
        [menuItem setTarget:self];
        [aMenu addItem:menuItem];


#ifndef TCM_NO_DEBUG
		// debug only
        menuItem = [[NSMenuItem alloc] 
            initWithTitle:NSLocalizedString(@"Open SubEthaEdit Modes Folder",@"Menu item in alternate mode menu for opening the SubEthaEdit modes folder.")
                   action:@selector(revealModesFolder:)
            keyEquivalent:@""];
        [menuItem setTag:MENU_ITEM_TAG_BUNDLE_MODE_FOLDER];
        [menuItem setTarget:self];
        [aMenu addItem:menuItem];
#endif
    }
}

- (IBAction)revealModesFolder:(id)aSender {
	NSURL *url;
    switch ([aSender tag]) {
		case MENU_ITEM_TAG_BUNDLE_MODE_FOLDER: { // debug only
			url = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:BUNDLE_MODE_FOLDER_NAME];
		} break;
			
        case MENU_ITEM_TAG_USER_MODE_FOLDER: {
            NSArray *userDomainURLs = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
			url = [DocumentModeManager URLWithAddedBundleIdentifierDirectoryForURL:[userDomainURLs lastObject] subDirectoryName:LIBRARY_MODE_FOLDER_NAME];
		} break;
	}
//	BOOL canOpenURL = [[NSWorkspace sharedWorkspace] openURL:url]; (application error alert :/
	BOOL canOpenURL = [[NSWorkspace sharedWorkspace] openFile:[url path]];
    if (!canOpenURL) {
		NSBeep();
	}
}

- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode {
    [aPopUp removeAllItems];
    NSMenu *tempMenu=[NSMenu new];
    [self setupMenu:tempMenu action:@selector(none:) alternateDisplay:NO];
    if (hasAutomaticMode) {
        NSMenuItem *menuItem=[[[tempMenu itemArray] objectAtIndex:0] copy];
        [menuItem setTag:[self tagForDocumentModeIdentifier:AUTOMATICMODEIDENTIFIER]];
        [menuItem setTitle:NSLocalizedString(@"Automatic Mode", @"Foo")];
        [tempMenu insertItem:menuItem atIndex:0];
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
