//
//  ODBEditorController.m
//  flyopts
//
//  Created by August Mueller on 11/18/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "FOODBEditorController.h"
#import "FOODBEditor.h"
#import <WebKit/WebKit.h>

@implementation FOODBEditorController

static FOODBEditorController *me = nil;

+ (id) sharedController; {
    
    // oh, this probably isn't thread safe the first time around...
    if (!me) {
        me = [[FOODBEditorController alloc] init];
    }
    
    return me;
}


- (id)init {
	self = [super init];
    if (self) {
        [self setEditingTextViews:[NSMutableSet set]];
    }
    
	return self;
}

- (void)dealloc {
    FMRelease(editingTextViews);
    [super dealloc];
}



- (NSMutableSet *)editingTextViews {
    return editingTextViews; 
}
- (void)setEditingTextViews:(NSMutableSet *)newEditingTextViews {
    [newEditingTextViews retain];
    [editingTextViews release];
    editingTextViews = newEditingTextViews;
}

- (IBAction) endEditSession:(id)sender; {
    
    [[sender window] orderOut:nil];
    [NSApp endSheet:[sender window]];
    
    // FIXME - end the ODB session here as well.
    
    // Editor abortEditingFile:
}

- (void) openWebViewInODBEditor:(WebView*)webview; {
    [webview selectAll:nil];
	DOMDocumentFragment* selection = [[webview selectedDOMRange] cloneContents];
    NSLog(@"foo: %@", selection);
}


- (void) openInODBEditor:(NSTextView*)textView; {
    
    [editingTextViews addObject:textView];
    
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
    [contextDict setObject:textView forKey:@"textView"];
    
    // load up a new sheet.
    [NSBundle loadNibNamed:@"ODBEditInProgressSheet" owner:self];
    
    if (latestEditInProgressSheet) {
        
        [contextDict setObject:latestEditInProgressSheet forKey:@"progressSheet"];
        
        [NSApp beginSheet:latestEditInProgressSheet
           modalForWindow:[textView window]
            modalDelegate:self
           didEndSelector:NULL
              contextInfo:nil];
    }
    
    [contextDict retain]; // we'll see about releasing this later on.
    
    [[FOODBEditor sharedODBEditor] editString:[[textView textStorage] string]
                                      options:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Text from %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]] ,ODBEditorCustomPathKey, nil]
                                    forClient:self
                                      context:contextDict];
}

-(void) odbEditor:(FOODBEditor *)editor didModifyFileForString:(NSString *)newString context:(NSDictionary *)contextDict; {
    NSTextView *textView = [contextDict objectForKey:@"textView"];
    
    [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView textStorage] length]) withString:newString];
    [textView didChangeText];
}

-(void)odbEditor:(FOODBEditor *)editor didCloseFileForString:(NSString *)newString context:(NSDictionary *)contextDict; {
    
    NSTextView *textView            = [contextDict objectForKey:@"textView"];
    NSWindow *editInProgressSheet   = [contextDict objectForKey:@"progressSheet"];
    
    [editInProgressSheet orderOut:nil];
    [NSApp endSheet:editInProgressSheet];
    
    [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView textStorage] length]) withString:newString];
    [textView didChangeText];
    
	[NSApp activateIgnoringOtherApps:YES];
	
    [contextDict autorelease];
}



@end
