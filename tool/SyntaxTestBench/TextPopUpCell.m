//
//  TextPopUpCell.m
//  XXP
//
//  Created by Dominik Wagner on Sat Mar 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TextPopUpCell.h"

@implementation TextPopUpCell

- (id)initTextCell:(NSString *)aString {
    self=[super initTextCell:aString];
    _textFieldCell=[[NSTextFieldCell alloc] initTextCell:@""];
    [_textFieldCell setControlSize:NSSmallControlSize];
    [_textFieldCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [_textFieldCell setWraps:NO];
    //NSLog(@"textPopUpCell initTextCell finished");
    return self;
}

- (void)dealloc {
    [_textFieldCell release];
    [super dealloc];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
    if ([controlView respondsToSelector:@selector(delegate)]) {
        id delegate=[controlView performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:@selector(textPopUpWillShowMenu:)]) {
            [delegate textPopUpWillShowMenu:self];
        }
    }
    return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (float)desiredWidth {
    NSSize textSize=[[_textFieldCell stringValue]
                        sizeWithAttributes:[NSDictionary dictionaryWithObject:
                                                [_textFieldCell font] forKey:NSFontAttributeName]];
    // text + arrows + inset?
    return textSize.width+6.+2.;   
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    cellFrame.size.width-=6.;
    [_textFieldCell drawWithFrame:cellFrame inView:controlView];
    NSImage *arrow=[NSImage imageNamed:@"SmallPopUpArrows.tiff"];
    NSSize  textSize=[[_textFieldCell stringValue] 
                        sizeWithAttributes:[NSDictionary dictionaryWithObject:
                                                [_textFieldCell font] forKey:NSFontAttributeName]];
    // ISSUE: maybe totally wrong
    NSPoint drawTo;
    drawTo.x=NSMinX(cellFrame)+textSize.width+4.;
    if (drawTo.x>NSMaxX(cellFrame)) drawTo.x=NSMaxX(cellFrame)+1.;
    drawTo.y=cellFrame.origin.y+cellFrame.size.height/2.+1.;
    if ([controlView isFlipped]) {
        drawTo.y+=[arrow size].height/2.;
    } else {
        drawTo.y-=[arrow size].height/2.;
    }
    [arrow setFlipped:NO];
    [arrow dissolveToPoint:drawTo fraction:1];
}

- (void)selectItem:(id <NSMenuItem>)aItem {
    [super selectItem:aItem];
    [_textFieldCell setStringValue:[aItem title]];
}

- (void)selectItemAtIndex:(int)aIndex {
    [super selectItemAtIndex:aIndex];
    NSMenuItem *item=[self selectedItem];
    if (item) {
        [_textFieldCell setStringValue:[item title]];
    }
}

- (void)setStringValue:(NSString*)aString {
    [_textFieldCell setStringValue:aString];
}

@end