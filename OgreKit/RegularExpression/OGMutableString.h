/*
 * Name: OGMutableString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGString.h>

@protocol OGMutableStringProtocol
- (void)appendString:(NSString*)string;
- (void)appendString:(NSString*)string 
	hasAttributesOfOGString:(NSObject<OGStringProtocol>*)ogString;

- (void)appendAttributedString:(NSAttributedString*)string;

- (void)appendOGString:(NSObject<OGStringProtocol>*)string;
- (void)appendOGStringLeaveImprint:(NSObject<OGStringProtocol>*)string;
- (void)appendOGString:(NSObject<OGStringProtocol>*)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes;
- (void)appendOGString:(NSObject<OGStringProtocol>*)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
	ofOGString:(NSObject<OGStringProtocol>*)srcString;

- (void)setAttributesOfOGString:(NSObject<OGStringProtocol>*)string 
	atIndex:(NSUInteger)index;
@end
