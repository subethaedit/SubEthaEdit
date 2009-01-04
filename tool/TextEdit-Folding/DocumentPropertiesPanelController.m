/*
        DocumentPropertiesPanelController.m
        Copyright (c) 2007 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer

        "Document Properties" panel controller for TextEdit.  There is a little more code here than one would like,
	however, this code does show steps needed to implement a non-modal inspector panel using bindings, and have 
	the fields in the panel correctly commit when the panel loses key, or the document it is associated with
	is saved or made non-key (inactive).
	
	This class is mostly reusable, except with the assumption that commitEditing always succeeds.
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


#import "DocumentPropertiesPanelController.h"
#import "Document.h"
#import "DocumentController.h"


@implementation DocumentPropertiesPanelController

- (id)init {
    return [super initWithWindowNibName:@"DocumentProperties"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSApp removeObserver:self forKeyPath:@"mainWindow.windowController.document"];
    [super dealloc];
}

/* inspectedDocument is a KVO-compliant property, which this method manages. Anytime we hear about the mainWindow, or the mainWindow's document change, we check to see what changed.  Note that activeDocumentChanged doesn't mean document contents changed, but rather we have a new active document.
*/
- (void)activeDocumentChanged {
    id doc = [[[NSApp mainWindow] windowController] document];
    if (doc != inspectedDocument) {
	if (inspectedDocument) [documentObjectController commitEditing];
	[self setValue:(doc && [doc isKindOfClass:[Document class]]) ? doc : nil forKey:@"inspectedDocument"];   
    }
}
    
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == [DocumentPropertiesPanelController class]) {
	[self activeDocumentChanged];
    } else {
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/* When controls in the panel start editing, register it with the inspected document.
*/
- (void)objectDidBeginEditing:(id)editor {
    [inspectedDocument objectDidBeginEditing:editor];
}

- (void)objectDidEndEditing:(id)editor {
    [inspectedDocument objectDidEndEditing:editor];
}

/* We don't want to do any observing until the properties panel is brought up.
*/
- (void)windowDidLoad {
    // Once the UI is loaded, we start observing the panel itself to commit editing when it becomes inactive (loses key state)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentPropertiesPanelDidResignKey:) name:NSWindowDidResignKeyNotification object:[self window]];

    // Make sure we start inspecting the document that is currently active, and start observing changes
    [self activeDocumentChanged];
    [NSApp addObserver:self forKeyPath:@"mainWindow.windowController.document" options:0 context:[DocumentPropertiesPanelController class]];

    [super windowDidLoad];  // It's documented to do nothing, but still a good idea to invoke...
}

/* Whenever the properties panel loses key status, we want to commit editing.
*/
- (void)documentPropertiesPanelDidResignKey:(NSNotification *)notification {
    [documentObjectController commitEditing];
}

/* Since we want the panel to toggle... Note that if the window is visible and key, we order it out; otherwise we make it key.
*/
- (void)toggleWindow:(id)sender {
    NSWindow *window = [self window];
    if ([window isVisible] && [window isKeyWindow]) {
	[[self window] orderOut:sender];
    } else {
	[[self window] makeKeyAndOrderFront:sender];
    }
}

/* validateMenuItem: is used to dynamically set attributes of menu items.
*/
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleWindow:)) {   // Correctly toggle the menu item for showing/hiding document properties
	// We call [self isWindowLoaded] first since it prevents [self window] from loading the nib
	validateToggleItem(menuItem, [self isWindowLoaded] && [[self window] isVisible], NSLocalizedString(@"Hide Properties", @"Title for menu item to hide the document properties panel."), NSLocalizedString(@"Show Properties", @"Title for menu item to show the document properties panel (should be the same as the initial menu item in the nib)."));
    }
    return YES;
}

@end
