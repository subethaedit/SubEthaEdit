//  SEEDividerListItem.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 02/12/2020.

#import "SEEDividerListItem.h"

@implementation SEEDividerListItem

@synthesize image;
@synthesize name;

- (NSString *)uid {
    return [NSString stringWithFormat:@"com.subethaedit.%@", NSStringFromClass(self.class)];
}

- (void)itemAction:(id)sender { }

@end
