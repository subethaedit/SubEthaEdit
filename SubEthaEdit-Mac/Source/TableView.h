//  TableView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.10.04.

#import <Cocoa/Cocoa.h>


@interface TableView : NSTableView {
    NSColor *I_lightBackgroundColor;
    NSColor *I_darkBackgroundColor;
    BOOL I_disableFirstRow;
}

-(void)setLightBackgroundColor:(NSColor *)aColor;
-(void)setDarkBackgroundColor:(NSColor *)aColor;
-(void)setDisableFirstRow:(BOOL)aFlag;

@end
