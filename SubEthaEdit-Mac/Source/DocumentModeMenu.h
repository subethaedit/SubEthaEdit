//  DocumentModeMenu.h
//  SubEthaEdit
//
//  Created by dom on 29.03.2021.

#import <Cocoa/Cocoa.h>

@interface DocumentModeMenu : NSMenu {
    SEL I_action;
    BOOL I_alternateDisplay;
}
- (void)configureWithAction:(SEL)aSelector alternateDisplay:(BOOL)aFlag;
@end

