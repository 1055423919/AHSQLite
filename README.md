//
//  README.md
//  AHSQLite
//
//  Created by Lxhong on 2026/2/4.
//

# AHSQLite

AHSQLite 是一个轻量级 Objective-C SQLite ORM 框架，提供自动建表、增删改查、批量操作等功能。使用简单，支持直接在模型对象上保存和查询数据。

## 特性

- 自动建表，无需手动写 SQL
- 支持模型属性自动映射 SQLite 字段
- NSObject 分类支持 `save`、`find`、`update`、`delete`、批量操作
- 支持事务批量插入
- 单例管理数据库连接，线程安全
- 完全 Objective-C 实现，适合 iOS 项目

## 安装

### CocoaPods

1. 在你的 `Podfile` 中添加：
pod 'AHSQLite'

2.安装：
pod install

### 手动导入

1.下载 AHSQLite 仓库

2.将 AHSQLite 文件夹拖入你的 Xcode 项目

## 在需要使用的地方导入：

#import <AHSQLite/AHSQLite.h>

# 使用示例

## 创建模型

@interface TTListInfoModel : NSObject

@property (nonatomic, copy) NSString *identifer;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, assign) NSInteger age;

@end

## 保存对象

TTListInfoModel *model = [[TTListInfoModel alloc] init];

model.identifer = @"001";

model.content = @"测试内容";

model.age = 18;

[model sql_save:@"TimeTunnelList"];

## 查询所有数据

NSArray *all = [TTListInfoModel sql_findAll:@"TimeTunnelList"];

## 按条件查询

NSArray *some = [TTListInfoModel sql_find:@"TimeTunnelList" key:@"identifer" value:@"001"];

## 更新数据

model.content = @"修改后的内容";
[TTListInfoModel sql_update:@"TimeTunnelList" model:model key:@"identifer" value:@"001"];

## 删除数据

[TTListInfoModel sql_delete:@"TimeTunnelList" key:@"identifer" value:@"001"];

## 批量保存

NSArray *models = @[model1, model2, model3];
[TTListInfoModel sql_saveBatch:@"TimeTunnelList" models:models];

## 清空并删除表
[TTListInfoModel sql_cleanAll:@"TimeTunnelList"];
