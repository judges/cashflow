// Generated by O/R mapper generator ver 0.1

#import "Database.h"
#import "Assets.h"

@implementation Assets

@synthesize name;
@synthesize type;
@synthesize initialBalance;
@synthesize sorder;

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [name release];
    [super dealloc];
}

/**
  @brief Migrate database table

  @return YES - table was newly created, NO - table already exists
*/

+ (BOOL)migrate
{
    NSArray *columnTypes = [NSArray arrayWithObjects:
        @"name", @"TEXT",
        @"type", @"INTEGER",
        @"initialBalance", @"REAL",
        @"sorder", @"INTEGER",
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
        sql = @"SELECT * FROM Assets;";
    } else {
        sql = [NSString stringWithFormat:@"SELECT * FROM Assets %@;", cond];
    }  

    stmt = [db prepare:sql];
    while ([stmt step] == SQLITE_ROW) {
        Assets *e = [[[Assets alloc] init] autorelease];
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
+ (Assets *)find:(int)pid
{
    Database *db = [Database instance];

    dbstmt *stmt = [db prepare:@"SELECT * FROM Assets WHERE key = ?;"];
    [stmt bindInt:0 val:pid];
    if ([stmt step] != SQLITE_ROW) {
        return nil;
    }

    Assets *e = [[[Assets alloc] init] autorelease];
    [e _loadRow:stmt];
 
    return e;
}

- (void)_loadRow:(dbstmt *)stmt
{
    self.pid = [stmt colInt:0];
    self.name = [stmt colString:1];
    self.type = [stmt colInt:2];
    self.initialBalance = [stmt colDouble:3];
    self.sorder = [stmt colInt:4];

    isInserted = YES;
}

+ (NSString *)tableName
{
    return @"Assets";
}

- (void)insert
{
    [super insert];

    Database *db = [Database instance];
    dbstmt *stmt;
    
    [db beginTransaction];
    stmt = [db prepare:@"INSERT INTO Assets VALUES(NULL,?,?,?,?);"];

    [stmt bindString:0 val:name];
    [stmt bindInt:1 val:type];
    [stmt bindDouble:2 val:initialBalance];
    [stmt bindInt:3 val:sorder];
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

    dbstmt *stmt = [db prepare:@"UPDATE Assets SET "
        "name = ?"
        ",type = ?"
        ",initialBalance = ?"
        ",sorder = ?"
        " WHERE key = ?;"];
    [stmt bindString:0 val:name];
    [stmt bindInt:1 val:type];
    [stmt bindDouble:2 val:initialBalance];
    [stmt bindInt:3 val:sorder];
    [stmt bindInt:4 val:pid];

    [stmt step];
    [db commitTransaction];
}

/**
  @brief Delete record
*/
- (void)delete
{
    Database *db = [Database instance];

    dbstmt *stmt = [db prepare:@"DELETE FROM Assets WHERE key = ?;"];
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
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Assets %@;", cond];
    [db exec:sql];
}

+ (void)delete_all
{
    [Assets delete_cond:nil];
}

@end
