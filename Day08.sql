# 1. 基础筛选（10 分）
# film 表：找出 rating = 'R'、片长在 120–150 分钟之间、租金大于 2.99 的电影。
# 输出：title、length、rental_rate。按片长降序、标题升序，取前 10 条。
select title,length,rental_rate from film
where rating='R' and length between 120 and 150 and rental_rate>2.99
order by length desc,title limit 10;
# 2. 分类收入统计（15 分）
# 统计每个分类的电影数量、平均片长、总租赁收入。
# 只保留电影数量 >= 60 的分类，按总收入降序取前 5。
# 输出：分类名、电影数量、平均片长、总收入。
# 连接路径自己判断，注意 payment → rental → inventory → film。
with t1 as (
    select c.category_id as cid,
           c.name as name,
           count(*) as count_film,
           avg(f.length) as avg_len
    from category as c
    join film_category as fa on c.category_id = fa.category_id
    join film as f on fa.film_id = f.film_id
    group by c.category_id, c.name having count(*)>=60
),
t2 as (
    select c.category_id as cid2,
    sum(p.amount) as sum_amount
    from category as c
    join film_category as fa on c.category_id = fa.category_id
    join film as f on f.film_id=fa.film_id
    join inventory as i on f.film_id = i.film_id
    join rental as r on i.inventory_id = r.inventory_id
    join payment as p on r.rental_id = p.rental_id
    group by c.category_id
)
select t1.name,t1.count_film,t1.avg_len,t2.sum_amount from t1 join t2 on t1.cid=t2.cid2 order by t2.sum_amount desc limit 5;
# 3. 从未被租出的电影（15 分）
# 找出从未被租出去过的电影。
# 输出：film_id、title、length，按片长降序取前 10。
# 要求用 NOT EXISTS 写。
select film_id,title,length from film where not exists(
    select 1 from rental as r
        join inventory as i on i.inventory_id =r.inventory_id
        where i.film_id=film.film_id
)order by length desc limit 10;
# 4. 门店客户消费排名（20 分）
# 每个门店内，按客户总消费降序排名，取每个门店前 5 名。
# 输出：store_id、客户全名、总消费、店内排名。
# 要求：
# - 先算每个客户总消费，再排名
# - 用 RANK()，同消费额允许并列
# - 并列导致超过 5 行是正常的
with t1 as (
select c.store_id as c_id,concat(c.first_name,' ',c.last_name) as c_name,sum(p.amount) as sum_amount
from customer as c
join payment as p on c.customer_id=p.customer_id
group by c.store_id,c.customer_id),
t2 as(
select *,rank() over (partition by c_id order by sum_amount desc ) as rank_sum from t1)
select * from t2 where rank_sum<=5 order by c_id,rank_sum,c_name;
# 5. 月度收入与环比（20 分）
# 统计 2005 年每个月的总收入，并计算：
# - 当月收入
# - 上月收入
# - 相对上月的增长额
# - 相对上月的增长率
# 输出：月份、收入、上月收入、增长额、增长率，按月份升序。
# 提示：先按月聚合，再用 LAG() 取上月；第一个月没有上月，结果可以为 NULL。
with t1 as (
select month(payment_date) as month,sum(amount) as sum_amount from payment
where payment_date>='2005-01-01' and payment_date<'2006-01-01'
group by month(payment_date)),
t2 as(
    select *,
    lag(sum_amount) over (order by month) as lag_month,
    sum_amount-(lag(sum_amount) over (order by month)) as grow_num,
    (sum_amount-(lag(sum_amount) over (order by month)))/(lag(sum_amount) over (order by month))  as grow_percent
    from t1
    )
select * from t2 order by month;
# 6. EXPLAIN 分析（20 分）
# 对 payment 表分别执行：
EXPLAIN SELECT * FROM payment WHERE YEAR(payment_date) = 2005;
#
EXPLAIN SELECT *
FROM payment
WHERE payment_date >= '2005-07-01'
  AND payment_date <  '2005-07-08';
# 用文字回答：
# - 两条的 type、key、rows 有什么区别
#     第一条：type都是all,key是null,rows是15375 第二条：type是range,key是idx_pay_date,rows是992
# - 为什么 YEAR(payment_date) 不好
# 他要先把所有的payment_date取出来转换成year再去判断是不是2005
# - 第二条如果要更稳定地走索引，需要什么索引
# 需要 payment_date 列上的索引，例如 idx_pay_date (payment_date)；
# 查询条件保持为 payment_date >= ... AND payment_date < ...，不要在列上套 DATE() 或 YEAR()。
