#import <OgreKit/OgreAFPCComboBox.h>
#import <OgreKit/OgreAFPCEscapeCharacterFormatter.h>

@implementation OgreAFPCComboBox

/* delegate method of fieldEditor */
- (BOOL)textView:(NSTextView*)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString
{
	// ＼と￥を統一する必要がある場合は統一する。
	NSString   *convertedString = [(OgreAFPCEscapeCharacterFormatter*)[self formatter] stringForObjectValue:replacementString];
	if ([replacementString isEqualToString:convertedString] || (convertedString == nil)) {
		// 変更なし
		return [super textView:aTextView shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
	} else {
		// ＼と￥を統一
		[aTextView replaceCharactersInRange:affectedCharRange withString:convertedString];
		return NO;
	}
}

@end
