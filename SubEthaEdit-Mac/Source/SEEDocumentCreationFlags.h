//  SEEDocumentCreationFlags.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.03.14.

#import <Foundation/Foundation.h>

@interface SEEDocumentCreationFlags : NSObject

@property (nonatomic, assign) BOOL openInTab;
@property (nonatomic, assign) BOOL isAlternateAction;
@property (nonatomic, weak) NSWindow *tabWindow;

@end
