//
//  ParticipantsView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 12 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface ParticipantsView : NSView {
    id I_delegate;
    id I_dataSource;
    
    NSArray *I_categories;
}

- (void)setDataSource:(id)dataSource;
- (id)dataSource;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (void)noteEnclosingScrollView;
- (void)resizeToFit;

@end


@interface NSObject (ParticipantsViewDataSourceAdditions)

- (int)participantsViewNumberOfCategories:(ParticipantsView *)participantsView;
- (NSString *)participantsView:(ParticipantsView *)participantsView labelOfCategory:(NSString *)category;
- (int)participantsView:(ParticipantsView *)participantsView numberOfItemsInCategory:(NSString *)category;

@end