//  FoldedTextAttachment.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.

#import <Cocoa/Cocoa.h>


@interface FoldedTextAttachment : NSTextAttachment

@property (nonatomic) NSRange foldedTextRange;
@property (nonatomic, readonly) NSMutableArray *innerAttachments;

- (instancetype)initWithFoldedTextRange:(NSRange)inFoldedTextRange;
- (void)moveAttachmentLocation:(int)inLocationDifference;
@end

