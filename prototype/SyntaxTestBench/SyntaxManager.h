//
//  SyntaxManager.h
//  XXP
//
//  Created by Martin Pittenauer on Tue Mar 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SyntaxManager : NSObject {
    NSMutableArray      *I_definitions;
    NSMutableDictionary *I_availableSyntaxNames;
}

+ (SyntaxManager *)sharedInstance;
- (void) reloadSyntaxDefinitions;

// Public API:
- (NSDictionary *) availableSyntaxNames;
- (NSString *) syntaxDefinitionForExtension:(NSString *) anExtension;
- (NSString *) syntaxDefinitionForName:(NSString *) aName;



@end
