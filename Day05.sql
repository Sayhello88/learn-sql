# 用 CTE 重写上周第 1 题：film：每个分级内按片长降序排名，取出每个分级的前 3 名
with film_rank as
    ( select rating,title,row_number() over (partition by rating order by length desc) as rk from film )
select * from film_rank where rk<=3;

# 每个客户最后一次支付的金额和时间（用上面的「每组最新一条」模式）
with cus_last_pay as (
    select *,row_number() over (partition by customer_id order by payment_date desc ) as t
    from payment
)
select * from cus_last_pay where t=1;
# 按天统计 2005 年 7 月的每日收入，并算出与前一天相比的增长额（DATE + SUM + LAG）
with e_income as(
    select date(payment_date) as e_date,sum(amount) as income from payment
    where date(payment_date)>='2005-07-01' and
          date(payment_date)<'2005-08-01' group by e_date
),
pre_eh as(
    select e_date,income,lag(income) over(order by e_date) as pre from e_income
    )
select e_date,income,income-pre from pre_eh ;
# 用两个 CTE 分步算：先算每个客户的总消费，再筛出总额大于 100 的，按总额降序取前 10
with total_pay as(
    select customer_id ,sum(amount) as total_am from payment group by customer_id
),
total_100 as(
    select * from total_pay where total_am>100)
select * from total_100 order by total_am desc limit 10;
# 用 CTE 链式：先算每个客户总消费，再用 CASE WHEN 分档（>=100 为「高价值」，否则「普通」），最后统计各档有多少人
with total_cus as (
    select customer_id,sum(amount) as sa from payment group by customer_id
),
tags as (
select customer_id,sa,
        case
            when sa>=100 then 'High value'
            else 'Ordinary'
        end as tag from total_cus)
select tag,count(*) from tags group by tag;

