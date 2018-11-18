//  DebugSendOperationController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 16.04.07.

#ifndef TCM_NO_DEBUG


#import "DebugSendOperationController.h"
#import "PlainTextDocument.h"
#import "TCMMMSession.h"
#import "TextOperation.h"
#import "SelectionOperation.h"

@implementation DebugSendOperationController

- (void)windowDidLoad {
    [self setValue:[NSNumber numberWithInt:10] forKey:@"operationLocation"];
    [self setValue:[NSNumber numberWithInt:10] forKey:@"operationLength"];
    [self setValue:@"haha" forKey:@"operationReplacementString"];
}

- (NSString *)windowNibName {
    return @"DebugSendOperation";
}

- (IBAction)sendTextOperation:(id)aSender {
    TextOperation *operation = [TextOperation textOperationWithAffectedCharRange:NSMakeRange(_operationLocation,_operationLength) replacementString:_operationReplacementString userID:[TCMMMUserManager myUserID]];
    PlainTextDocument *document = (PlainTextDocument *)[[[NSApp mainWindow] windowController] document];
    NSLog(@"%s document:%@ operation:%@",__FUNCTION__,document,operation);
    [[document session] documentDidApplyOperation:operation];
}

- (IBAction)sendSelectionOperation:(id)aSender {
    SelectionOperation *operation = [SelectionOperation selectionOperationWithRange:NSMakeRange(_operationLocation,_operationLength) userID:[TCMMMUserManager myUserID]];
    PlainTextDocument *document = (PlainTextDocument *)[[[NSApp mainWindow] windowController] document];
    NSLog(@"%s document:%@ operation:%@",__FUNCTION__,document,operation);
    [[document session] documentDidApplyOperation:operation];
}


@end

#endif
