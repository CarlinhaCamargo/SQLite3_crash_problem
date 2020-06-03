//
//  ViewController.m
//  TesteSQLite3
//
//  Created by Carla de Oliveira Camargo on 28/05/20.
//  Copyright © 2020 Carla de Oliveira Camargo. All rights reserved.
//

#import "ViewController.h"
#include <sqlite3.h>

static NSString* systemSqliteDBFileName = @"testdb.sqlite";

@interface ViewController ()
@property(nonatomic, strong)NSString* dbFilePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* documentsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    self.dbFilePath = [documentsDir.path stringByAppendingPathComponent:systemSqliteDBFileName];

    if (![self createDB]) {
        NSLog(@"Error - failed to create/open a database.");
        return;
    }

    [self testSqlCipher];

    // Do any additional setup after loading the view.
    NSArray *array = [[NSArray alloc] initWithArray: [self columnMethodsTest]];
    for (NSString *string in array) {
        NSLog(@"%@", string);
    }
}

- (BOOL)dbExists  {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.dbFilePath];
}

- (BOOL)createDB {
    if ([self dbExists]) {
        return YES;
    }

    sqlite3* dbConnection;

    if ((dbConnection = [self openDatabase])) {
        char* errorMsg = NULL;
        const char* sqlCreateStatement = "create table if not exists \
        empInfo (id integer primary key, firstname text, lastname text, address text);";
        
        if (SQLITE_OK != sqlite3_exec(dbConnection, sqlCreateStatement, NULL, NULL, &errorMsg)) {
            NSString* errorMsgFromExec = nil;
            if (errorMsg) {
                errorMsgFromExec = [NSString stringWithCString:errorMsg encoding:NSASCIIStringEncoding];
                sqlite3_free(errorMsg);
            }
            
            NSLog(@"Error executing sqlite3 query:\"%@\" - error message:%@",
                  [NSString stringWithCString:sqlCreateStatement encoding:NSASCIIStringEncoding],
                  errorMsgFromExec);
            sqlite3_close(dbConnection);
            return NO;
        }
        sqlite3_close(dbConnection);
        return YES;
    }
    
    return NO;
}

- (NSArray*)columnMethodsTest {
    NSMutableArray *columnInfo = [[NSMutableArray alloc] init];

    sqlite3* dbConnection;
    if (!(dbConnection = [self openDatabase])) {
        return columnInfo;
    }

    const char* sqlSelectStatement = "select * from empInfo";
    sqlite3_stmt *statement;
    if (SQLITE_OK != sqlite3_prepare_v2(dbConnection, sqlSelectStatement, -1, &statement, NULL)) {
        NSLog(@"Error - failed to prepare select statement. %s", sqlite3_errmsg(dbConnection) ?: "Unknown error");

        sqlite3_close(dbConnection);
        return columnInfo;
    }

    //extract column information
    [columnInfo addObject:[NSString stringWithFormat:@"\nSqlite3 Version: %@.",[[NSString alloc] initWithUTF8String:(char*)sqlite3_libversion()]]];

    int cols = sqlite3_column_count(statement);

    [columnInfo addObject:[NSString stringWithFormat:@"\nColumn Count is %d.", cols]];
    for (int i=0; i<cols; i++) {
        const char *string = sqlite3_column_name(statement, i);
        NSString* columnName = @(string ?: "");
        NSLog(@"sqlite3_column_name: %@", columnName);

        /* For sqlite3column, if static lib test, the method can return NULL.
         ** NULL is returned if the result column is an expression or constant or
         ** anything else which is not an unambiguous reference to a database column.
         */

        string = sqlite3_column_database_name(statement, i);
        NSString* columnDBName = @(string ?: "");
        NSLog(@"sqlite3_column_database_name: %@", columnDBName);

        string = sqlite3_column_table_name(statement, i);
        NSString* columnTableName = @(string ?: "");
        NSLog(@"sqlite3_column_table_name: %@", columnTableName);

        string = sqlite3_column_origin_name(statement, i);
        NSString* columnOriginName = @(string ?: "");
        NSLog(@"sqlite3_column_origin_name: %@", columnOriginName);

        NSMutableString *entry = [NSMutableString stringWithFormat:@"\nColumn #%d:", i];
        [entry appendString:[NSString stringWithFormat:@"\nName:\t          %@", columnName]];
        [entry appendString:[NSString stringWithFormat:@"\nDatabase Name:\t %@", columnDBName]];
        [entry appendString:[NSString stringWithFormat:@"\nTable Name:\t    %@", columnTableName]];
        [entry appendString:[NSString stringWithFormat:@"\nOrigin Name:\t   %@", columnOriginName]];
        [columnInfo addObject:entry];

        NSLog(@"");
    }
    sqlite3_finalize(statement);
    sqlite3_close(dbConnection);

    return columnInfo;
}

- (BOOL)setKeyForDatabase:(sqlite3 *)db {
    int rc;
    const char* key = [@"BIGSecret" UTF8String];
    if ((rc = sqlite3_key(db, key, (int)strlen(key))) != SQLITE_OK) {
        NSLog(@"sqlite3_key error: %d %s", rc, sqlite3_errmsg(db));
    }
    return rc == SQLITE_OK;
}

- (sqlite3 *)openDatabase {
    sqlite3 *db;
    int rc;

    if ((rc = sqlite3_open([self.dbFilePath UTF8String], &db)) != SQLITE_OK) {
        NSLog(@"sqlite3_open error: %d %s", rc, sqlite3_errmsg(db));
        sqlite3_close(db);
        return NULL;
    }

    if (![self setKeyForDatabase:db]) {
        sqlite3_close(db);
        return NULL;
    }

    return db;
}

- (void)testSqlCipher {
    sqlite3 *db;
    sqlite3_stmt *stmt;
    int rc;
    bool sqlcipher_valid = NO;

    if (!(db = [self openDatabase])) {
        return;
    }

    if ((rc = sqlite3_exec(db, (const char*) "SELECT count(*) FROM sqlite_master;", NULL, NULL, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_exec error: %d %s", rc, sqlite3_errmsg(db));
    }

    if ((rc = sqlite3_prepare_v2(db, "PRAGMA cipher_version;", -1, &stmt, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_prepare_v2 error: %d %s", rc, sqlite3_errmsg(db));
        sqlite3_close(db);
        return;
    }

    if ((rc = sqlite3_step(stmt) != SQLITE_ROW)) {
        NSLog(@"sqlite3_step error: %d %s", rc, sqlite3_errmsg(db));
    }

    const unsigned char *ver = sqlite3_column_text(stmt, 0);
    if (ver != NULL) {
        sqlcipher_valid = YES;
        NSLog(@"cipher_version = %s", ver);
        // password is correct (or database initialize), and verified to be using sqlcipher
    }

    sqlite3_finalize(stmt);

    sqlite3_close(db);
}

@end
