# learn-sql

数据科学与大数据技术专业（大二）的 SQL 学习记录。

目标方向：**数据开发 / 数仓工程师**（保底：数据分析）。
这里按周提交练习，只记录真正自己写过、跑通过的代码。

## 学习路线

| 阶段 | 时间 | 内容 | 状态 |
| --- | --- | --- | --- |
| W1 | 2026.10 | SQL 基础：SELECT / WHERE / ORDER BY / LIMIT | ✅ |
| W2 | 2026.10 | 聚合：GROUP BY / HAVING / 日期与字符串函数 | ✅ |
| W3 | 2026.10 | 多表 JOIN：INNER / LEFT / 自连接 / 反连接 | ✅ |
| W4 | 2026.10 | 子查询 / EXISTS / UNION | ✅ |
| W5–W6 | 2026.11 | 窗口函数 / CTE / CASE WHEN | ✅ |
| W7 | 2026.11 | 索引与执行计划（EXPLAIN） | ✅ 已完成 |
| W8 | 2026.10 | SQL 综合实战：多表 + 窗口 + CTE | ✅ |
| W9 | 2026.11 | 阶段小测 | 🚧 下一阶段 |

## 进度

| 文件 | 内容 | 状态 |
| --- | --- | --- |
| `Day01.sql` | 基础查询 10 题 + 聚合 9 题 | ✅ 已完成 |
| `Day02.sql` | 多表 JOIN：三表连接、连接聚合、反连接、自连接 | ✅ 已完成 |
| `Day03.sql` | 子查询、EXISTS / NOT EXISTS、UNION | ✅ 已完成 |
| `Day04.sql` | 窗口函数：排名、累计、LAG、RANK 对比 | ✅ 已完成 |
| `Day05.sql` | CTE、CASE WHEN、分档统计 | ✅ 已完成 |
| `Day06.sql` | 索引与 EXPLAIN：前缀索引、联合索引、filesort | ✅ 已完成 |
| `Day07.sql` | W8 综合实战：分类统计、排名、移动平均、分类最高收入 | ✅ 已完成 |

## 仓库结构

```
learn-sql/
├── Day01.sql   # W1–W2：基础查询、聚合与分组
├── Day02.sql   # W3：多表 JOIN、反连接、自连接
├── Day03.sql   # W4：子查询、EXISTS、UNION
├── Day04.sql   # W5：窗口函数
├── Day05.sql   # W6：CTE、CASE WHEN
├── Day06.sql   # W7：索引与 EXPLAIN
├── Day07.sql   # W8：SQL 综合实战
├── NOTES.md    # SQL 学习手册
└── README.md
```

## 学习方式

- 每周投入 10–12 小时（不含课内）
- 先自己写，卡住 20 分钟再查资料
- 每道题都跑通再提交，不交「看起来对」的代码
- 每完成一周，更新上面的进度表

## 使用数据

[sakila](https://dev.mysql.com/doc/sakila/en/) —— MySQL 官方示例数据库（DVD 租赁业务，16 张表，约 1.6 万条租赁记录）。

## 后续计划

- 2027 年暑假：拿到第一份数据相关实习
- 2027 年秋：Hive / Spark / 数仓分层建模
- 2028 年秋招：数据开发 / 数仓方向
