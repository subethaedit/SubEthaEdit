#import <Cocoa/Cocoa.h>
#import "Document.h"

/* An instance of this subclass is created in the main nib file. */

// NSDocumentController is subclassed to provide for modification of the open panel. Normally, there is no need to subclass the document controller.
@interface DocumentController : NSDocumentController {
    BOOL useCustomSettingsForOptions;	    // YES means that lastSelectedEncoding, lastSelectedIgnoreHTML, and lastSelectedIgnoreRich should be used instead of the default settings from Preferences
    NSStringEncoding lastSelectedEncoding;
    BOOL lastSelectedIgnoreHTML, lastSelectedIgnoreRich;
}

+ (NSView *)encodingAccessory:(NSUInteger)encoding includeDefaultEntry:(BOOL)includeDefaultItem encodingPopUp:(NSPopUpButton **)popup checkBox:(NSButton **)button;

- (Document *)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pb display:(BOOL)display error:(NSError **)error;

- (NSStringEncoding)lastSelectedEncoding;
- (BOOL)lastSelectedIgnoreHTML;
- (BOOL)lastSelectedIgnoreRich;

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)fileNameExtensionsAndHFSFileTypes;

- (Document *)transientDocumentToReplace;
- (void)replaceTransientDocument:(Document *)transientDoc withDocument:(Document *)doc display:(BOOL)displayDocument;

@end
