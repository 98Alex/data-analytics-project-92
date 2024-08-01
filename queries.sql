-- Запрос на всю таблицу customers
select count(customer_id) from customers

-- Запрос для поиска продавцов с маленькой средней выручкой
select
    first_name || ' ' || last_name as seller,
    floor(avg(quantity * price))
from sales as s
inner join products on s.product_id = products.product_id
inner join employees as e on s.sales_person_id = e.employee_id
group by 1
having
avg(quantity * price) < (
    select avg(quantity * price)
    from sales
    inner join products on sales.product_id = products.product_id
)
order by 2

-- Запрос для поиска топ-10 лучших продавцов
select
    e.first_name || ' ' || e.last_name as seller,
    count(s.sales_id) as operations,
    floor(sum(s.quantity * p.price)) as income
from sales as s
left join employees as e on s.sales_person_id = e.employee_id
left join products as p on s.product_id = p.product_id
group by first_name || ' ' || last_name
order by income desc
limit 10

-- Запрос для поиска выручки по дням недели
WITH t_1 AS (
    SELECT
        e.first_name || ' ' || e.last_name as seller,
        TO_CHAR(s.sale_date, 'day') as day_of_week,
        s.quantity * p.price as income,
        EXTRACT(ISODOW FROM s.sale_date) as day_of_week_num
    FROM sales AS s
    LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p on p.product_id = s.product_id
)

SELECT
    seller,
    day_of_week,
    FLOOR(SUM(income)) AS income
FROM t_1
GROUP BY seller, day_of_week, day_of_week_num
ORDER BY day_of_week_num, seller;

-- Запрос для анализа возрастных групп покупателей
with t_1 as (
    select
        customer_id,
        case
            when age between 16 and 25 then '16-25'
            when age between 26 and 40 then '26-40'
            when age > 40 then '40+'
            else 'Unknown'
        end as age_category
    from customers
)

select
    age_category,
    count(customer_id) as age_count
from t_1
group by 1
order by 1

-- Запрос на подсчёт количества уникальных покупателей по месяцам
select 
    to_char(sale_date, 'YYYY-MM') as selling_month,
    count(distinct(customer_id)) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
from sales s 
join products p using(product_id)
group by 1
order by 1 asc

-- Запрос на поиск покупателей, чья первая покупка пришлась на акцию
WITH ranked_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        c.first_name || ' ' || c.last_name AS customer,
        e.first_name || ' ' || e.last_name AS seller,
        sum(p.price * s.quantity) AS total_sum,
        row_number()
            OVER (PARTITION BY s.customer_id ORDER BY s.sale_date)
        AS rn
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN customers AS c ON s.customer_id = c.customer_id
GROUP BY
    s.customer_id,
    c.first_name,
    c.last_name,
    s.sale_date,
    e.first_name,
    e.last_name
)

SELECT
    customer,
    sale_date,
    seller
FROM ranked_sales
WHERE total_sum = 0 AND rn = 1
ORDER BY customer_id;
