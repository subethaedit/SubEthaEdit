//
//  TextView.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FoldedTextAttachment : NSTextAttachment
{
	NSAttributedString *I_foldedText;
}
- (id)initWithFoldedText:(NSAttributedString *)inFoldedText;
- (NSAttributedString *)foldedText;
@end



@interface TextView : NSTextView {

}

- (void)collapseSelection:(id)inSender;
- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atIndex:(NSUInteger)inIndex;

@end
