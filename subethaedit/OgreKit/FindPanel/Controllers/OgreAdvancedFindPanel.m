//
//  OgreAdvancedFindPanel.m
//  OgreKit
//
//  Created by Isao Sonobe on Tue Jun 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <OgreKit/OgreAdvancedFindPanel.h>
#import <OgreKit/OgreAdvancedFindPanelController.h>

@implementation OgreAdvancedFindPanel

- (void)flagsChanged:(NSEvent*)theEvent
{
    [(OgreAdvancedFindPanelController*)[self delegate] findPanelFlagsChanged:[theEvent modifierFlags]];
    
    [super flagsChanged:theEvent];
}

@end
