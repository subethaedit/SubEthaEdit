//  SEEStyleSheetSettings.m
//  SubEthaEdit
//
//  Created by dom on 24.03.11.

// helper class to manage style sheet preferences for a mode
// internal defaults structure
// "StyleSheets" => {"single" => SingleStyleSheetName, "multiple" => {<context> => <stylesheetname>}, "usesMultipleStyle" => BOOL}

NSString * const SEEStyleSheetSettingsSingleStyleSheetKey        = @"single";
NSString * const SEEStyleSheetSettingsMultipleStyleSheetsKey     = @"multiple";
NSString * const SEEStyleSheetSettingsUsesMultipleStyleSheetsKey = @"usesMultiple";


#import "SEEStyleSheetSettings.h"
#import "DocumentModeManager.h"
#import "SyntaxDefinition.h"

@interface SEEStyleSheetSettings () {
    NSMutableDictionary *_styleSheetNamesByLanguageContext;
}
@end
    
@implementation SEEStyleSheetSettings

- (void)takeSettingsFromModeDefaults {
	NSDictionary *sheetPrefsDict = [self.documentMode defaultForKey:DocumentModeStyleSheetsPreferenceKey];
	if (!sheetPrefsDict && self.documentMode.isBaseMode) {
		self.usesMultipleStyleSheets = NO;
		self.singleStyleSheetName = [DocumentModeManager defaultStyleSheetName];
	} else {
		self.usesMultipleStyleSheets = [[sheetPrefsDict objectForKey:SEEStyleSheetSettingsUsesMultipleStyleSheetsKey] boolValue];
		NSString *value = [sheetPrefsDict objectForKey:SEEStyleSheetSettingsSingleStyleSheetKey];
		if (value) self.singleStyleSheetName = value;
		NSDictionary *sheetMapping = [sheetPrefsDict objectForKey:SEEStyleSheetSettingsMultipleStyleSheetsKey];
		if (sheetMapping && [sheetMapping isKindOfClass:[NSDictionary class]]) {
			[_styleSheetNamesByLanguageContext removeAllObjects];
			[_styleSheetNamesByLanguageContext addEntriesFromDictionary:sheetMapping];
		}
	}
}

- (void)pushSettingsToModeDefaults {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (self.singleStyleSheetName) [result setObject:self.singleStyleSheetName forKey:SEEStyleSheetSettingsSingleStyleSheetKey];
	[result setObject:[_styleSheetNamesByLanguageContext copy] forKey:SEEStyleSheetSettingsMultipleStyleSheetsKey];
	[result setObject:[NSNumber numberWithBool:self.usesMultipleStyleSheets] forKey:SEEStyleSheetSettingsUsesMultipleStyleSheetsKey];
	[[self.documentMode defaults] setObject:result forKey:DocumentModeStyleSheetsPreferenceKey];
}

- (instancetype)initWithDocumentMode:(DocumentMode *)aMode {
	if ((self=[super init])) {
		_styleSheetNamesByLanguageContext = [NSMutableDictionary new];
		self.documentMode = aMode;
		self.singleStyleSheetName = [DocumentModeManager defaultStyleSheetName]; // default
		[self takeSettingsFromModeDefaults];
	}
	return self;
}

- (SEEStyleSheet *)styleSheetForLanguageContext:(NSString *)aLanguageContext {
	DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
	SEEStyleSheet *result = nil;
	if (self.usesMultipleStyleSheets) {
		NSString *sheetName = [_styleSheetNamesByLanguageContext objectForKey:aLanguageContext];
		if (sheetName) {
			result = [modeManager styleSheetForName:sheetName];
		}
	}
	
	if (!self.usesMultipleStyleSheets || !result) {
		result = [modeManager styleSheetForName:self.singleStyleSheetName];
	}
	if (!result) {
		result = [modeManager styleSheetForName:[DocumentModeManager defaultStyleSheetName]];
		[self resetStyleSheetForLanguageContext:aLanguageContext];
	}
	return result;
}

#pragma mark
- (void)resetStyleSheetForLanguageContext:(NSString *)aLanguageContext {
	// there is no style sheet for multi or single -> reset what needs resetting to default
	
	if (self.usesMultipleStyleSheets) {
		// TODO: if style sheet per lang context is ever turned back on: test this again
		[_styleSheetNamesByLanguageContext removeObjectForKey:aLanguageContext];
		
	} else {
		self.singleStyleSheetName = [DocumentModeManager defaultStyleSheetName];
		if (![self.documentMode isBaseMode]) {
			[[self.documentMode defaults] setObject:@YES forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];			
		}
	}
	[self pushSettingsToModeDefaults];
}

#pragma mark
- (SEEStyleSheet *)topLevelStyleSheet {
	return [self styleSheetForLanguageContext:self.documentMode.syntaxDefinition.mainLanguageContext];
}

- (NSColor *)documentForegroundColor {
	SEEStyleSheet *topLevelStyleSheet = [self topLevelStyleSheet];
	return topLevelStyleSheet.documentForegroundColor;
}

- (NSColor *)documentBackgroundColor {
	SEEStyleSheet *topLevelStyleSheet = [self topLevelStyleSheet];
	return topLevelStyleSheet.documentBackgroundColor;
}

- (void)setStyleSheetName:(NSString *)aStyleSheetName forLanguageContext:(NSString *)aLanguageContext {
	[_styleSheetNamesByLanguageContext setObject:aStyleSheetName forKey:aLanguageContext];
}

- (NSString *)styleSheetNameForLanguageContext:(NSString *)aLanguageContext {
	NSString *styleSheetName = [_styleSheetNamesByLanguageContext objectForKey:aLanguageContext];
	if (!styleSheetName) styleSheetName = self.singleStyleSheetName;
	return styleSheetName;
}

@end
