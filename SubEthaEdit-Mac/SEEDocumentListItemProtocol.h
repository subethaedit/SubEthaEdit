//
//  SEEDocumentListItemProtocol.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEEDocumentListItem <NSObject>

@property (nonatomic, readonly, strong) NSString *uid;

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSImage *image;

- (IBAction)itemAction:(id)sender;

@end
