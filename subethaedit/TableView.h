//
//  TableView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TableView : NSTableView {
    NSColor *I_lightBackgroundColor;
    NSColor *I_darkBackgroundColor;
}

-(void)setLightBackgroundColor:(NSColor *)aColor;
-(void)setDarkBackgroundColor:(NSColor *)aColor;
@end
