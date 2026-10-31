# 分类电影统计
# - 输出：分类名、电影数量、平均片长
# - 只保留电影数量 >= 60 的分类
# - 按平均片长降序
# - 涉及：category、film_category、film
# - 结果粒度：一行一个分类
select c.name,count(f.film_id) as num,avg(f.length) as afl from film as f
    join film_category as fc on f.film_id=fc.film_id
    join category as c on c.category_id=fc.category_id
    group by c.name having  num>=60 order by afl desc;

# 演员作品数排行
# - 输出：演员全名、参演电影数、排名
# - 用 RANK() 排名，取排名前 10
# - 并列时允许超过 10 行，并在注释里说明原因
# - 涉及：actor、film_actor
# - 结果粒度：一行一个演员
with t1 as(
    select actor_id,count(film_id) as co_n,
           rank() over (
               order by count(film_id) desc) as rank_num from film_actor
                    group by actor_id
)
-- RANK() 遇到作品数相同的演员会给相同名次，并跳过后续名次。
-- 本题第 7 名有 6 人并列（都是 35 部），下一名直接到第 13 名，
-- 所以 WHERE rank_num <= 10 实际会返回 12 行，不是 10 行。
-- 这是并列保留，不是重复数据。
select concat(a.first_name,' ',a.last_name) as name,t1.co_n,
       t1.rank_num from actor as a
       join t1 on t1.actor_id=a.actor_id where t1.rank_num<=10
       order by t1.rank_num,name;

# 每个门店的客户消费排名
# - 输出：store_id、客户全名、总消费、店内排名
# - 每个门店内按总消费降序排名
# - 先算每个客户总消费，再用窗口函数排名
# - 涉及：customer、payment
# - 结果粒度：一行一个客户
with t2 as (select
    c.customer_id,
    c.store_id,
    concat(c.first_name, ' ', c.last_name) as name,
    sum(p.amount) as sum_a
        from customer as c
            join payment as p on c.customer_id = p.customer_id
            group by c.customer_id
)
select store_id,name,sum_a,
       row_number() over (partition by store_id order by sum_a desc) as rank_n
from t2 order by store_id,rank_n;
# 第 4 题：每日收入 + 7 日移动平均
# - 数据：payment
# - 时间：2005 年 7 月
# - 输出：日期、当天收入、最近 7 天平均收入
# - “最近 7 天”包含当天；前面不足 7 天时，按已有天数计算
# - 提示：
#   1. 先用 CTE 按 DATE(payment_date) 汇总每日收入
#   2. 再对结果使用窗口函数
#   3. 窗口范围关键词：ROWS BETWEEN 6 preceding AND current ROW
# 不要把 AVG() 和 GROUP BY 硬塞在同一层，先聚合，再开窗。
with date_income as(
    select date(payment_date) as d,sum(amount) as sa from payment
            where payment_date>='2005-07-01' and payment_date <'2005-08-01'
            group by date(payment_date)
)
select
    d,
    sa,
    avg(sa) over (order by d rows between 6 preceding and current row) as 7_day_ai from date_income;
# 第 5 题：每个分类收入最高的电影
# - 输出：分类名、电影标题、该电影收入
# - 每个分类取收入第一名；如果并列，保留全部并列
# - 连接路径：category → film_category → film → inventory → rental → payment
with ca_fi as (
select c.name as c_na,f.film_id as f_id,f.title as f_ti,sum(p.amount) as sm from category as c
join film_category as fc on c.category_id = fc.category_id
join film as f on fc.film_id = f.film_id
join inventory as i on f.film_id=i.film_id
join rental as r on i.inventory_id=r.inventory_id
join payment as p on r.rental_id = p.rental_id
group by c.category_id,c.name,f.film_id,f_ti),
rank_income as (
    select *,rank() over (partition by c_na order by sm desc) as rank_sm from ca_fi
    )
select c_na,f_ti,sm from rank_income where rank_sm=1 order by c_na

