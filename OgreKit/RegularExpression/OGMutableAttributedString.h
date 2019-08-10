/*
 * Name: OGMutableAttributedString.h
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

#import <OgreKit/OGMutableString.h>
#import <OgreKit/OGAttributedString.h>

@interface OGMutableAttributedString : OGAttributedString <OGMutableStringProtocol>
{
	NSString		*_currentFontFamilyName;
	NSFontTraitMask	_currentFontTraits;
	float			_currentFontWeight;
	float			_currentFontPointSize;
	NSDictionary	*_currentAttributes;
	NSFontManager	*_fontManager;
}

@end
