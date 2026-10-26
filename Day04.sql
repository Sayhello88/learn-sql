# film：每个分级内按片长降序排名，取出每个分级的前 3 名
select rating,title,length,rl from(
        select rating,title,length,row_number()
        over (partition by rating order by length desc) as rl from film) t
        where t.rl<=3 order by rating,rl;
# film：每部电影显示片长、本分级的平均片长、以及两者差值，按差值降序
select title,length,avg(length) over (partition by rating) as avg_len,
       length-avg(length) over (partition by rating) as diff
        from film order by diff desc ;
# payment：每个客户按支付时间累计支付金额
select customer_id,payment_date,amount,sum(amount) over
    (partition by customer_id order by payment_date) as sum_pay
from payment;
# payment：每个客户相邻两笔支付的金额差（用 LAG）
select customer_id,amount,
       amount-lag(amount) over
           (partition by customer_id order by payment_date) as diff from payment;
# film：按片长降序，同时用 RANK() 和 DENSE_RANK() 算排名，找出两者结果不一样的电影
select title,rl,drl from (select title,rank() over (order by length) as rl,
       dense_rank() over (order by length)as drl from film) as t where t.rl!=t.drl;