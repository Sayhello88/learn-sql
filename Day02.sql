# 查出演员 NICK WAHLBERG 演过的所有电影标题（三表连接）
# 统计每个演员演过多少部电影，按数量降序取前 10（连接 + 分组）
# 统计每个分类（category.name）下有多少部电影（film_category + category）
# 找出从未租过任何电影的客户（customer LEFT JOIN rental，想想 WHERE 怎么写）
# （挑战）找出同姓的演员对，比如两个都姓 ALLEN 的演员。提示：actor 表自己连自己
select concat(ac.first_name,' ',ac.last_name) ,fi.title from actor as ac
    join film_actor as fa on ac.actor_id=fa.actor_id join film as fi on fi.film_id=fa.film_id
    where concat(ac.first_name,' ',ac.last_name)='NICK WAHLBERG';
select concat(ac.first_name,' ',ac.last_name),count(fi.film_id) from actor as ac
    join film_actor as fa on fa.actor_id=ac.actor_id join film as fi on fi.film_id=fa.film_id
    GROUP BY ac.actor_id order by count(fi.film_id) desc limit 10;
select ca.name,count(fc.film_id) from category as ca
    join film_category as fc on ca.category_id=fc.category_id
    group by ca.name;
select c.customer_id,concat(c.first_name,' ',c.last_name) from customer as c
    left join rental as r on c.customer_id=r.customer_id
    where r.rental_id is NULL;
select a.actor_id,concat(a.first_name,' ',a.last_name),b.actor_id,concat(b.first_name,' ',b.last_name) from actor as a
    join actor as b on a.last_name=b.last_name where a.actor_id<b.actor_id order by a.last_name;