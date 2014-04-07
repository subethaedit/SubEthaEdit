//
//  EncodingDoctorDialog.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006-2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SEEEncodingDoctorDialogViewController, PlainTextWindowControllerTabContext, PlainTextDocument;

@protocol SEEDocumentDialogViewController
@property (nonatomic, weak) PlainTextWindowControllerTabContext *tabContext;
@property (nonatomic, readonly) id initialFirstResponder;
- (void)orderOut:(id)aSender;
@end

#import "TCMMMOperation.h"
#import "TCMMMTransformator.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowControllerTabContext.h"

@interface SEEEncodingDoctorDialogViewController : NSViewController <SEEDocumentDialogViewController> {
}

@property (nonatomic) NSStringEncoding encoding;

- (id)initWithEncoding:(NSStringEncoding)anEncoding;
- (IBAction)cancel:(id)aSender;
- (IBAction)rerunCheckAndConvert:(id)aSender;
- (IBAction)convertLossy:(id)aSender;
- (IBAction)jumpToSelection:(id)aSender; 
- (id)initialFirstResponder;
- (void)takeNoteOfOperation:(TCMMMOperation *)anOperation transformator:(TCMMMTransformator *)aTransformator;

@end

