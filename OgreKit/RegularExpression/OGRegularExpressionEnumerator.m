/*
 * Name: OGRegularExpressionEnumerator.m
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGString.h>


// ���g��encoding/decoding���邽�߂�key
static NSString	* const OgreRegexKey               = @"OgreEnumeratorRegularExpression";
static NSString	* const OgreSwappedTargetStringKey = @"OgreEnumeratorSwappedTargetString";
static NSString	* const OgreStartOffsetKey         = @"OgreEnumeratorStartOffset";
static NSString	* const OgreStartLocationKey       = @"OgreEnumeratorStartLocation";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreEnumeratorTerminalOfLastMatch";
static NSString	* const OgreIsLastMatchEmptyKey    = @"OgreEnumeratorIsLastMatchEmpty";
static NSString	* const OgreOptionsKey             = @"OgreEnumeratorOptions";
static NSString	* const OgreNumberOfMatchesKey     = @"OgreEnumeratorNumberOfMatches";

NSString	* const OgreEnumeratorException = @"OGRegularExpressionEnumeratorException";

@implementation OGRegularExpressionEnumerator

// ��������
- (id)nextObject
{
	int					r;
	unichar             *start, *range, *end;
	OnigRegion			*region;
	id					match = nil;
	unsigned			UTF16charlen = 0;
	
	/* �S�ʓI�ɏ��������\�� */
	if ( _terminalOfLastMatch == -1 ) {
		// �}�b�`�I��
		return nil;
	}
	
	start = _UTF16TargetString + _startLocation; // search start address of target string
	end = _UTF16TargetString + _lengthOfTargetString; // terminate address of target string
	range = end;	// search terminate address of target string
	if (start > range) {
		// ����ȏ㌟���͈͂̂Ȃ��ꍇ
		_terminalOfLastMatch = -1;
		return nil;
	}
	
	// compile�I�v�V����(OgreFindNotEmptyOption��ʂɈ���)
	BOOL	findNotEmpty;
	if (([_regex options] & OgreFindNotEmptyOption) == 0) {
		findNotEmpty = NO;
	} else {
		findNotEmpty = YES;
	}
	
	// search�I�v�V����(OgreFindEmptyOption��ʂɈ���)
	BOOL		findEmpty;
	unsigned	searchOptions;
	if ((_searchOptions & OgreFindEmptyOption) == 0) {
		findEmpty = NO;
		searchOptions = _searchOptions;
	} else {
		findEmpty = YES;
		searchOptions = _searchOptions & ~OgreFindEmptyOption;  // turn off OgreFindEmptyOption
	}
	
	// region�̍쐬
	region = onig_region_new();
	if ( region == NULL ) {
		// ���������m�ۂł��Ȃ������ꍇ�A��O�𔭐�������B
		[NSException raise:NSMallocException format:@"fail to create a region"];
	}
	
	/* ���� */
	regex_t*	regexBuffer = [_regex patternBuffer];
	
	int	counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (!findNotEmpty) {
		/* �󕶎���ւ̃}�b�`�������ꍇ */
		r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, searchOptions);
		
		// OgreFindEmptyOption���w�肳��Ă��Ȃ��ꍇ�ŁA
		// �O��󕶎���ȊO�Ƀ}�b�`���āA����󕶎���Ƀ}�b�`�����ꍇ�A1�������炵�Ă���1�x�}�b�`�����݂�B
		if (!findEmpty && (!_isLastMatchEmpty) && (r >= 0) && (region->beg[0] == region->end[0]) && (_startLocation > 0)) {
			if (start < range) {
				UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _startLocation);
				_startLocation += UTF16charlen; // 1�����i�߂�
				start = _UTF16TargetString + _startLocation;
				r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, searchOptions);
			} else {
				r = ONIG_MISMATCH;
			}
		}
		
	} else {
		/* �󕶎���ւ̃}�b�`�������Ȃ��ꍇ */
		while (TRUE) {
			r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, searchOptions);
			if ((r >= 0) && (region->beg[0] == region->end[0]) && (start < range)) {
				// �󕶎���Ƀ}�b�`�����ꍇ
				UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _startLocation);
				_startLocation += UTF16charlen;	// 1�����i�߂�
				start = _UTF16TargetString + _startLocation;
			} else {
				// ����ȏ�i�߂Ȃ��ꍇ�E�󕶎���ȊO�Ƀ}�b�`�����ꍇ�E�}�b�`�Ɏ��s�����ꍇ
				break;
			}
		
			counterOfAutorelease++;
			if (counterOfAutorelease % 100 == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
		}
		if ((r >= 0) && (region->beg[0] == region->end[0]) && (start >= range)) {
			// �Ō�ɋ󕶎���Ƀ}�b�`�����ꍇ�B�~�X�}�b�`�����Ƃ���B
			r = ONIG_MISMATCH;
		}
	}
	
	[pool release];
	
	if (r >= 0) {
		// �}�b�`�����ꍇ
		// match�I�u�W�F�N�g�̍쐬
		match = [[[OGRegularExpressionMatch allocWithZone:[self zone]] 
				initWithRegion: region 
				index: _numberOfMatches
				enumerator: self
				terminalOfLastMatch: _terminalOfLastMatch
			] autorelease];
		
		_numberOfMatches++;	// �}�b�`���𑝉�
		
		/* �}�b�`����������̏I�[�ʒu */
		if ( (r == _lengthOfTargetString * sizeof(unichar)) && (r == region->end[0]) ) {
			_terminalOfLastMatch = -1;	// �Ō�ɋ󕶎���Ƀ}�b�`�����ꍇ�́A����ȏ�}�b�`���Ȃ��B
			_isLastMatchEmpty = YES;	// ����Ȃ����낤���O�̂��߁B

			return match;
		} else {
			_terminalOfLastMatch = region->end[0] / sizeof(unichar);	// �Ō�Ƀ}�b�`����������̏I�[�ʒu
		}

		/* ����̃}�b�`�J�n�ʒu�����߂� */
		_startLocation = _terminalOfLastMatch;
		
		/* UTF16String�ł̊J�n�ʒu */
		if (r == region->end[0]) {
			// �󕶎���Ƀ}�b�`�����ꍇ�A����̃}�b�`�J�n�ʒu��1������ɐi�߂�B
			_isLastMatchEmpty = YES;
			UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _terminalOfLastMatch);
			_startLocation += UTF16charlen;
		} else {
			// ��łȂ������ꍇ�͐i�߂Ȃ��B
			_isLastMatchEmpty = NO;
		}
		
		return match;
	}
	
	onig_region_free(region, 1 /* free self */);	// �}�b�`���Ȃ������������region���J���B
	
	if (r == ONIG_MISMATCH) {
		// �}�b�`���Ȃ������ꍇ
		_terminalOfLastMatch = -1;
	} else {
		// �G���[�B��O�𔭐�������B
		unsigned char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		[NSException raise:OgreEnumeratorException format:@"%s", s];
	}
	return nil;	// �}�b�`���Ȃ������ꍇ
}

- (NSArray*)allObjects
{	
#ifdef DEBUG_OGRE
	NSLog(@"-allObjects of %@", [self className]);
#endif

	NSMutableArray	*matchArray = [NSMutableArray arrayWithCapacity:10];

	int			orgTerminalOfLastMatch = _terminalOfLastMatch;
	BOOL		orgIsLastMatchEmpty = _isLastMatchEmpty;
	unsigned	orgStartLocation = _startLocation;
	unsigned	orgNumberOfMatches = _numberOfMatches;
	
	_terminalOfLastMatch = 0;
	_isLastMatchEmpty = NO;
	_startLocation = 0;
	_numberOfMatches = 0;
			
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	OGRegularExpressionMatch	*match;
	int matches = 0;
	while ( (match = [self nextObject]) != nil ) {
		[matchArray addObject:match];
		matches++;
		if ((matches % 100) == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[pool release];
	
	_terminalOfLastMatch = orgTerminalOfLastMatch;
	_isLastMatchEmpty = orgIsLastMatchEmpty;
	_startLocation = orgStartLocation;
	_numberOfMatches = orgNumberOfMatches;

	if (matches == 0) {
		// not found
		return nil;
	} else {
		// found something
		return matchArray;
	}
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
	//OGRegularExpression	*_regex;							// ���K�\���I�u�W�F�N�g
	//NSString				*_TargetString;				// �����Ώە�����
	//NSRange				_searchRange;						// �����͈�
	//unsigned              _searchOptions;						// �����I�v�V����
	//int					_terminalOfLastMatch;               // �O��Ƀ}�b�`����������̏I�[�ʒu (_region->end[0] / sizeof(unichar))
	//unsigned              _startLocation;						// �}�b�`�J�n�ʒu
	//BOOL					_isLastMatchEmpty;					// �O��̃}�b�`���󕶎��񂾂������ǂ���
    //unsigned              _numberOfMatches;                   // �}�b�`������
    
    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _regex forKey: OgreRegexKey];
		[encoder encodeObject: _targetString forKey: OgreSwappedTargetStringKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchRange.location] forKey: OgreStartOffsetKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchOptions] forKey: OgreOptionsKey];
		[encoder encodeObject: [NSNumber numberWithInt:_terminalOfLastMatch] forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_startLocation] forKey: OgreStartLocationKey];
		[encoder encodeObject: [NSNumber numberWithBool:_isLastMatchEmpty] forKey: OgreIsLastMatchEmptyKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_numberOfMatches] forKey: OgreNumberOfMatchesKey];
	} else {
		[encoder encodeObject: _regex];
		[encoder encodeObject: _targetString];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchRange.location]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchOptions]];
		[encoder encodeObject: [NSNumber numberWithInt:_terminalOfLastMatch]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_startLocation]];
		[encoder encodeObject: [NSNumber numberWithBool:_isLastMatchEmpty]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_numberOfMatches]];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	id		anObject;	
	BOOL	allowsKeyedCoding = [decoder allowsKeyedCoding];


	//OGRegularExpression	*_regex;							// ���K�\���I�u�W�F�N�g
    if (allowsKeyedCoding) {
		_regex = [[decoder decodeObjectForKey: OgreRegexKey] retain];
	} else {
		_regex = [[decoder decodeObject] retain];
	}
	if (_regex == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	
	//NSString			*_targetString;				// �����Ώە�����B\������ւ���Ă���(��������)�̂Œ���
	//unichar           *_UTF16TargetString;			// UTF16�ł̌����Ώە�����
	//unsigned          _lengthOfTargetString;       // [_targetString length]
    if (allowsKeyedCoding) {
		_targetString = [[decoder decodeObjectForKey: OgreSwappedTargetStringKey] retain];	// [self targetString]�ł͂Ȃ��B
	} else {
		_targetString = [[decoder decodeObject] retain];
	}
	if (_targetString == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	NSString	*targetPlainString = [_targetString string];
	_lengthOfTargetString = [targetPlainString length];
    
	_UTF16TargetString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * _lengthOfTargetString);
    if (_UTF16TargetString == NULL) {
		// �G���[�B��O�𔭐�������B
        [self release];
        [NSException raise:NSInvalidUnarchiveOperationException format:@"fail to allocate a memory"];
    }
    [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
	
	// NSRange				_searchRange;						// �����͈�
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreStartOffsetKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_searchRange.location = [anObject unsignedIntValue];
	_searchRange.length = _lengthOfTargetString;
	
	
	
	// 	_searchOptions;			// �����I�v�V����
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreOptionsKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_searchOptions = [anObject unsignedIntValue];
	
	
	// int	_terminalOfLastMatch;	// �O��Ƀ}�b�`����������̏I�[�ʒu (_region->end[0] / sizeof(unichar))
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
	_terminalOfLastMatch = [anObject intValue];
	
	
	//			_startLocation;						// �}�b�`�J�n�ʒu
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreStartLocationKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_startLocation = [anObject unsignedIntValue];
    	

	//BOOL				_isLastMatchEmpty;					// �O��̃}�b�`���󕶎��񂾂������ǂ���
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIsLastMatchEmptyKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_isLastMatchEmpty = [anObject boolValue];
	
	
	//	unsigned			_numberOfMatches;					// �}�b�`������
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreNumberOfMatchesKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// �G���[�B��O�𔭐�������B
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_numberOfMatches = [anObject unsignedIntValue];
	
	
	return self;
}


// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	id	newObject = [[[self class] allocWithZone:zone] 
			initWithOGString: _targetString 
			options: _searchOptions
			range: _searchRange 
			regularExpression: _regex];
			
	// �l�̃Z�b�g
	[newObject _setTerminalOfLastMatch: _terminalOfLastMatch];
	[newObject _setStartLocation: _startLocation];
	[newObject _setIsLastMatchEmpty: _isLastMatchEmpty];
	[newObject _setNumberOfMatches: _numberOfMatches];

	return newObject;
}

// description
- (NSString*)description
{
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			_regex, 	// ���K�\���I�u�W�F�N�g
			_targetString,
			[NSString stringWithFormat:@"(%d, %d)", _searchRange.location, _searchRange.length], 	// �����͈�
			[[_regex class] stringsForOptions:_searchOptions], 	// �����I�v�V����
			[NSNumber numberWithInt:_terminalOfLastMatch],	// �O��Ƀ}�b�`����������̏I�[�ʒu���O�̕�����̒���
			[NSNumber numberWithUnsignedInt:_startLocation], 	// �}�b�`�J�n�ʒu
			(_isLastMatchEmpty? @"YES" : @"NO"), 	// �O��̃}�b�`���󕶎��񂾂������ǂ���
			[NSNumber numberWithUnsignedInt:_numberOfMatches], 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			@"Regular Expression", 
            @"Target String", 
			@"Search Range", 
			@"Options", 
			@"Terminal of the Last Match", 
			@"Start Location of the Next Search", 
			@"Was the Last Match Empty", 
			@"Number Of Matches", 
			nil]
		];
		
	return [dictionary description];
}

@end
