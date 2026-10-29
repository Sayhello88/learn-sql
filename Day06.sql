# 1. 对 film(title) 建索引，用 EXPLAIN 对比 WHERE title LIKE 'A%' 建索引前后的 type 和 rows
create index film_title on film (title);
explain select title from film where title like 'A%';
# 2. 对比这两条的 EXPLAIN：
create index idx_pay_date on payment (payment_date);
explain SELECT * FROM payment WHERE YEAR(payment_date) = 2005;
explain SELECT * FROM payment WHERE payment_date >= '2005-07-01' AND payment_date < '2005-07-08';
# 3. 建联合索引 payment(customer_id, payment_date)，分别 EXPLAIN 这三个查询，看哪个用得上：
#    - WHERE customer_id = 1
#    - WHERE customer_id = 1 AND payment_date > '2005-06-01'
#    - WHERE payment_date > '2005-06-01'
create index p_c_d on payment (customer_id,payment_date);
explain select * from payment where customer_id=1;
explain select * from payment WHERE customer_id = 1 AND payment_date > '2005-06-01';
explain select * from payment WHERE payment_date > '2005-06-01';
# 4. 找一条 type = ALL 的查询（比如 WHERE last_name LIKE '%SON'），想办法把它优化到 range 或 ref
CREATE INDEX idx_actor_last ON actor (last_name);
explain select * from actor where last_name like '%SON';
explain select * from actor where last_name like 'SON%';

# 5. 故意写一条会触发 Using filesort 的查询，再写一条能避免的——说出区别
-- 有 filesort：按不在索引顺序里的列排
EXPLAIN SELECT title FROM film WHERE title LIKE 'A%' ORDER BY release_year;

-- 无 filesort：按索引列本身排
EXPLAIN SELECT title FROM film WHERE title LIKE 'A%' ORDER BY title;
