//
//  DocumentModeManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"

@interface DocumentModeMenu : NSMenu {
    SEL I_action;
}
- (void)configureWithAction:(SEL)aSelector;
@end

@interface DocumentModeManager : NSObject {
    NSMutableDictionary *I_modeBundles;
    NSMutableDictionary *I_documentModesByIdentifier;
	NSMutableDictionary *I_modeIdentifiersByExtension;
	NSMutableArray      *I_modeIdentifiersTagArray;
}

+ (DocumentModeManager *)sharedInstance;

- (DocumentMode *)baseMode;
- (DocumentMode *)documentModeForIdentifier:(NSString *)anIdentifier;
- (DocumentMode *)documentModeForExtension:(NSString *)anExtension;
- (NSString *)documentModeIdentifierForTag:(int)aTag;
- (int)tagForDocumentModeIdentifier:(NSString *)anIdentifier;
- (NSDictionary *)availableModes;


@end
