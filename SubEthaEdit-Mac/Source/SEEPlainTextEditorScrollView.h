//  SEEPlainTextEditorScrollView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 15 2004.
//  Recrafted by Michael Ehrmannn on Tue Jan 21 2014.
//

#import <Cocoa/Cocoa.h>


@interface SEEPlainTextEditorScrollView : NSScrollView {
}

@property (nonatomic, assign) CGFloat topOverlayHeight;
@property (nonatomic, assign) CGFloat bottomOverlayHeight;

/** Use the following property names in the User Defined Runtime Attributes in Interface Builder to set up your SEEPlainTextEditorScrollView on the fly. */
@property (nonatomic, strong) NSNumber *topOverlayHeightNumber;
@property (nonatomic, strong) NSNumber *bottomOverlayHeightNumber;

@end
