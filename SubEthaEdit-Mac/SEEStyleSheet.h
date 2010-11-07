//
//  SEEStyleSheet.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.
//  Copyright 2010 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SEEStyleSheet : NSObject {
	NSMutableDictionary * I_ScopeStyleDictionary;
	NSMutableDictionary * I_scopeCache;
}

@property (nonatomic, retain) NSMutableDictionary * scopeStyleDictionary;
@property (nonatomic, retain) NSMutableDictionary * scopeCache;


- (NSDictionary *)styleAttributesForScope:(NSString *)aScope;



@end
