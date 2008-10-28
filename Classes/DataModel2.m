// -*-  Mode:ObjC; c-basic-offset:4; tab-width:4; indent-tabs-mode:t -*-
/*
  CashFlow for iPhone/iPod touch

  Copyright (c) 2008, Takuya Murakami, All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// SQLite データベース版
// まだ試作中、、、

#import "DataModel.h"
#import <sqlite3.h>

@implementation DataModel

@synthesize transactions, serialCounter;

static sqlite3 *db = nil;
static NSDateFormatter *dateFormatter;

// Factory
+ (DataModel*)allocWithLoad;
{
	DataModel *dm = nil;

	// misc initialization
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];

	// Load from DB
	NSString *dbPath = [CashFlowAppDelegate pathOfDataFile:@"CashFlow.db"];
	if (sqlite3_open([dbPath UTF8String], &db) == 0) {
		dm = [[DataModel alloc] init];
		[dm reloadFromDB];

		return dm;
	}

	// Backward compatibility
	NSString *dataPath = [CashFlowAppDelegate pathOfDataFile:@"Transactions.dat"];

	NSData *data = [NSData dataWithContentsOfFile:dataPath];
	if (data != nil) {
		NSKeyedUnarchiver *ar = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];

		dm = [ar decodeObjectForKey:@"DataModel"];
		if (dm != nil) {
			[dm retain];
			[ar finishDecoding];
		
			[dm recalcBalance];
		}
	}
	if (dm == nil) {
		// initial or some error...
		dm = [[DataModel alloc] init];
	}

	// Ok, create new database
	sqlite3_open_v2([dbPath UTF8String], &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL);
	sqlite3_exec(db, "CREATE TABLE Transactions (key INTEGER PRIMARY KEY, date DATE, type INTEGER,\
value DOUBLE, balance DOUBLE, description TEXT, memo TEXT);", 0, 0);

	[db rewriteToDB];
	return dm;
}

// private
- (void)reloadFromDB
{
	const char *q = "SELECT key, date, type, value, balance, description, memo\
 FROM Transactions ORDER BY date";
		
	sqlite3_stmt *stmt;
	sqlite3_prepare_v2(db, q, strlen(q), &stmt, NULL);

	while (sqlite3_step(stmt) == SQLITE_ROW) {
		Transaction *t = [[Transaction alloc] init];
		t.serial = sqlite3_column_int(stmt, 0);
		char *date = sqlite3_column_text(stmt, 1);
		t.type = sqlite3_column_int(stmt, 2);
		t.value = sqlite3_column_double(stmt, 3);
		t.balance = sqlite3_column_double(stmt, 4);
		char *desc = sqlite3_column_text(stmt, 5);
		char *memo = sqlite3_column_text(stmt, 6);

		t.date = [dateFormatter dateFromString:
						[NSString stringWithCString:date encoding:NSUTF8StringEncoding]];
		t.description = [NSString stringWithCString:desc encoding:NSUTF8StringEncoding];
		t.memo = [NSString stringWithCString:memo encoding:NSUTF8StringEncoding];

		[self insertTransaction:t];
	}
	sqlite3_finalize(stmt);
}

// private
- (void)rewriteToDB
{
	sqlite3_stmt *stmt;

	sqlite3_exec(db, "DELETE * FROM Transactions;", 0, 0);

	int n = [transactions count];
	int i;

	sqlite3_exec(db, "BEGIN;", 0, 0);

	for (i = 0; i < n; i++) {
		Transaction *t = [transactions objectAtIndex:i];
		[self insertTransactionDB:t];
	}

	sqlite3_exec(db, "COMMIT;", 0, 0);
}

- (void)insertTransactionDB:(Transaction*)t
{
	char sql[1024];

	sqlite3_snprintf(sizeof(sql), sql,
					 "INSERT INTO \"Transactions\" VALUES(NULL, %Q, %d, %f, %f, %Q, %Q);",
					 [[dateFormatter stringFromDate:t.date] UTF8String],
					 t.type,
					 t.value,
					 t.balance,
					 [t.description UTF8String],
					 [t.memo UTF8String]);
	sqlite3_exec(db, sql, 0, 0, 0);

	// get primary key
	t.serial = sqlite3_last_insert_rowid(db);
}

- (void)replaceDB:(Transaction*)t
{
	// TBD
}

- (BOOL)saveToStorage
{
	// do nothing
	return YES;
}

- (id)init
{
	[super init];

	transactions = [[NSMutableArray alloc] init];
	serialCounter = 0;

	return self;
}

- (void)dealloc 
{
	[transactions release];
	sqlite3_close(db);

	[super dealloc];
}

- (int)getTransactionCount
{
	return transactions.count;
}

- (Transaction*)getTransactionAt:(int)n
{
	return [transactions objectAtIndex:n];
}

- (void)assignSerial:(Transaction*)tr
{
	// do nothing
	// primary key is assigned by SQLite
}

- (void)insertTransaction:(Transaction*)tr
{
	int i;
	int max = [transactions count];
	Transaction *t = nil;

	// 挿入位置を探す
	for (i = 0; i < max; i++) {
		t = [transactions objectAtIndex:i];
		if ([tr.date compare:t.date] == NSOrderedAscending) {
			break;
		}
	}

	// 挿入
	[transactions insertObject:tr atIndex:i];

	// 全残高再計算
	[self recalcBalance];
	
	// 上限チェック
	if ([transactions count] > MAX_TRANSACTIONS) {
		[self deleteTransactionAt:0];
	}
}

- (void)replaceTransactionAtIndex:(int)index withObject:(Transaction*)t
{
	char sql[1024];

	Transaction *old = [transaction objectAtIndex:index];

	sqlite3_snprintf(sizeof(sql), sql,
					 "UPDATE \"Transactions\" SET date=%Q, type=%d, value=%f, balance=%f, description=%Q, memo=%Q WHERE key = %d",
					 [[dateFormatter stringFromDate:t.date] UTF8String],
					 t.type,
					 t.value,
					 t.balance,
					 [t.description UTF8String],
					 [t.memo UTF8String],
					 old.serial);
	sqlite3_exec(db, sql, 0, 0);

	[transactions replaceObjectAtIndex:index withObject:t];
}

- (void)deleteTransactionAt:(int)n
{
	char sql[128];

	Transaction *t = [transactions objectAtIndex:n];

	sqlite3_snprintf(sizeof(sql), sql,
					 "DELETE * FROM \"Transactions\" WHERE key = %d;", 
					 t.serial);
	sqlite3_exec(db, sql, 0, 0);

	[transactions removeObjectAtIndex:n];
	[self recalcBalance];
}

- (void)deleteOldTransactionsBefore:(NSDate*)date
{
	while (transactions.count > 0) {
		Transaction *t = [transactions objectAtIndex:0];
		if ([t.date compare:date] != NSOrderedAscending) {
			break;
		}

		[self deleteTransactionAt:0];
	}
}

- (int)firstTransactionByDate:(NSDate*)date
{
	for (int i = 0; i < transactions.count; i++) {
		Transaction *t = [transactions objectAtIndex:i];
		if ([t.date compare:date] != NSOrderedAscending) {
			return i;
		}
	}
	return -1;

}


// sort
static int compareByDate(Transaction *t1, Transaction *t2, void *context)
{
	return [t1.date compare:t2.date];
}

- (void)sortByDate
{
	[transactions sortUsingFunction:compareByDate context:NULL];
	[self recalcBalance];
}

- (void)recalcBalance
{
	Transaction *t;
	double bal;
	int max = [transactions count];
	int i;

	if (max == 0) return;

	// Get initial balance from first transaction
	t = [transactions objectAtindex:0];
	bal = t.balance;

	// Recalculate balances
	for (i = 1; i < max; i++) {
		t = [transactions objectAtIndex:i];

		switch (t.type) {
		case TYPE_INCOME:
			bal += t.value;
			t.balance = bal;
			break;

		case TYPE_OUTGO:
			bal -= t.value;
			t.balance = bal;
			break;

		case TYPE_ADJ:
			t.value = t.balance - bal;
			bal = t.balance;
			break;
		}
	}
}

- (double)lastBalance
{
	int max = [transactions count];
	if (max == 0) {
		return 0.0;
	}
	return [[transactions objectAtIndex:max - 1] balance];
}


// Utility
+ (NSString*)currencyString:(double)x
{
	NSNumberFormatter *f = [[[NSNumberFormatter alloc] init] autorelease];
	[f setNumberStyle:NSNumberFormatterCurrencyStyle];
	[f setLocale:[NSLocale currentLocale]];
	NSString *bstr = [f stringFromNumber:[NSNumber numberWithDouble:x]];
	return bstr;
}

- (NSMutableArray *)allocDescList
{
	int i, max;
	max = [transactions count];
	
	NSMutableArray *ary = [[NSMutableArray alloc] init];
	if (max == 0) return ary;
	
	for (i = max - 1; i >= 0; i--) {
		[ary addObject:[[transactions objectAtIndex:i] description]];
	}
	
	[ary sortUsingSelector:@selector(compare:)];
	
	// uniq
	NSString *prev = [ary objectAtIndex:0];
	for (i = 1; i < [ary count]; i++) {
		if ([prev isEqualToString:[ary objectAtIndex:i]]) {
			[ary removeObjectAtIndex:i];
			i--;
		} else {
			prev = [ary objectAtIndex:i];
		}
	}
	
	return ary;
}

//
// Archive / Unarchive
//
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self) {
		self.serialCounter = [decoder decodeIntForKey:@"serialCounter"];
		self.transactions = [decoder decodeObjectForKey:@"Transactions"];
		[self recalcBalance];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:serialCounter forKey:@"serialCounter"];
	[coder encodeObject:transactions forKey:@"Transactions"];
}

@end