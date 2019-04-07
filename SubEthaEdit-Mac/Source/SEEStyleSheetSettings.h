//  SEEStyleSheetSettings.h
//  SubEthaEdit
//
//  Created by dom on 24.03.11.

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"
#import "SEEStyleSheet.h"

@class SEEStyleSheet;
@class DocumentMode;

@interface SEEStyleSheetSettings : NSObject 

@property BOOL usesMultipleStyleSheets;
@property (weak) DocumentMode *documentMode;
@property (copy) NSString *singleStyleSheetName;

- (instancetype)initWithDocumentMode:(DocumentMode *)aMode;

- (SEEStyleSheet *)styleSheetForLanguageContext:(NSString *)aLanguageContext;
- (void)setStyleSheetName:(NSString *)aStyleSheetName forLanguageContext:(NSString *)aLanguageContext;
- (NSString *)styleSheetNameForLanguageContext:(NSString *)aLanguageContext;
- (void)pushSettingsToModeDefaults;

- (NSColor *)documentForegroundColor;
- (NSColor *)documentBackgroundColor;

@end
