//  SEEDocumentCreationFlags.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.03.14.

#import <Foundation/Foundation.h>

@interface SEEDocumentCreationFlags : NSObject

@property (nonatomic) BOOL openInTab;
@property (nonatomic) BOOL isAlternateAction;
@property (nonatomic, weak) NSWindow *tabWindow;

@end
