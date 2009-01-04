#import <Cocoa/Cocoa.h>

@interface MultiplePageView : NSView {
    NSPrintInfo *printInfo;
    NSColor *lineColor;
    NSColor *marginColor;
    NSUInteger numPages;
}

- (void)setPrintInfo:(NSPrintInfo *)anObject;
- (NSPrintInfo *)printInfo;
- (CGFloat)pageSeparatorHeight;
- (NSSize)documentSizeInPage;	/* Returns the area where the document can draw */
- (NSRect)documentRectForPageNumber:(NSUInteger)pageNumber;	/* First page is page 0 */
- (NSRect)pageRectForPageNumber:(NSUInteger)pageNumber;	/* First page is page 0 */
- (void)setNumberOfPages:(NSUInteger)num;
- (NSUInteger)numberOfPages;
- (void)setLineColor:(NSColor *)color;
- (NSColor *)lineColor;
- (void)setMarginColor:(NSColor *)color;
- (NSColor *)marginColor;

@end
