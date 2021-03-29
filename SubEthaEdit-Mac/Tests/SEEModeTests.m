//  SEEModeTests.m
//  SubEthaEdit-Tests
//
//  Created by dom on 29.03.2021.

#import <XCTest/XCTest.h>

#import "DocumentModeManager.h"

@interface SEEModeTests : XCTestCase
@end

@implementation SEEModeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDocumentModeManager {
    DocumentMode *base = [[DocumentModeManager sharedInstance] baseMode];
    
    NSLog(@"%s, base: %@",__FUNCTION__,base);

    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
