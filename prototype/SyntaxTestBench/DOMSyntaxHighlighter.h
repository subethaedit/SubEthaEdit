//
//  SyntaxHighlighter.h
//  HTMLEditorX
//
//  Created by Dominik Wagner on Tue Jan 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SyntaxManager.h"


@interface DOMSyntaxHighlighter : NSObject <SyntaxHighlighter> {
    NSMutableDictionary *I_keyWords;
    NSMutableCharacterSet *I_keyWordCharacterSet;
    
}

@end
