//
//  NSMutableAttributedString(ODBAdditions).h
//  FMEditInBBEdit
//
//  Created by August Mueller on Sun Feb 01 2004.
//

#import <Cocoa/Cocoa.h>

@interface NSTextView(FlyOptsODBAdditions)

- (void)fmReplaceCharactersInRange:(NSRange)range withString:(NSString *)string;

@end
