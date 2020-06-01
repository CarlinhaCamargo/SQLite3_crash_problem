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
    // Do any additional setup after loading the view.
    NSArray *array = [[NSArray alloc] initWithArray: [self columnMethodsTest]];
    NSLog(@"aqui");
}

-(BOOL)dbExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.dbFilePath];
}

-(BOOL)createDB
{
    if ([self dbExists])
    {
        return YES;
    }
    
    sqlite3* dbConnection;
    if (SQLITE_OK == sqlite3_open([self.dbFilePath UTF8String], &dbConnection))
    {
    
        char* errorMsg = NULL;
        const char* sqlCreateStatement = "create table if not exists \
        empInfo (id integer primary key, firstname text, lastname text, address text);";
        
        if (SQLITE_OK != sqlite3_exec(dbConnection, sqlCreateStatement, NULL, NULL, &errorMsg))
        {
            NSString* errorMsgFromExec = nil;
            if (NULL != errorMsg)
            {
                errorMsgFromExec = [NSString stringWithCString:errorMsg encoding:NSASCIIStringEncoding];
                sqlite3_free(errorMsg);
            }
            
            NSLog(@"Error executing sqlite3 query:\"%@\" - error message:%@",
                  [NSString stringWithCString:sqlCreateStatement encoding:NSASCIIStringEncoding],
                  errorMsgFromExec);
            return NO;
        }
        sqlite3_close(dbConnection);
        return YES;
    }
    
    return NO;
}

-(NSArray*)columnMethodsTest
{
    NSMutableArray *columnInfo = [[NSMutableArray alloc] init];

    if (![self createDB])
    {
        NSLog(@"Error - failed to create/open a database.");
        return columnInfo;
    }

    sqlite3* dbConnection;
    if (SQLITE_OK == sqlite3_open([self.dbFilePath UTF8String], &dbConnection))
    {
        const char* sqlSelectStatement = "select * from empInfo";
        sqlite3_stmt *statement;
        if (SQLITE_OK == sqlite3_prepare_v2(dbConnection, sqlSelectStatement, -1, &statement, NULL))
        {
            //extract column information
            [columnInfo addObject:[NSString stringWithFormat:@"\nSqlite3 Version: %@.",[[NSString alloc] initWithUTF8String:(char*)sqlite3_libversion()]]];

            int cols = sqlite3_column_count(statement);

            [columnInfo addObject:[NSString stringWithFormat:@"\nColumn Count is %d.", cols]];
            for (int i=0; i<cols; i++)
            {
                NSString* columnName = ((sqlite3_column_name(statement, i)) != NULL) ? [[NSString alloc] initWithUTF8String: (char*)sqlite3_column_name(statement, i)] : @"";
//                NSLog(@"%@", columnName);
                /* For sqlite3colum, if static lib test, the method can return NULL.
                ** NULL is returned if the result column is an expression or constant or
                ** anything else which is not an unambiguous reference to a database column.
                */
                
                NSLog(@"%s", sqlite3_column_database_name(statement, i));
                NSString* columnDBName = ((sqlite3_column_database_name(statement, i)) != NULL) ? [[NSString alloc] initWithUTF8String: (char*)sqlite3_column_database_name(statement, i)] : @"";
                NSLog(@"%@",columnDBName);
                NSString* columnTableName = ((sqlite3_column_table_name(statement, i)) != NULL) ? [[NSString alloc] initWithUTF8String: (char*)sqlite3_column_table_name(statement, i)] : @"";
                NSLog(@"%@",columnTableName);
                NSString* columnOriginName = ((sqlite3_column_origin_name(statement, i)) != NULL) ? [[NSString alloc] initWithUTF8String: (char*)sqlite3_column_origin_name(statement, i)] : @"";
                NSLog(@"%@",columnOriginName);
                
                NSMutableString *entry = [NSMutableString stringWithFormat:@"\nColumn #%d:", i];
                [entry appendString:[NSString stringWithFormat:@"\nName:\t          %@", columnName]];
                [entry appendString:[NSString stringWithFormat:@"\nDatabase Name:\t %@", columnDBName]];
                [entry appendString:[NSString stringWithFormat:@"\nTable Name:\t    %@", columnTableName]];
                [entry appendString:[NSString stringWithFormat:@"\nOrigin Name:\t   %@", columnOriginName]];
                [columnInfo addObject:entry];
            }
            sqlite3_finalize(statement);
        }

        sqlite3_close(dbConnection);
        return columnInfo;
    }

    // Fail to open the database.
    NSLog(@"Error - failed to open the database.");
    return columnInfo;
}



@end
