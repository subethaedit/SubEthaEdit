/*
 * Name: OGRegularExpressionMatch.m
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/onigmo.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionCapturePrivate.h>
#import <OgreKit/OGString.h>


NSString	* const OgreMatchException = @"OGRegularExpressionMatchException";

// ���g��encoding/decoding���邽�߂�key
static NSString	* const OgreRegionKey              = @"OgreMatchRegion";
static NSString	* const OgreEnumeratorKey          = @"OgreMatchEnumerator";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreMatchTerminalOfLastMatch";
static NSString	* const OgreIndexOfMatchKey        = @"OgreMatchIndexOfMatch";
static NSString	* const OgreCaptureHistoryKey      = @"OgreMatchCaptureHistory";


inline unsigned Ogre_UTF16strlen(unichar *const aUTF16string, unichar *const end)
{
	return end - aUTF16string;
}

static NSArray *Ogre_arrayWithOnigRegion(OnigRegion *region)
{
	if (region == NULL) return nil;
	
	NSMutableArray      *regionArray = [NSMutableArray arrayWithCapacity:1];
	unsigned            i = 0, n = region->num_regs;
	
	for( i = 0; i < n; i++ ) {
		[regionArray addObject:[NSArray arrayWithObjects:
			[NSNumber numberWithInt:region->beg[i]], 
			[NSNumber numberWithInt:region->end[i]], 
			nil]];
	}
	
	return regionArray;
}

static OnigRegion *Ogre_onigRegionWithArray(NSArray *regionArray)
{
	if (regionArray == nil) return NULL;
	
	OnigRegion		*region = onig_region_new();
	if (region == NULL) {
		// ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}
	unsigned		i = 0, n = [regionArray count];
	NSArray			*anObject;
	int				r;
	
	r = onig_region_resize(region, [regionArray count]);
	if (r != ONIG_NORMAL) {
		// ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
		onig_region_free(region, 1);
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}

	for (i = 0; i < n; i++) {
        anObject = [regionArray objectAtIndex:i];
		region->beg[i] = [[anObject objectAtIndex:0] unsignedIntValue];
		region->end[i] = [[anObject objectAtIndex:1] unsignedIntValue];
	}
    
    region->history_root = NULL;
	
	return region;
}

static NSArray *Ogre_arrayWithOnigCaptureTreeNode(OnigCaptureTreeNode *cap)
{
	if (cap == NULL) return [NSArray array];
	
	unsigned            i, n = cap->num_childs;
	NSMutableArray      *children = nil;
    
    if (n > 0) {
        children = [NSMutableArray arrayWithCapacity:n];
        for(i = 0; i < n; i++) [children addObject:Ogre_arrayWithOnigCaptureTreeNode(cap->childs[i])];
    }
    
    return [NSArray arrayWithObjects:
        [NSNumber numberWithInt:cap->group], 
        [NSNumber numberWithInt:cap->beg], 
        [NSNumber numberWithInt:cap->end], 
        children, 
        nil];
}

static OnigCaptureTreeNode *Ogre_onigCaptureTreeNodeWithArray(NSArray *captureArray)
{
    if (captureArray == nil || [captureArray count] == 0) return NULL;
    
    OnigCaptureTreeNode *capture;
    
    capture = (OnigCaptureTreeNode*)malloc(sizeof(OnigCaptureTreeNode));
	if (capture == NULL) {
		// ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}
    
    capture->group     = [[captureArray objectAtIndex:0] unsignedIntValue];
    capture->beg       = [[captureArray objectAtIndex:1] unsignedIntValue];
    capture->end       = [[captureArray objectAtIndex:2] unsignedIntValue];
    
    
    if ([captureArray count] >= 4) {
        NSArray     *children = (NSArray*)[captureArray objectAtIndex:3];
        unsigned    i, n = [children count];
        capture->childs = (OnigCaptureTreeNode**)malloc(n * sizeof(OnigCaptureTreeNode*));
        if (capture->childs == NULL) {
            // ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
            free(capture);
            [NSException raise:NSMallocException format:@"fail to memory allocation"];
        }
        
        capture->allocated = n;
        capture->num_childs = n;
        for (i = 0; i < n; i++) capture->childs[i] = Ogre_onigCaptureTreeNodeWithArray([children objectAtIndex:i]);
    } else {
        capture->allocated = 0;
        capture->num_childs = 0;
        capture->childs = NULL;
    }
    
    return capture;
}


@implementation OGRegularExpressionMatch

// �}�b�`��������
- (unsigned)index
{
	return _index;
}

// ����������̐� + 1
- (unsigned)count
{
	return _region->num_regs;
}

// �}�b�`����������͈̔�
- (NSRange)rangeOfMatchedString
{
	return [self rangeOfSubstringAtIndex:0];
}

// �}�b�`���������� \&, \0
- (NSObject<OGStringProtocol>*)matchedOGString
{
	return [self ogSubstringAtIndex:0];
}

- (NSString*)matchedString
{
	return [self substringAtIndex:0];
}

- (NSAttributedString*)matchedAttributedString
{
	return [self attributedSubstringAtIndex:0];
}

// index�Ԗڂ�substring�͈̔�
- (NSRange)rangeOfSubstringAtIndex:(unsigned)index
{
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ) {
		// index�Ԗڂ�substring�����݂��Ȃ��ꍇ
		return NSMakeRange(NSNotFound, 0);
	}
	//NSLog(@"%d %d-%d", index, _region->beg[index], _region->end[index]);
	
	return NSMakeRange(_searchRange.location + (_region->beg[index] / sizeof(unichar)), (_region->end[index] - _region->beg[index]) / sizeof(unichar));
}

// index�Ԗڂ�substring \n
- (NSObject<OGStringProtocol>*)ogSubstringAtIndex:(unsigned)index
{
	// index�Ԗڂ�substring�����݂��Ȃ����ɂ� nil ��Ԃ�
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

- (NSString*)substringAtIndex:(unsigned)index
{
	// index�Ԗڂ�substring�����݂��Ȃ����ɂ� nil ��Ԃ�
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

- (NSAttributedString*)attributedSubstringAtIndex:(unsigned)index
{
	// index�Ԗڂ�substring�����݂��Ȃ����ɂ� nil ��Ԃ�
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

// �}�b�`�̑ΏۂɂȂ���������
- (NSObject<OGStringProtocol>*)targetOGString
{
	return _targetString;
}

- (NSString*)targetString
{
	return [_targetString string];
}

- (NSAttributedString*)targetAttributedString
{
	return [_targetString attributedString];
}

// �}�b�`�����������O�̕����� \`
- (NSObject<OGStringProtocol>*)prematchOGString
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

- (NSString*)prematchString
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

- (NSAttributedString*)prematchAttributedString
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

// �}�b�`�����������O�̕����� \` �͈̔�
- (NSRange)rangeOfPrematchString
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return NSMakeRange(NSNotFound, 0);
	}

	return NSMakeRange(_searchRange.location, _region->beg[0] / sizeof(unichar));
}

// �}�b�`�������������̕����� \'
- (NSObject<OGStringProtocol>*)postmatchOGString
{
	if (_region->beg[0] == -1) {
		// �}�b�`�������������̕����񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

- (NSString*)postmatchString
{
	if (_region->beg[0] == -1) {
		// �}�b�`�������������̕����񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

- (NSAttributedString*)postmatchAttributedString
{
	if (_region->beg[0] == -1) {
		// �}�b�`�������������̕����񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

// �}�b�`�������������̕����� \' �͈̔�
- (NSRange)rangeOfPostmatchString
{
	if (_region->beg[0] == -1) {
		// �}�b�`�������������̕����񂪑��݂��Ȃ��ꍇ
		return NSMakeRange(NSNotFound, 0);
	}
	
	return NSMakeRange(_searchRange.location + _region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar));
}

// �}�b�`����������ƈ�O�Ƀ}�b�`����������̊Ԃ̕����� \-
- (NSObject<OGStringProtocol>*)ogStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

- (NSString*)stringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

- (NSAttributedString*)attributedStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

// �}�b�`����������ƈ�O�Ƀ}�b�`����������̊Ԃ̕����� \- �͈̔�
- (NSRange)rangeOfStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// �}�b�`���������񂪑��݂��Ȃ��ꍇ
		return NSMakeRange(NSNotFound, 0);
	}

	return NSMakeRange(_searchRange.location + _terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch);
}

// �Ō�Ƀ}�b�`�������������� \+
- (NSObject<OGStringProtocol>*)lastMatchOGSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self ogSubstringAtIndex:i];
	}
}

- (NSString*)lastMatchSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self substringAtIndex:i];
	}
}

- (NSAttributedString*)lastMatchAttributedSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self attributedSubstringAtIndex:i];
	}
}

// �Ō�Ƀ}�b�`��������������͈̔� \+
- (NSRange)rangeOfLastMatchSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return NSMakeRange(NSNotFound, 0);
	} else {
		return [self rangeOfSubstringAtIndex:i];
	}
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
   if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region) forKey: OgreRegionKey];
		[encoder encodeObject: _enumerator forKey: OgreEnumeratorKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _terminalOfLastMatch] forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _index] forKey: OgreIndexOfMatchKey];
		[encoder encodeObject: Ogre_arrayWithOnigCaptureTreeNode(_region->history_root) forKey: OgreCaptureHistoryKey];
	} else {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region)];
		[encoder encodeObject: _enumerator];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _terminalOfLastMatch]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _index]];
		[encoder encodeObject: Ogre_arrayWithOnigCaptureTreeNode(_region->history_root)];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	// OnigRegion		*_region;				// match result region
	id  anObject;
	NSArray	*regionArray;
    if (allowsKeyedCoding) {
		regionArray = [decoder decodeObjectForKey: OgreRegionKey];
	} else {
		regionArray = [decoder decodeObject];
	}
	if (regionArray == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_region = Ogre_onigRegionWithArray(regionArray);	
	
    
	// OGRegularExpressionEnumerator*	_enumerator;	// ������
    if (allowsKeyedCoding) {
		_enumerator = [[decoder decodeObjectForKey: OgreEnumeratorKey] retain];
	} else {
		_enumerator = [[decoder decodeObject] retain];
	}
	if (_enumerator == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	
	// unsigned	_terminalOfLastMatch;	// �O��Ƀ}�b�`����������̏I�[�ʒu (_region->end[0] / sizeof(unichar))
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreTerminalOfLastMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_terminalOfLastMatch = [anObject unsignedIntValue];

	
	// 	unsigned		_index;		// �}�b�`��������
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIndexOfMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_index = [anObject unsignedIntValue];

	
	// _region->history_root    // capture history
	NSArray	*captureArray;
    if (allowsKeyedCoding) {
		captureArray = [decoder decodeObjectForKey:OgreCaptureHistoryKey];
	} else {
		captureArray = [decoder decodeObject];
	}
	if (captureArray == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_region->history_root = Ogre_onigCaptureTreeNodeWithArray(captureArray);
	
    
	// �p�ɂɗ��p������̂̓L���b�V������B�ێ��͂��Ȃ��B
	// �����Ώە�����
	_targetString        = [_enumerator targetString];
	// �����͈�
	NSRange	searchRange = [_enumerator searchRange];
	_searchRange.location = searchRange.location;
	_searchRange.length   = searchRange.length;
	
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	OnigRegion*	newRegion = onig_region_new();
	onig_region_copy(newRegion, _region);
	
	return [[[self class] allocWithZone:zone] 
		initWithRegion: newRegion 
		index:_index 
		enumerator:_enumerator
		terminalOfLastMatch:_terminalOfLastMatch];
}


// description
- (NSString*)description
{
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			Ogre_arrayWithOnigRegion(_region), 
			Ogre_arrayWithOnigCaptureTreeNode(_region->history_root), 
			_enumerator, 
			[NSNumber numberWithUnsignedInt: _terminalOfLastMatch], 
			[NSNumber numberWithUnsignedInt: _index], 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			@"Range of Substrings", 
			@"Capture History", 
			@"Regular Expression Enumerator", 
			@"Terminal of the Last Match", 
			@"Index", 
			nil]
		];
		
	return [dictionary description];
}


// ���O(���x��)��name�̕��������� (OgreCaptureGroupOption���w�肵���Ƃ��Ɏg�p�ł���)
// ���݂��Ȃ����O�̏ꍇ�� nil ��Ԃ��B
// ����̖��O�������������񂪕�������ꍇ�͗�O�𔭐�������B
- (NSObject<OGStringProtocol>*)ogSubstringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self ogSubstringAtIndex:index];
}

- (NSString*)substringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self substringAtIndex:index];
}

- (NSAttributedString*)attributedSubstringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self attributedSubstringAtIndex:index];
}

// ���O��name�̕���������͈̔�
// ���݂��Ȃ����O�̏ꍇ�� {NSNotFound, 0} ��Ԃ��B
// ����̖��O�������������񂪕�������ꍇ�͗�O�𔭐�������B
- (NSRange)rangeOfSubstringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return NSMakeRange(NSNotFound, 0);
	
	return [self rangeOfSubstringAtIndex:index];
}

// ���O��name�̕����������index
// ���݂��Ȃ��ꍇ��-1��Ԃ�
// ����̖��O�������������񂪕�������ꍇ�͗�O�𔭐�������B
- (unsigned)indexOfSubstringNamed:(NSString*)name
{
	int	index = [[_enumerator regularExpression] groupIndexForName:name];
	if (index == -2) {
		// ����̖��O�������������񂪕�������ꍇ�͗�O�𔭐�������B
		[NSException raise:OgreMatchException format:@"multiplex definition name <%@> call", name];
	}
	
	return index;
}

// index�Ԗڂ̕���������̖��O
// ���݂��Ȃ����O�̏ꍇ�� nil ��Ԃ��B
- (NSString*)nameOfSubstringAtIndex:(unsigned)index
{
	return [[_enumerator regularExpression] nameForGroupIndex:index];
}



// �}�b�`��������������̂����O���[�v�ԍ����ŏ��̂���
- (unsigned)indexOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	unsigned	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (index = aRange.location; index < count; index++) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // �ǂ̕������ɂ��}�b�`���Ȃ������ꍇ
}

- (NSString*)nameOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfFirstMatchedSubstringInRange:aRange]];
}


// �}�b�`��������������̂����O���[�v�ԍ����ő�̂���
- (unsigned)indexOfLastMatchedSubstringInRange:(NSRange)aRange
{
	unsigned	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (index = count - 1; index >= aRange.location; index--) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // �ǂ̕������ɂ��}�b�`���Ȃ������ꍇ
}

- (NSString*)nameOfLastMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLastMatchedSubstringInRange:aRange]];
}


// �}�b�`��������������̂����Œ��̂���
- (unsigned)indexOfLongestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	unsigned	maxLength = 0;
	unsigned	maxIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != NSNotFound) && ((maxLength < range.length) || !matched)) {
			matched = YES;
			maxLength = range.length;
			maxIndex = i;
		}
	}
	
	return maxIndex;
}

- (NSString*)nameOfLongestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLongestSubstringInRange:aRange]];
}


// �}�b�`��������������̂����ŒZ�̂���
- (unsigned)indexOfShortestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	unsigned	minLength = 0;
	unsigned	minIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != NSNotFound) && ((minLength > range.length) || !matched)) {
			matched = YES;
			minLength = range.length;
			minIndex = i;
		}
	}
	
	return minIndex;
}

- (NSString*)nameOfShortestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfShortestSubstringInRange:aRange]];
}

// �}�b�`��������������̂����O���[�v�ԍ����ŏ��̂��� (�Ȃ��ꍇ��0��Ԃ�)
- (unsigned)indexOfFirstMatchedSubstring
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// ���̖��O
- (NSString*)nameOfFirstMatchedSubstring
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// �}�b�`��������������̂����O���[�v�ԍ����ő�̂��� (�Ȃ��ꍇ��0��Ԃ�)
- (unsigned)indexOfLastMatchedSubstring
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfLastMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// ���̖��O
- (NSString*)nameOfLastMatchedSubstring
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLastMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// �}�b�`��������������̂����Œ��̂��� (�Ȃ��ꍇ��0��Ԃ��B���������̕�����������΁A�ԍ��̏����������D�悳���)
- (unsigned)indexOfLongestSubstring
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfLongestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfLongestSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// ���̖��O
- (NSString*)nameOfLongestSubstring
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLongestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLongestSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// �}�b�`��������������̂����ŒZ�̂��� (�Ȃ��ꍇ��0��Ԃ��B���������̕�����������΁A�ԍ��̏����������D�悳���)
- (unsigned)indexOfShortestSubstring
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfShortestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfShortestSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// ���̖��O
- (NSString*)nameOfShortestSubstring
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfShortestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfShortestSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

/******************
* Capture History *
*******************/
// �ߊl����
// �������Ȃ��ꍇ��nil��Ԃ��B
- (OGRegularExpressionCapture*)captureHistory
{
	if (_region->history_root == NULL) return nil;
	
	return [[[OGRegularExpressionCapture allocWithZone:[self zone]] 
        initWithTreeNode:_region->history_root 
        index:0 
        level:0 
        parentNode:nil 
        match:self] autorelease];
}

@end
