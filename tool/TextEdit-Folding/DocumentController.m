/*
        Document.m
        Copyright (c) 1995-2007 by Apple Computer, Inc., all rights reserved.
        Author: David Remahl
 
        NSDocumentController subclass for TextEdit
        Required to support transient documents and customized Open panel
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "DocumentController.h"
#import "Document.h"
#import "EncodingManager.h"
#import "Preferences.h"
#import "TextEditErrors.h"
#import "TextView.h"

/* A very simple container class which is used to collect the outlets from loading the encoding accessory.  No implementation provided, because all of the references are weak and don't need retain/release.  Would be nice to be able to switch to a mutable dictionary here at some point.
*/
@interface OpenSaveAccessoryOwner : NSObject {
@public
    IBOutlet NSView *accessoryView;
    IBOutlet EncodingPopUpButton *encodingPopUp;
    IBOutlet NSButton *checkBox;
}
@end

@implementation OpenSaveAccessoryOwner
@end

@implementation DocumentController

/* Create a new document of the default type and initialize its contents from the pasteboard. 
*/
- (Document *)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pb display:(BOOL)display error:(NSError **)error {
    BOOL result = NO;
    NSString *type = nil;
    NSMutableArray *availableTypes = [NSMutableArray arrayWithArray:[pb types]];
    NSTextView *textView = [[[TextView alloc] initWithFrame:NSMakeRect(0., 0., CGFLOAT_MAX, CGFLOAT_MAX)] autorelease];   // Temporary
    
    // Look for a type to read; we do this ourselves so that we know exactly which type is read
    while (!result && [availableTypes count] > 0 && (type = [textView preferredPasteboardTypeFromArray:availableTypes restrictedToTypesFromArray:nil])) {
        result = [textView readSelectionFromPasteboard:pb type:type];
        [availableTypes removeObject:type];
    }

    if (result && type) {
	Document *transientDoc = [self transientDocumentToReplace];

	Class docClass = [self documentClassForType:type];
	if (!docClass) {    // Could happen if the type is unknown to TextEdit as a possible doc format but is importable into text (for instance, URL)
	    type = [[textView textStorage] containsAttachments] ? NSRTFDPboardType : NSRTFPboardType;
	    docClass = [self documentClassForType:type];
	}
	id doc = [[[docClass alloc] initWithType:type error:error] autorelease];
	if (!doc) return nil; // error has been set
	
	[[doc textStorage] replaceCharactersInRange:NSMakeRange(0, [[doc textStorage] length]) withAttributedString:[textView textStorage]];
	
	if ([type isEqualToString:NSStringPboardType]) {
	    [[doc textStorage] setAttributes:[doc defaultTextAttributes:NO] range:NSMakeRange(0, [[textView textStorage] length])];
	}
	
	[self addDocument:doc];
	
	if (transientDoc != nil) {
	    [self replaceTransientDocument:transientDoc withDocument:doc display:display];
	} else {
	    if (display) {
		[doc makeWindowControllers];
		[doc showWindows];
	    }
	}
	
	return doc;
    }
    
    // No suitable type found on pasteboard
    if (error) *error = [NSError errorWithDomain:TextEditErrorDomain code:TextEditOpenDocumentWithSelectionServiceFailed userInfo:[
            NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Service failed. Couldn\\U2019t open the selection.", @"Title of alert indicating error during 'New Window Containing Selection' service"), NSLocalizedDescriptionKey,
            NSLocalizedString(@"There might be an internal error or a performance problem, or the source application may be providing text of invalid type in the service request. Please try the operation a second time. If that doesn\\U2019t work, copy/paste the selection into TextEdit.", @"Recommendation when 'New Window Containing Selection' service fails"), NSLocalizedRecoverySuggestionErrorKey,
            nil]];

    return nil;
}

/* This method is overridden in order to support transient documents, i.e. the automatic closing of an automatically created untitled document, when a real document is opened. 
*/
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    Document *doc = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
    
    if (!doc) return nil;
    
    if ([[self documents] count] == 1) {
        // Determine whether this document might be a transient one
        // Check if there is a current AppleEvent. If there is, check whether it is an open or reopen event. In that case, the document being created is transient.
        NSAppleEventDescriptor *evtDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        AEEventID evtID = [evtDesc eventID];
        
        if (evtDesc && (evtID == kAEReopenApplication || evtID == kAEOpenApplication) && [evtDesc eventClass] == kCoreEventClass) {
            [doc setTransient:YES];
        }
    }
    
    return doc;
}

- (Document *)transientDocumentToReplace {
    NSArray *documents = [self documents];
    Document *transientDoc = nil;
    return ([documents count] == 1 && [(transientDoc = [documents objectAtIndex:0]) isTransientAndCanBeReplaced]) ? transientDoc : nil;
}

- (void)replaceTransientDocument:(Document *)transientDoc withDocument:(Document *)doc display:(BOOL)displayDocument {
    NSArray *controllersToTransfer = [[transientDoc windowControllers] copy];
    NSEnumerator *controllerEnum = [controllersToTransfer objectEnumerator];
    NSWindowController *controller;
    
    [controllersToTransfer makeObjectsPerformSelector:@selector(retain)];
    
    while (controller = [controllerEnum nextObject]) {
	[doc addWindowController:controller];
	[transientDoc removeWindowController:controller];
    }
    [transientDoc close];
    
    [controllersToTransfer makeObjectsPerformSelector:@selector(release)];
    [controllersToTransfer release];
    
    if (displayDocument) {
	[doc makeWindowControllers];
	[doc showWindows];
    }
}

/* When a document is opened, check to see whether there is a document that is already open, and whether it is transient. If so, transfer the document's window controllers and close the transient document. 
*/
- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    Document *transientDoc = [self transientDocumentToReplace];
    Document *doc = [super openDocumentWithContentsOfURL:absoluteURL display:(displayDocument && !transientDoc) error:outError];
    
    if (!doc) return nil;
    
    if (transientDoc != nil) [self replaceTransientDocument:transientDoc withDocument:doc display:YES];
    
    return doc;
}

/* When a second document is added, the first document's transient status is cleared. This happens when the user selects "New" when a transient document already exists. 
*/
- (void)addDocument:(NSDocument *)newDoc {
    Document *firstDoc;
    NSArray *documents = [self documents];
    if ([documents count] == 1 && (firstDoc = [documents objectAtIndex:0]) && [firstDoc isTransient]) {
        [firstDoc setTransient:NO];
    }
    [super addDocument:newDoc];
}

/* Loads the "encoding" accessory view used in save plain and open panels. There is a checkbox in the accessory which has different purposes in each case; so we let the caller set the title and other info for that checkbox.
*/
+ (NSView *)encodingAccessory:(NSUInteger)encoding includeDefaultEntry:(BOOL)includeDefaultItem encodingPopUp:(NSPopUpButton **)popup checkBox:(NSButton **)button {
    OpenSaveAccessoryOwner *owner = [[[OpenSaveAccessoryOwner alloc] init] autorelease];
    // Rather than caching, load the accessory view everytime, as it might appear in multiple panels simultaneously.
    if (![NSBundle loadNibNamed:@"EncodingAccessory" owner:owner])  {
        NSLog(@"Failed to load EncodingAccessory.nib");
        return nil;
    }
    if (popup) *popup = owner->encodingPopUp;
    if (button) *button = owner->checkBox;
    [[EncodingManager sharedInstance] setupPopUp:owner->encodingPopUp selectedEncoding:encoding withDefaultEntry:includeDefaultItem];
    return [owner->accessoryView autorelease];
}

- (IBAction)openDocument:(id)sender {
    // Remember the current default settings
    lastSelectedEncoding = [self lastSelectedEncoding];
    lastSelectedIgnoreHTML = [self lastSelectedIgnoreHTML];
    lastSelectedIgnoreRich = [self lastSelectedIgnoreRich];

    // Now switch to using those explicitly
    useCustomSettingsForOptions = YES;
    
    // Let the user choose document, and change settings
    [super openDocument:sender];

    // All done; switch back to using the default values
    useCustomSettingsForOptions = NO;    
}

/* To support selection of a fallback encoding, we override this method and add an accessory view.
*/
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)fileNameExtensionsAndHFSFileTypes {
    NSButton *ignoreRichTextButton;
    NSPopUpButton *encodingPopUp;
    NSInteger result;
    
    [openPanel setAccessoryView:[[self class] encodingAccessory:[[Preferences objectForKey:PlainTextEncodingForRead] unsignedIntegerValue] includeDefaultEntry:YES encodingPopUp:&encodingPopUp checkBox:&ignoreRichTextButton]];
    [ignoreRichTextButton setTitle:NSLocalizedString(@"Ignore rich text commands", @"Checkbox indicating that when opening a rich text file, the rich text should be ignored (causing the file to be loaded as plain text)")];
    // Also set tooltip: "If selected, HTML and RTF files will be loaded as plain text, allowing you to see and edit the HTML or RTF directives". If the ignoreRichText and ignoreHTML preference values do not agree, then the initial state of the ignore button in the panel should be "mixed" state, indicating it will do the appropriate thing depending on the file selected.
    if (lastSelectedIgnoreRich != lastSelectedIgnoreHTML) {
	[ignoreRichTextButton setAllowsMixedState:YES];
	[ignoreRichTextButton setState:NSMixedState];
    } else {
	if ([ignoreRichTextButton allowsMixedState]) [ignoreRichTextButton setAllowsMixedState:NO];
	[ignoreRichTextButton setState:lastSelectedIgnoreRich ? NSOnState : NSOffState];
    }
    
    result = [super runModalOpenPanel:openPanel forTypes:fileNameExtensionsAndHFSFileTypes];
    if (result == NSOKButton) {
	lastSelectedEncoding = [[encodingPopUp selectedItem] tag];
	NSInteger ignoreState = [ignoreRichTextButton state];
	if (ignoreState != NSMixedState) {  // Mixed state indicates they were different, and to leave them alone
	    lastSelectedIgnoreHTML = lastSelectedIgnoreRich = (ignoreState == NSOnState);
	}
    }
    return result;
}

- (NSStringEncoding)lastSelectedEncoding {
    return useCustomSettingsForOptions ? lastSelectedEncoding : [[Preferences objectForKey:PlainTextEncodingForRead] unsignedIntegerValue];
}

- (BOOL)lastSelectedIgnoreHTML {
    return useCustomSettingsForOptions ? lastSelectedIgnoreHTML : [[Preferences objectForKey:IgnoreHTML] boolValue];
}

- (BOOL)lastSelectedIgnoreRich {
    return useCustomSettingsForOptions ? lastSelectedIgnoreRich : [[Preferences objectForKey:IgnoreRichText] boolValue];
}

/* The user can change the default document type between Rich and Plain in Preferences. We override
   -defaultType to return the appropriate type string. 
*/
- (NSString *)defaultType {
    return [[Preferences objectForKey:RichText] boolValue] ? NSRTFPboardType : NSStringPboardType;
}

@end
