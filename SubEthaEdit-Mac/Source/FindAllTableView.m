//  FindAllTableView.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 7/19/05.

#import "FindAllTableView.h"

@implementation FindAllTableView

// Implement copying lines
- (void)copy:(id)sender {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableString *string = [NSMutableString new];

    switch ([self numberOfSelectedRows]) {
        case 0:
            NSBeep();
            return;

        default:
        {
            id selection = [self selectedRowIndexes];
            NSUInteger index = [selection firstIndex]; 

            do {
                [string appendString:[[[[(id)[self delegate] arrangedObjects] objectAtIndex:index] objectForKey:@"foundString"] string]];
            } while ((index = [selection indexGreaterThanIndex: index]) != NSNotFound);
        }
    }

    [pb declareTypes: [NSArray arrayWithObject:NSStringPboardType] 
        owner:nil];

    [pb setString:string forType: NSStringPboardType];
}

- (void)paste:(id)sender {
    NSBeep();
}

- (void)cut:(id)sender {
    NSBeep();
}

//Custom behavior for keys
- (void)keyDown:(NSEvent *)theEvent {
    NSUInteger characterIndex, characterCount; 
    int selectedRow = [self selectedRow]; 
    NSString *characters = [theEvent charactersIgnoringModifiers]; 
    characterCount = [characters length]; 
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++) { 
        unichar c = [characters characterAtIndex: characterIndex]; 
        switch(c) { 
            // After checking how NSButton behaves I opted to jump upon Return and Enter.
            case 13: // ReturnKey
            case NSEnterCharacter: // == 3
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                // This selector won't leak, as the return type is always zero
                if (selectedRow > -1) [[self target] performSelector:[self doubleAction]];
#pragma clang diagnostic pop
                
            break;
            default:
                [super keyDown:theEvent]; 
        } 
    } 

}

// instant reaction on first click:
- (BOOL)needsPanelToBecomeKey {
    return NO;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent {
    return YES;
}

@end
