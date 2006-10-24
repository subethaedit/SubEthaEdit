#import <Cocoa/Cocoa.h>

extern NSString * const ODBEditorCustomPathKey;

@interface FOODBEditor : NSObject
{
	UInt32					_signature;
	NSString				*_editorBundleIdentifier;
	NSMutableDictionary		*_filesBeingEdited;
}

+ (id)sharedODBEditor;

- (void) removeODBClient:(id) client;

- (void)setEditorBundleIdentifier:(NSString *)bundleIdentifier;
- (NSString *)editorBundleIdentifier;

- (void)abortEditingFile:(NSString *)path;
- (void)abortAllEditingSessionsForClient:(id)client;

// NOTE that client is never retained - it is your reponsibility to
// make sure the client sticks around and abort editing for that client
// before it is dealloc'd
//
// Also note that while it is possible to start several editString
// sessions for a single client it is the client's responsibility to
// distinguish between the sessions (possibly using the original
// context that you supplied.) It is also the clients responsibility to
// do the same for file editing sessions, but this should be easier
// since the file path will remain static (except in the save as case)
// whereas the string returned is obviously going to change as the user
// edits it.

- (BOOL)editFile:(NSString *)path options:(NSDictionary *)options forClient:(id)client context:(void *)context;

- (BOOL)editString:(NSString *)string options:(NSDictionary *)options forClient:(id)client context:(void *)context;

@end

@interface NSObject(ODBEditorClient)

// see the ODB Editor documentation for when newFileLocation is sent
// if the file wasn't subject to a save as newpath will be nil

-(void)odbEditor:(FOODBEditor *)editor didModifyFile:(NSString *)path newFileLocation:(NSString *)newPath  context:(NSDictionary *)context;
-(void)odbEditor:(FOODBEditor *)editor didClosefile:(NSString *)path context:(NSDictionary *)context;

-(void)odbEditor:(FOODBEditor *)editor didModifyFileForString:(NSString *)newString context:(void *)context;
-(void)odbEditor:(FOODBEditor *)editor didCloseFileForString:(NSString *)newString context:(void *)context;

@end
