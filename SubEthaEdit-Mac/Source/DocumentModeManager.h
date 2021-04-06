//  DocumentModeManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"
#import "DocumentModePopUpButton.h"
#import "DocumentModeMenu.h"
#import "SEEStyleSheet.h"

//#define MODE_EXTENSION [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:@"de.codingmonkeys.subethaedit.seemode"]
#define MODE_EXTENSION @"seemode"
#define MODE5_EXTENSION @"see5mode"
#define BASEMODEIDENTIFIER @"SEEMode.Base"
#define AUTOMATICMODEIDENTIFIER @"SEEMode.Automatic"

@interface DocumentModeManager : NSObject <NSAlertDelegate> {
    NSMutableDictionary *I_modeBundles;
    NSMutableDictionary *I_documentModesByIdentifier;
    NSMutableDictionary *I_documentModesByName;

	NSRecursiveLock *I_documentModesByIdentifierLock; // (ifc - experimental locking for thread safety... TCM are putting in a real fix)

	NSMutableArray      *I_modeIdentifiersTagArray;
	
	// style sheet management
	NSMutableDictionary *I_styleSheetPathsByName;
	NSMutableDictionary *I_styleSheetsByName;
}

@property (nonatomic, strong, readonly) NSArray *allPathExtensions;
@property (nonatomic, strong) NSMutableArray *modePrecedenceArray;

+ (DocumentModeManager *)sharedInstance;
+ (DocumentMode *)baseMode;
+ (NSString *)xmlFileRepresentationOfAllStyles;
+ (NSString *)defaultStyleSheetName;

- (DocumentMode *)baseMode;
- (DocumentMode *)modeForNewDocuments;
- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier;
- (DocumentMode *)documentModeForPath:(NSString *)path withContentData:(NSData *)content;
- (DocumentMode *)documentModeForPath:(NSString *)path withContentString:(NSString *)contentString;
- (DocumentMode *)documentModeForName:(NSString *)aName;
- (NSArray *)allLoadedDocumentModes;
- (NSString *)documentModeIdentifierForTag:(NSInteger)aTag;
- (BOOL)documentModeAvailableModeIdentifier:(NSString *)anIdentifier;
- (NSInteger)tagForDocumentModeIdentifier:(NSString *)anIdentifier;
- (NSDictionary *)availableModes;

- (NSMutableArray *)reloadPrecedences;
- (void)revalidatePrecedences;

@property (nonatomic, strong, readonly) NSDictionary *changedScopeNameDict;
- (void)reloadAllStyles;
- (SEEStyleSheet *)styleSheetForName:(NSString *)aStyleSheetName;
- (NSArray *)allStyleSheetNames;
- (void)saveStyleSheet:(SEEStyleSheet *)aStyleSheet;
- (SEEStyleSheet *)duplicateStyleSheet:(SEEStyleSheet *)aStyleSheet;
- (void)revealStyleSheetInFinder:(SEEStyleSheet *)aStyleSheet;
- (NSURL *)customStyleSheetFolderURL;

- (IBAction)reloadDocumentModes:(id)aSender;
- (void)revealModeInFinder:(DocumentMode *)aMode jumpIntoContentFolder:(BOOL)aJumpIntoContentFolder;
- (NSURL *)urlForWritingModeWithName:(NSString *)aModeName;
@end

// Private additions
@interface DocumentModeManager ()
- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector alternateDisplay:(BOOL)aFlag;
- (void)setupPopUp:(DocumentModePopUpButton *)aPopUp selectedModeIdentifier:(NSString *)aModeIdentifier automaticMode:(BOOL)hasAutomaticMode;
@end
