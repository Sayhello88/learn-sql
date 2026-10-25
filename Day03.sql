# 查出所有片长高于全站平均片长的电影，按片长降序
select title,length from film where length>(select avg(length) from film)
                              order by length desc ;
# 查出所有租过电影的客户，用 IN 子查询写（写完后想想能不能改成 JOIN）
select * from customer where customer_id in (select customer_id from rental );
# 找出从未被租出去过的电影（film → inventory → rental，用 NOT EXISTS）
select f.film_id,f.title from film as f
                         where not exists(select 1 from inventory as i
                             join rental as r on i.inventory_id = r.inventory_id
                                                   where f.film_id=i.film_id);


# 先算出每个演员演了多少部电影，再筛选出数量大于 30 的，按数量降序（用 FROM 子查询）
select * from (
    select concat(a.first_name,' ',a.last_name),count(*) as co
      from actor as a join film_actor as fa on a.actor_id=fa.actor_id
      group by a.actor_id) as t where t.co>30 order by t.co desc ;
# 把 actor 的姓名和 customer 的姓名合并成一列，用 UNION；再换成 UNION ALL，对比行数差多少
select concat(a.first_name,' ',a.last_name) from actor as a
union
select concat(b.first_name,' ',b.last_name) from customer as b;
select concat(a.first_name,' ',a.last_name) from actor as a
union all
select concat(b.first_name,' ',b.last_name) from customer as b;