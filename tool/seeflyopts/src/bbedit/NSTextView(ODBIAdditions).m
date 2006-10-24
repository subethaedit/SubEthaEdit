
#import "NSTextView(ODBIAdditions).h"
#import "FOODBEditor.h"
#import "FOODBEditorController.h"

@implementation NSTextView(FlyOptsODBAdditions)

- (IBAction) flyoptsODBEdit:(id)sender {
    [[FOODBEditorController sharedController] openInODBEditor:self];
}

- (void)fmReplaceCharactersInRange:(NSRange)range withString:(NSString *)string; {
    
    NSTextStorage *ts = [self textStorage];
    
    NSString *oldString = [[[[ts string] substringWithRange:range] copy] autorelease];
    
    NSUndoManager *undoManager = [[self window] undoManager];
    
    [[undoManager prepareWithInvocationTarget:self] fmReplaceCharactersInRange:NSMakeRange(range.location, [string length])
                                                                    withString:oldString];
    
    [ts replaceCharactersInRange:range withString:string];
}

@end
