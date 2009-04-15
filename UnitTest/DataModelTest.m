// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestCommon.h"
#import "DataModel.h"

@interface DataModelTest : SenTestCase {
}
@end

@implementation DataModelTest

- (void)setUp
{
    //[DataModel initialize];
    //    db = [Database instance];
    //	[TestUtility initializeTestDatabase];
    //    dm = [DataModel sharedDataModel];
}

- (void)tearDown
{
    //	[dm release];
}

// データが
- (void)testLoadDB
{
    [DataModel finalize];

    // テストデータを読み込ませる
    [DataModel initialize];

    STAssertNotNil(theDataModel, nil);

#if 0
    [dm loadDB];

    // 先頭に All Shelf があることを確認する
    STAssertTrue([dm shelvesCount] >= 1, nil); // TBD
    Shelf *shelf = [dm shelfAtIndex:0];
    STAssertNotNil(shelf, nil);
#endif
}

@end