//
//  SyntaxHighlighter.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SyntaxHighlighter : NSObject {
    NSMutableDictionary *I_keyWords;
    NSMutableCharacterSet *I_keyWordCharacterSet;

}

@end
