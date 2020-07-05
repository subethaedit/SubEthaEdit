//  SEEFontForwardingTextView.m
//  SubEthaEdit
//
//  Created by dom on 05.07.2020.

#import "SEEFontForwardingTextView.h"

@implementation SEEFontForwardingTextView

- (void)changeFont:(id)sender {
    id delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(changeFont:)]) {
        [delegate changeFont:sender];
    } else {
        [super changeFont:sender];
    }
}

@end
