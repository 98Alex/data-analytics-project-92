-- Запрос на всю таблицу customers
select * from customers

-- Запрос для поиска продавцов с маленькой средней выручкой
select first_name||' '|| last_name seller,
floor(avg(quantity * price))
from sales s 
join products p using(product_id)
join employees e on e.employee_id = s.sales_person_id 
group by 1
having avg(quantity * price) < (
select avg(quantity * price)
from sales s
join products using(product_id)
)
order by 2

-- Запрос для поиска топ-10 лучших продавцов
select 
first_name|| ' '||last_name  seller,
count(s.sales_id) operations,
floor(sum(s.quantity * p.price)) income
from sales s
left join employees e on s.sales_person_id = e.employee_id
left join products p on s.product_id = p.product_id
group by first_name|| ' '||last_name
order by income
limit 10

-- Запрос для поиска выручки по дням недели
WITH t_1 AS (
  SELECT 
    e.first_name || ' ' || e.last_name AS seller,
    TO_CHAR(s.sale_date, 'Day') AS day_of_week,
    FLOOR(s.quantity * p.price) AS income,
    EXTRACT(ISODOW FROM s.sale_date) AS day_of_week_num
  FROM sales s
  LEFT JOIN employees e ON e.employee_id = s.sales_person_id
  LEFT JOIN products p USING(product_id)
)
SELECT 
  seller,
  day_of_week,
  SUM(income) AS total_income
FROM t_1
GROUP BY seller, day_of_week, day_of_week_num
ORDER BY day_of_week_num, seller

-- запрос для анализа возрастных групп покупателей
with t_1 as(
SELECT customer_id,
  CASE 
    WHEN age BETWEEN 16 AND 25 THEN '16-25'
    WHEN age BETWEEN 26 AND 40 THEN '26-40'
    WHEN age > 40 THEN '40+'
    ELSE 'Unknown'
  END AS age_category
FROM customers c
)
select age_category,
count(customer_id) age_count
from t_1
group by 1
order by 1

-- Запрос на подсчёт количества уникальных покупателей по месяцам
select to_char(sale_date, 'YYYY-MM') date,
count(customer_id) total_customers,
floor(sum(s.quantity * p.price)) income
from sales s 
join products p using(product_id)
group by 1
order by 1 asc
