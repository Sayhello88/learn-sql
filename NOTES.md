# SQL 学习手册

> 配套仓库：`learn-sql` ｜ 数据源：sakila（MySQL 8.0）
> 更新至 W7：窗口函数、CTE、索引与 EXPLAIN。

---

## 0. 怎么用这份手册

- 当速查表用，不要背。写不出来时先看模板，再自己敲一遍。
- 每节最后的「坑」是重点，都是真实踩过的。
- 例题都基于 sakila，可以直接跑。

---

## 1. 一条 SQL 的执行顺序

写的时候从 `SELECT` 开始，但**执行顺序不是**：

```
FROM / JOIN  →  ON  →  WHERE  →  GROUP BY  →  HAVING
             →  SELECT  →  窗口函数  →  DISTINCT  →  ORDER BY  →  LIMIT
```

这解释了三件事：

1. `WHERE` 里不能用 `SELECT` 起的别名（那时还没算出来）
2. `WHERE` 里不能用聚合函数（`GROUP BY` 还没发生）
3. `WHERE` 里不能用窗口函数（窗口在 `SELECT` 之后才算）

---

## 2. 基础查询

```sql
SELECT 列1, 列2
FROM 表
WHERE 条件
ORDER BY 列1 DESC, 列2 ASC
LIMIT 10;
```

**常用运算符**

| 运算符 | 含义 | 例子 |
| --- | --- | --- |
| `=` `<>` `>` `<` `>=` `<=` | 比较 | `rating = 'R'` |
| `AND` `OR` `NOT` | 逻辑 | `rating = 'R' AND length > 120` |
| `BETWEEN a AND b` | 闭区间 | `length BETWEEN 90 AND 120` |
| `IN (a, b)` | 在集合中 | `rating IN ('G','PG')` |
| `LIKE '%x%'` | 模糊匹配 | `title LIKE '%LOVE%'` |
| `IS NULL` / `IS NOT NULL` | 判空 | `length IS NOT NULL` |
| `DISTINCT` | 去重 | `SELECT DISTINCT rating` |

**NULL 的规则（必记）**

- `NULL = NULL` 结果是 `UNKNOWN`，不是 `TRUE`
- 判断空只能用 `IS NULL` / `IS NOT NULL`
- 任何值和 NULL 做算术，结果是 NULL
- `COUNT(列)` 会跳过 NULL，`COUNT(*)` 不会

**坑**

- `title = '%LOVE%'` 匹配不到任何东西，通配符只有 `LIKE` 认。
- 日期是 `DATETIME` 时，`= '2005-06-14'` 只匹配 `00:00:00`，要用范围。
- `LIMIT 10 OFFSET 20` 等价于 `LIMIT 20, 10`。

---

## 3. 聚合与分组

```sql
SELECT rating,
       COUNT(*)     AS cnt,
       AVG(length)  AS avg_len,
       SUM(amount)  AS total
FROM film
GROUP BY rating
HAVING COUNT(*) > 100
ORDER BY cnt DESC;
```

**五个聚合函数**：`COUNT` / `SUM` / `AVG` / `MAX` / `MIN`

**`WHERE` vs `HAVING`**

| | 作用对象 | 执行时机 |
| --- | --- | --- |
| `WHERE` | 一行一行过滤 | 分组之前 |
| `HAVING` | 一组一组过滤 | 分组之后 |

**规则**：`SELECT` 里的非聚合列，必须出现在 `GROUP BY` 里（否则 `ONLY_FULL_GROUP_BY` 报 1055）。

**坑**

- 分组按 `id` 而不是按姓名，避免重名合并。
- `COUNT(列)` 不数 NULL；想知道行数用 `COUNT(*)`。
- `HAVING` 里可以直接用 `SELECT` 的别名（MySQL 支持）。

---

## 4. 常用函数

**日期**

| 函数 | 作用 | 例子 |
| --- | --- | --- |
| `NOW()` | 当前时间 | `2026-10-25 21:00:00` |
| `DATE(x)` | 取日期部分 | `DATE('2005-07-15 22:44:12')` → `2005-07-15` |
| `YEAR(x)` / `MONTH(x)` | 取年 / 月 | `YEAR(rental_date)` |
| `DATE_FORMAT(x, fmt)` | 格式化 | `DATE_FORMAT(x,'%Y-%m')` → `2005-07` |
| `DATEDIFF(a, b)` | 相差天数 | `DATEDIFF(return_date, rental_date)` |

**字符串**

| 函数 | 作用 |
| --- | --- |
| `CONCAT(a, b, c)` | 拼接，任一参数为 NULL 则结果为 NULL |
| `CONCAT_WS(sep, a, b)` | 带分隔符拼接 |
| `UPPER` / `LOWER` | 大小写 |
| `TRIM` | 去首尾空格 |
| `LENGTH` / `CHAR_LENGTH` | 字节数 / 字符数（中文用后者） |
| `SUBSTRING(s, pos, len)` | 截取 |

**条件分支**

```sql
CASE
    WHEN 条件1 THEN 值1
    WHEN 条件2 THEN 值2
    ELSE 默认值
END AS 别名
```

常用于分档：`CASE WHEN total >= 100 THEN '高价值' ELSE '普通' END`。

**数值**

`ROUND(x, n)` 四舍五入 ｜ `CEIL` 向上取整 ｜ `FLOOR` 向下取整 ｜ `ABS` 绝对值

**坑**

- 日期范围用**左闭右开**：`>= '2005-06-01' AND < '2005-07-01'`，别用 `BETWEEN` 卡月末。
- `DATE_FORMAT` 必须传两个参数，只传日期会报错。

---

## 5. 多表 JOIN

```
A 表: 1 2 3        B 表: 2 3 4

INNER JOIN  →  2 3          两边都有的
LEFT  JOIN  →  1 2 3        左表全留，右表没有补 NULL
RIGHT JOIN  →  2 3 4        右表全留
```

MySQL **没有** `FULL OUTER JOIN`，需要的话用 `LEFT JOIN ... UNION ... RIGHT JOIN` 模拟。

**模板（三表）**

```sql
SELECT f.title, a.first_name, a.last_name
FROM film f
JOIN film_actor fa ON f.film_id  = fa.film_id
JOIN actor a       ON fa.actor_id = a.actor_id
WHERE a.last_name = 'WAHLBERG';
```

**反连接：找「没有」**

```sql
SELECT c.*
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
WHERE r.rental_id IS NULL;
```

**自连接：同一张表连自己**

```sql
SELECT a.actor_id, b.actor_id
FROM actor a
JOIN actor b ON a.last_name = b.last_name
WHERE a.actor_id < b.actor_id;   -- 排除自己 + 去掉镜像
```

**坑**

1. 忘写 `ON` → 笛卡尔积（1000 × 200 = 20 万行）
2. `LEFT JOIN` 后在 `WHERE` 过滤右表的**具体值** → 退化成 INNER
3. 一对多会翻倍，统计电影数要用 `COUNT(DISTINCT f.film_id)`
4. 多表同名列要用别名区分，`SELECT *` 会出重复列
5. 每张表**必须先出现、后引用**，`ON` 里不能引用还没 join 的表

---

## 6. 子查询

**① 标量子查询（返回一行一列）**

```sql
SELECT title, length
FROM film
WHERE length > (SELECT AVG(length) FROM film);
```

**② IN（返回一列）**

```sql
SELECT * FROM customer
WHERE customer_id IN (SELECT customer_id FROM rental);
```

**③ EXISTS / NOT EXISTS（只判断存在性）**

```sql
SELECT c.* FROM customer c
WHERE NOT EXISTS (
    SELECT 1 FROM rental r WHERE r.customer_id = c.customer_id
);
```

**④ FROM 子查询（派生表）**

```sql
SELECT * FROM (
    SELECT customer_id, COUNT(*) AS cnt
    FROM rental GROUP BY customer_id
) AS t
WHERE t.cnt > 40;
```

**规则**

- 标量子查询只能返回**一行一列**，否则报错
- 派生表**必须起别名**
- `EXISTS` 里的 `SELECT` 写什么都行，只看有没有行

**坑**

- `NOT IN` 的子查询里只要有 NULL，整个条件恒为假 → 用 `NOT EXISTS`
- 「一对多」判断存在性时，`NOT EXISTS` 比 `LEFT JOIN` 安全

---

## 7. 集合运算 UNION

```sql
SELECT first_name FROM actor
UNION
SELECT first_name FROM customer;
```

| | 去重 | 速度 |
| --- | --- | --- |
| `UNION` | 会去重 | 慢（要排序） |
| `UNION ALL` | 不去重 | 快 |

**规则**

- 两边**列数相同**、顺序对应、类型兼容
- 列名取**第一条** `SELECT` 的
- `ORDER BY` 只能写在最后一条后面，作用于整体

---

## 8. 窗口函数（W5–W6）

```sql
函数() OVER (
    PARTITION BY 分组列
    ORDER BY 排序列
)
```

与 `GROUP BY` 的区别：**`GROUP BY` 压行，窗口函数保留每一行。**

**排名**

```sql
ROW_NUMBER() OVER (PARTITION BY rating ORDER BY length DESC)
RANK()       OVER (...)
DENSE_RANK() OVER (...)
```

| 长度 | ROW_NUMBER | RANK | DENSE_RANK |
| --- | --- | --- | --- |
| 200 | 1 | 1 | 1 |
| 200 | 2 | 1 | 1 |
| 190 | 3 | 3 | 2 |

**取每组前 N（必须套子查询）**

```sql
SELECT * FROM (
    SELECT rating, title, length,
           ROW_NUMBER() OVER (PARTITION BY rating ORDER BY length DESC) AS rn
    FROM film
) t
WHERE t.rn <= 3;
```

**聚合窗口**

```sql
SUM(amount) OVER (PARTITION BY customer_id)                        -- 整组总和，每行一样
SUM(amount) OVER (PARTITION BY customer_id ORDER BY payment_date)  -- 累计
AVG(length) OVER (PARTITION BY rating)                             -- 组内平均
```

**偏移**

```sql
LAG(amount)              -- 上一行
LEAD(amount)             -- 下一行
LAG(amount, 2)           -- 上两行
LAG(amount, 1, 0)        -- 没有上一行时用 0 代替 NULL
```

**坑**

- 窗口函数不能写在 `WHERE` 里，要套子查询。
- `LAG` / `LEAD` 必须配 `ORDER BY`，否则「上一行」没有定义。
- 同一时间有多条记录时，加第二排序键（如 `payment_id`）保证顺序稳定。

---

## 8.5 CTE（WITH）

把查询拆成有名字的几步，从上往下读。

```sql
WITH 名字 AS (查询),
     名字2 AS (查询，可引用名字)
SELECT ... FROM 名字2;
```

等价于派生表，但嵌套两层以上时可读性高得多。

**经典：每组取最新一条**

```sql
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date DESC) AS rn
    FROM payment
)
SELECT * FROM ranked WHERE rn = 1;
```

**先聚合，再窗口（环比）**

```sql
WITH daily AS (
    SELECT DATE(payment_date) AS d, SUM(amount) AS income
    FROM payment
    WHERE payment_date >= '2005-07-01' AND payment_date < '2005-08-01'
    GROUP BY d
),
prev AS (
    SELECT d, income, LAG(income) OVER (ORDER BY d) AS pre
    FROM daily
)
SELECT d, income, income - pre AS growth FROM prev ORDER BY d;
```

**要点**

- 聚合和窗口不能在同一层混着做：先 `GROUP BY` 压成一行一天，再对它 `LAG`。
- 后面可以引用前面的 CTE，像搭积木。
- `LAG` 必须配 `ORDER BY`，否则「上一行」没有定义。

---

## 9. 索引与 EXPLAIN（W7）

> 一句话：**索引用来看目录，EXPLAIN 用来看 MySQL 准备怎么查。**

### 9.1 先看表上已经有什么索引

不要一上来就 `CREATE INDEX`，sakila 自带了一些索引：

```sql
SHOW INDEX FROM film;
SHOW INDEX FROM actor;
SHOW INDEX FROM payment;
```

重点看这几列：

| 列 | 含义 |
| --- | --- |
| `Key_name` | 索引名 |
| `Column_name` | 索引包含哪一列 |
| `Seq_in_index` | 在联合索引里排第几 |
| `Non_unique` | `0` 表示唯一索引 |

**sakila 里已经有的索引**：

- `film.idx_title (title)`
- `actor.idx_actor_last_name (last_name)`
- `payment.idx_fk_customer_id (customer_id)`
- `payment.idx_fk_staff_id (staff_id)`

所以 `CREATE INDEX film_title ON film(title)` 和 `CREATE INDEX idx_actor_last ON actor(last_name)` 都是**重复索引**，不会让查询更快，只会多占空间、拖慢写入。学习时可以先 `DROP INDEX` 掉自己建的重复索引。

### 9.2 InnoDB 和 B+ 树，先用直觉理解

**InnoDB** 是 MySQL 8 默认的存储引擎。你可以先记三件事：

- 数据按行存在磁盘上
- 支持事务和崩溃恢复
- 使用 B+ 树组织索引

**B+ 树索引**像一本按关键字排好序的目录：

```text
             [M]
           /     \
       [D, H]     [R, W]
       /  |  \     /  |  \
      A  E  K    N  T  Z
```

它的关键能力是：**知道关键字顺序，所以能快速定位和连续扫描一段范围**。因此：

- `title = 'A'`：能定位
- `title LIKE 'A%'`：能定位到 A 开头的一段
- `title LIKE '%A'`：不知道开头是什么，只能整表扫
- `YEAR(payment_date) = 2005`：要先对每一行算函数，索引顺序用不上

### 9.3 聚簇索引、二级索引、回表

InnoDB 的主键索引叫**聚簇索引**：叶子节点直接放整行数据。

```text
主键索引 film_id -> [film_id, title, length, rating, ...整行]
```

普通索引叫**二级索引**，叶子节点放的是“索引列 + 主键值”：

```text
idx_title (title) -> [title, film_id]
```

如果查询要的列不在二级索引里，就要拿 `film_id` 回主键索引再查一次，这叫**回表**：

```text
idx_title 找到 film_id  ->  主键索引找到整行
```

如果查询只需要索引里已有的列，就不用回表，叫**覆盖索引**，`EXPLAIN` 的 `Extra` 会出现：

```text
Using index
```

例子：

```sql
-- title 在 idx_title 里，通常可以覆盖
EXPLAIN SELECT title FROM film WHERE title LIKE 'A%';

-- 还要 description、rating 等列，通常要回表
EXPLAIN SELECT * FROM film WHERE title LIKE 'A%';
```

### 9.4 看懂 EXPLAIN 的关键列

```sql
EXPLAIN SELECT title FROM film WHERE title LIKE 'A%';
```

| 列 | 看什么 |
| --- | --- |
| `type` | 访问方式，最重要 |
| `possible_keys` | 理论上能用的索引 |
| `key` | 实际选中的索引 |
| `key_len` | 用了索引的多少字节 |
| `rows` | **估算**要扫多少行，不是精确值 |
| `filtered` | 扫描后预计还剩多少百分比 |
| `Extra` | 覆盖索引、排序、临时表等额外信息 |

`type` 从好到差大致是：

```text
const  >  eq_ref  >  ref  >  range  >  index  >  ALL
```

- `const`：主键/唯一索引等值查到一行
- `ref`：普通索引等值匹配，可能多行
- `range`：索引范围扫描，例如 `BETWEEN`、`>`、`LIKE 'A%'`
- `index`：扫描整个索引，不是扫描整表，但仍可能很慢
- `ALL`：全表扫描

`Extra` 常见值：

| 值 | 含义 |
| --- | --- |
| `Using index` | 覆盖索引，不用回表 |
| `Using where` | 服务层还要过滤 |
| `Using filesort` | 需要额外排序 |
| `Using temporary` | 用了临时表，常见于复杂 `GROUP BY` |

### 9.5 索引什么时候用得上

**① 前缀匹配可以，前导通配符不行**

```sql
EXPLAIN SELECT title FROM film WHERE title LIKE 'A%';  -- range
EXPLAIN SELECT title FROM film WHERE title LIKE '%A';  -- ALL
```

sakila 里 `A%` 有 46 部电影，适合演示范围扫描。

**② 列上套函数，普通索引容易失效**

```sql
-- 不推荐：对 payment_date 套了 YEAR()
EXPLAIN SELECT * FROM payment WHERE YEAR(payment_date) = 2005;

-- 推荐：把范围写在列上
EXPLAIN SELECT * FROM payment
WHERE payment_date >= '2005-01-01'
  AND payment_date <  '2006-01-01';
```

第一条通常是 `ALL`，第二条能用 `payment_date` 索引做 `range`。

**③ 联合索引遵守最左前缀**

```sql
CREATE INDEX idx_customer_date ON payment(customer_id, payment_date);
```

它像电话簿先按姓、再按名排序：

| 查询 | 能否利用 `idx_customer_date` |
| --- | --- |
| `WHERE customer_id = 1` | 能 |
| `WHERE customer_id = 1 AND payment_date > '2005-06-01'` | 能 |
| `WHERE payment_date > '2005-06-01'` | 不能单独利用这个联合索引 |

但注意：如果表上同时有单独的 `idx_pay_date (payment_date)`，第三条会改用 `idx_pay_date`，`type` 仍然是 `range`。要验证“最左前缀”，要先排除其他索引的干扰。

**④ ORDER BY 最好跟索引顺序一致**

```sql
-- 过滤用 title 索引，但排序按 release_year，通常出现 Using filesort
EXPLAIN SELECT title FROM film
WHERE title LIKE 'A%'
ORDER BY release_year;

-- 过滤和排序都按 title，索引本身有序，通常没有 filesort
EXPLAIN SELECT title FROM film
WHERE title LIKE 'A%'
ORDER BY title;
```

`Using filesort` 不一定真的写磁盘，也可能在内存里排序；它只表示 MySQL 需要额外做一次排序。

### 9.6 索引不是越多越好

- 每个索引都要占空间
- `INSERT` / `UPDATE` / `DELETE` 都要维护索引，写入会变慢
- 区分度低的列（例如只有几个值）单独建索引，效果通常不好
- 小表全表扫描有时比走索引更快，优化器可能主动选择 `ALL`
- 不要重复建索引，先用 `SHOW INDEX` 看现有索引

**W7 的坑**

- `film.title` 已经有 `idx_title`，`actor.last_name` 已经有 `idx_actor_last_name`，不要重复建。
- 第 2 题建了 `idx_pay_date` 后，第 3 题第三条查询会被它接走，不一定能看到 `ALL`。
- `rows` 是优化器估算值，不是 `COUNT(*)`；sakila 数据量小，不要用耗时判断索引好坏。
- `LIKE 'SON%'` 虽然是 `range`，但 sakila 里没有姓以 `SON` 开头的演员，可能返回 0 行；演示前缀索引用 `A%` 更直观。
- 查询 `SELECT *` 容易触发回表；只取需要的列，才更容易用上覆盖索引。

---

## 10. 常见错误清单（自查用）

| # | 错误 | 正确做法 |
| --- | --- | --- |
| 1 | `WHERE x = NULL` | `WHERE x IS NULL` |
| 2 | `title = '%LOVE%'` | `title LIKE '%LOVE%'` |
| 3 | `WHERE COUNT(*) > 5` | `HAVING COUNT(*) > 5` |
| 4 | `WHERE RANK() OVER (...) <= 3` | 套子查询再筛 |
| 5 | `LEFT JOIN` 后在 `WHERE` 过滤右表值 | 条件写进 `ON` |
| 6 | 一对多 `COUNT(*)` 翻倍 | `COUNT(DISTINCT id)` |
| 7 | `NOT IN` 遇到 NULL 结果为空 | `NOT EXISTS` |
| 8 | `payment_date = '2005-06'` | `>= '2005-06-01' AND < '2005-07-01'` |
| 9 | 派生表没别名 | `FROM (...) AS t` |
| 10 | 忘写 `ON` | 检查每个 `JOIN` |
| 11 | 重复建同列索引 | 先 `SHOW INDEX`，复用已有索引 |
| 12 | `WHERE YEAR(date_col) = 2005` | 改成日期范围，让索引可用 |
| 13 | `LIKE '%关键字'` | 尽量用前缀匹配，或考虑全文索引 |
| 14 | 把 `EXPLAIN.rows` 当精确行数 | 它是估算值，以实际 `COUNT(*)` 为准 |

---

## 11. sakila 速查

| 表 | 关键字段 |
| --- | --- |
| `film` | film_id, title, release_year, length, rating, rental_rate |
| `actor` | actor_id, first_name, last_name |
| `film_actor` | actor_id, film_id |
| `category` / `film_category` | category_id, name / film_id, category_id |
| `customer` | customer_id, store_id, first_name, last_name, active |
| `rental` | rental_id, rental_date, inventory_id, customer_id, return_date |
| `payment` | payment_id, customer_id, rental_id, amount, payment_date |
| `inventory` | inventory_id, film_id, store_id |

**几个可用来对答案的数字**

```
film      1000      Actor    200       customer  599
rental    16044     payment  16044     inventory 4581
film_actor 5462     category 16
```

---

*持续更新：每学完一个新知识点，回来看一眼是否该补进来。*
