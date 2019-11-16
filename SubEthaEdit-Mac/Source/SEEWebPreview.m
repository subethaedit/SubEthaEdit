//
//  SEEWebPreview.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 16.11.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "SEEWebPreview.h"

@implementation SEEWebPreview {
    NSString *script;
    NSURL *scriptURL;
    JSVirtualMachine *vm;
    JSContext *ctx;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    self = [super init];
    if (self) {
        NSError *error = nil;

        scriptURL = [url copy];

        script = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

        vm = [[JSVirtualMachine alloc] init];
        ctx = [[JSContext alloc] initWithVirtualMachine:vm];
        [ctx evaluateScript:script withSourceURL:scriptURL];

        if (ctx.exception) {
            return nil;
        }

        if (error) {
            return nil;
        }
    }
    return self;
}

- (NSString *)webPreviewForText:(NSString *)text {
    JSValue *result = [ctx.globalObject invokeMethod:@"webPreview" withArguments:@[ text ]];
    NSString *preview = nil;

    if (result.isString) {
        preview = [result toString];
    }

    return preview;
}

@end
