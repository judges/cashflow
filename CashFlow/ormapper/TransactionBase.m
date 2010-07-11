// Generated by O/R mapper generator ver 0.1

#import "Database.h"
#import "TransactionBase.h"

@implementation TransactionBase

@synthesize asset;
@synthesize dst_asset;
@synthesize date;
@synthesize type;
@synthesize category;
@synthesize value;
@synthesize description;
@synthesize memo;

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [date release];
    [description release];
    [memo release];
    [super dealloc];
}

/**
  @brief Migrate database table

  @return YES - table was newly created, NO - table already exists
*/

+ (BOOL)migrate
{
    NSArray *columnTypes = [NSArray arrayWithObjects:
        @"asset", @"INTEGER",
        @"dst_asset", @"INTEGER",
        @"date", @"DATE",
        @"type", @"INTEGER",
        @"category", @"INTEGER",
        @"value", @"REAL",
        @"description", @"TEXT",
        @"memo", @"TEXT",
        nil];

    return [super migrate:columnTypes];
}

/**
  @brief get all records matche the conditions

  @param cond Conditions (WHERE phrase and so on)
  @return array of records
*/
+ (NSMutableArray *)find_cond:(NSString *)cond
{
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    Database *db = [Database instance];
    dbstmt *stmt;

    NSString *sql;
    if (cond == nil) {
        sql = @"SELECT * FROM Transactions;";
    } else {
        sql = [NSString stringWithFormat:@"SELECT * FROM Transactions %@;", cond];
    }  

    stmt = [db prepare:sql];
    while ([stmt step] == SQLITE_ROW) {
        TransactionBase *e = [[[TransactionBase alloc] init] autorelease];
        [e _loadRow:stmt];
        [array addObject:e];
    }
    return array;
}

/**
  @brief get the record matchs the id

  @param pid Primary key of the record
  @return record
*/
+ (TransactionBase *)find:(int)pid
{
    Database *db = [Database instance];

    dbstmt *stmt = [db prepare:@"SELECT * FROM Transactions WHERE key = ?;"];
    [stmt bindInt:0 val:pid];
    if ([stmt step] != SQLITE_ROW) {
        return nil;
    }

    TransactionBase *e = [[[TransactionBase alloc] init] autorelease];
    [e _loadRow:stmt];
 
    return e;
}

- (void)_loadRow:(dbstmt *)stmt
{
    self.pid = [stmt colInt:0];
    self.asset = [stmt colInt:1];
    self.dst_asset = [stmt colInt:2];
    self.date = [stmt colDate:3];
    self.type = [stmt colInt:4];
    self.category = [stmt colInt:5];
    self.value = [stmt colDouble:6];
    self.description = [stmt colString:7];
    self.memo = [stmt colString:8];

    isInserted = YES;
}

+ (NSString *)tableName
{
    return @"Transactions";
}

- (void)insert
{
    [super insert];

    Database *db = [Database instance];
    dbstmt *stmt;
    
    [db beginTransaction];
    stmt = [db prepare:@"INSERT INTO Transactions VALUES(NULL,?,?,?,?,?,?,?,?);"];

    [stmt bindInt:0 val:asset];
    [stmt bindInt:1 val:dst_asset];
    [stmt bindDate:2 val:date];
    [stmt bindInt:3 val:type];
    [stmt bindInt:4 val:category];
    [stmt bindDouble:5 val:value];
    [stmt bindString:6 val:description];
    [stmt bindString:7 val:memo];
    [stmt step];

    self.pid = [db lastInsertRowId];

    [db commitTransaction];
    isInserted = YES;
}

- (void)update
{
    [super update];

    Database *db = [Database instance];
    [db beginTransaction];

    dbstmt *stmt = [db prepare:@"UPDATE Transactions SET "
        "asset = ?"
        ",dst_asset = ?"
        ",date = ?"
        ",type = ?"
        ",category = ?"
        ",value = ?"
        ",description = ?"
        ",memo = ?"
        " WHERE key = ?;"];
    [stmt bindInt:0 val:asset];
    [stmt bindInt:1 val:dst_asset];
    [stmt bindDate:2 val:date];
    [stmt bindInt:3 val:type];
    [stmt bindInt:4 val:category];
    [stmt bindDouble:5 val:value];
    [stmt bindString:6 val:description];
    [stmt bindString:7 val:memo];
    [stmt bindInt:8 val:pid];

    [stmt step];
    [db commitTransaction];
}

/**
  @brief Delete record
*/
- (void)delete
{
    Database *db = [Database instance];

    dbstmt *stmt = [db prepare:@"DELETE FROM Transactions WHERE key = ?;"];
    [stmt bindInt:0 val:pid];
    [stmt step];
}

/**
  @brief Delete all records
*/
+ (void)delete_cond:(NSString *)cond
{
    Database *db = [Database instance];

    if (cond == nil) {
        cond = @"";
    }
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Transactions %@;", cond];
    [db exec:sql];
}

+ (void)delete_all
{
    [TransactionBase delete_cond:nil];
}

@end
