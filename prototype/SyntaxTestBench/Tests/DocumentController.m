//
//  DocumentController.m
//  Hydra
//
//  Created by Ulrich Bauer on Wed Jan 29 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "DocumentController.h"


@implementation DocumentController

- (id)init
{
    if (self = [super init]) {
        _documentsById = [[NSMutableDictionary alloc] init];
        _selectionsByFileName = [[NSMutableDictionary alloc] init];
        _ODBParametersByFileName = [[NSMutableDictionary alloc] init];
        [self setEncodingFromRunningOpenPanel:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didNewDocument:)
                                                     name:TextDocumentNewNotification
                                                   object:nil];
    }
    return self;
}

- (void)addDocument:(NSDocument *)aDocument
{
	[super addDocument:aDocument];
	NSString *documentId = [(TextDocument *)aDocument documentId];
	[_documentsById setObject:aDocument forKey:documentId];
}

- (void)removeDocument:(NSDocument *)aDocument {
	NSString *documentId = [(TextDocument *)aDocument documentId];
	[_documentsById removeObjectForKey:documentId];
	[super removeDocument:aDocument];
}

- (void)handleSelectionRange:(NSValue *)value forDocument:(TextDocument *)document
{
    struct SelectionRange *selectionRange;
    selectionRange = malloc(sizeof(struct SelectionRange));
    [value getValue:selectionRange];
    if (LOGLEVEL(4)) NSLog(@"lineNum: %d\nstartRange: %d\nendRange: %d", selectionRange->lineNum, selectionRange->startRange, selectionRange->endRange);

    if (selectionRange->lineNum < 0) {
        if (LOGLEVEL(4)) NSLog(@"selectRange");
        [document selectRange:NSMakeRange(selectionRange->startRange, selectionRange->endRange - selectionRange->startRange) scrollToVisible:YES];
    } else {
        if (LOGLEVEL(4)) NSLog(@"gotoLine");
        [document gotoLine:selectionRange->lineNum + 1 orderFront:YES];
    }
    free(selectionRange);
}

- (void)handleODBParameters:(NSDictionary *)parameters forFileName:(NSString *)fileName
{
    if (LOGLEVEL(2)) NSLog(@"handling ODB parameters for file name: %@", fileName);
    TextDocument *document = [self documentForFileName:fileName];
    if (document == nil) {
        [_ODBParametersByFileName setObject:parameters forKey:fileName];
    } else {
        [document setODBParameters:parameters];
    }
}

- (void)handleSelection:(NSValue *)selection forFileName:(NSString *)fileName
{
    TextDocument *document = [self documentForFileName:fileName];
    if (document == nil) {
        [_selectionsByFileName setObject:selection forKey:fileName];
    } else {
        if (selection != nil) {
            [self handleSelectionRange:selection forDocument:document];
        }
    }
}

- (void)didNewDocument:(NSNotification *)aNotification
{
    if (LOGLEVEL(4)) NSLog(@"didNewDocument");
    TextDocument *document = [aNotification object];
    if (LOGLEVEL(8)) NSLog(@"_selectionsByFileName: %@", [_selectionsByFileName description]);
    
    NSString *originalFileName = [document fileName];
    if (originalFileName != nil) {
        NSString *fileName = [originalFileName stringByStandardizingPath];
        
        NSDictionary *parameters = [_ODBParametersByFileName objectForKey:fileName];
        if (parameters != nil) {
            [document setODBParameters:parameters];
            [_ODBParametersByFileName removeObjectForKey:fileName];
        }
    
        NSValue *selectionRangeValue = [_selectionsByFileName objectForKey:fileName];
        if (selectionRangeValue != nil) {
            [self handleSelectionRange:selectionRangeValue forDocument:document];
            [_selectionsByFileName removeObjectForKey:fileName];
        }
    }
}

- (TextDocument *)documentForDocumentId:(NSString *)aDocumentId
{
	return [_documentsById objectForKey:aDocumentId];
}

- (void)setEncodingFromRunningOpenPanel:(NSNumber *)newEncoding
{
    [_encodingFromRunningOpenPanel autorelease];
    _encodingFromRunningOpenPanel = [newEncoding copy];
}

- (NSNumber *)encodingFromRunningOpenPanel
{
    return _encodingFromRunningOpenPanel;
}

- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSStringEncoding defaultEncoding = [[defaults objectForKey:DefaultEncodingPreferenceKey] unsignedIntValue];
    NSPopUpButton *encodingPopUp;
    int result;

    [self setEncodingFromRunningOpenPanel:[NSNumber numberWithUnsignedInt:defaultEncoding]];
    [[EncodingManager sharedInstance] registerEncoding:defaultEncoding];
    [openPanel setAccessoryView:[[EncodingManager sharedInstance] encodingAccessory:defaultEncoding
                                                                includeDefaultEntry:YES
                                                         enableIgnoreRichTextButton:NO
                                                                      encodingPopUp:&encodingPopUp
                                                               ignoreRichTextButton:nil
                                                                     lossyEncodings:[NSArray array]]];
    result = [openPanel runModalForTypes:nil];

    if (result == NSOKButton) {
        [self setEncodingFromRunningOpenPanel:[NSNumber numberWithUnsignedInt:[[encodingPopUp selectedItem] tag]]];
    }
    [[EncodingManager sharedInstance] unregisterEncoding:[[encodingPopUp selectedItem] tag]];
    
    return result;
}

- (id)openDocumentWithContentsOfFile:(NSString *)aPath display:(BOOL)aFlag {
//    NSLog (@"openDocumentWithContentsOfFile:%@ display:%d",aPath,aFlag);
    TextDocument *document = [self documentForFileName:aPath];
    if (document) {
        // this is the least thing we have to do 
        // (otherwise Open Recent wont bring up the window if a file is open)
        [[[document topmostWindowController] window] makeKeyAndOrderFront:self];
        return document;
    }
    return [super openDocumentWithContentsOfFile:aPath display:aFlag];
}

@end
