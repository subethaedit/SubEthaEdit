//
//  PlainTextWindowControllerTabContext.h
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextWindowController, PlainTextDocument, PlainTextLoadProgress;


@interface PlainTextWindowControllerTabContext : NSObject {
}

@property (nonatomic, strong) NSMutableArray *plainTextEditors;
@property (nonatomic, strong) NSSplitView *editorSplitView;
@property (nonatomic, strong) NSSplitView *dialogSplitView;
@property (nonatomic, strong) PlainTextDocument *document;
@property (nonatomic, strong) id documentDialog;

@property (nonatomic) BOOL isReceivingContent;
@property (nonatomic) BOOL isAlertScheduled;
@property (nonatomic, strong) PlainTextLoadProgress *loadProgress;


@property (nonatomic) BOOL isProcessing;
@property (nonatomic) BOOL isEdited;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSString *iconName;
@property (nonatomic) int objectCount;

@end
