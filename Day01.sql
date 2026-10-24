-- 1. film：title、release_year、length，按片长降序，取前 10
-- 2. film：rating = 'R' 且片长超过 120 分钟
-- 3. film：所有出现过的分级（不能重复），并说出共几种
-- 4. customer：姓为 SMITH 的客户
-- 5. film：租金 > 4.99，按租金降序，租金相同按标题升序
-- 6. film：1990 年以后上映、片长 < 60 分钟的 G 级电影
-- 7. film：标题里带 LOVE（大小写都要能匹配）
-- 8. film：片长在 90–120 分钟之间（含两端），按片长降序取前 20
-- 9. actor：姓以 A 开头的演员，按名字升序
-- 10. film：分级是 G 或 PG、且片长不为空的电影，按上映年份降序取前 15
select title,release_year,length from film order by length desc limit 10;
select * from film where rating='R' and length >120;
select rating,count(rating) from film group by rating;
select * from customer where last_name='SMITH';
select * from film where rental_rate>4.99 order by rental_rate desc,title asc;
select * from film where release_year >1990 and length<60 and rating='G';
select * from film where title like '%LOVE%';
select * from film where length between 90 and 120 order by length desc limit 20;
select * from actor where last_name like 'A%' order by first_name;
select * from film where (rating='G' or rating='PG') and length is not NULL
                   order by release_year desc limit 15;


# film：每个分级有多少部电影，按数量降序
# film：每个分级的平均片长，只显示平均片长大于 110 的分级
# film：每个 rental_duration 有多少部电影，只显示数量大于 100 的
select rating,count(rating) from film group by rating
                                      order by `count(rating)`desc ;
select rating,avg(length)  from film group by rating having avg(length)>110 ;
select rental_duration,count(rental_duration) from film group by rental_duration
                                              having count(rental_duration)>100;


# rental：统计 2005 年 6 月的租赁笔数
# rental：按「年月」分组统计租赁笔数，按月份升序
# rental：统计归还用时超过 7 天的记录数（提示：DATEDIFF）
# payment：每个 customer_id 的支付总额，只显示总额大于 100 的，按总额降序取前 10
# payment：统计 2005 年 7 月的支付总额和平均单笔金额（平均保留两位小数）
select count(*) from rental
                where rental_date>='2005-06-01' and rental_date <'2005-07-01';
select Year(rental_date) as y,MONTH(rental_date) as m,count(*) from rental
                                                      group by y,m order by y,m;
select count(*) from rental where datediff(return_date,rental_date)>7;
select customer_id,sum(amount) from payment group by customer_id
                                having sum(amount)>100
                                order by sum(amount) desc limit 10;
select sum(amount),round(avg(amount),2) from payment
                               where payment_date>='2005-07-01' and payment_date<'2005-08-01';




# actor：把姓名拼成 姓, 名 的格式（如 ALLEN, MERYL），按姓升序
# film：统计每个分级有多少部电影，分级名称显示成大写
# rental：统计 2005 年 6 月每个 customer_id 的租赁笔数，只要笔数大于 5 的，按笔数降序
# payment：按「天」统计 2005 年 7 月的每日收入，按日期升序

select concat(last_name,', ',first_name) from actor order by last_name;
select Upper(rating),count(rating) from film group by rating;
select customer_id,count(*) from rental where rental_date>='2005-06-01' and rental_date<'2005-07-01'
                                        group by customer_id
                                        having count(*)>5 order by count(*) desc ;
select date(payment_date),sum(amount) from payment
                                where payment_date>='2005-07-01' and payment_date<'2005-08-01'
                                group by date(payment_date) order by date(payment_date);