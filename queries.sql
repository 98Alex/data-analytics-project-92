-- Запрос на всю таблицу customers
select count(customer_id) from customers

-- Запрос для поиска продавцов с маленькой средней выручкой
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
GROUP BY e.first_name, e.last_name
HAVING
    AVG(s.quantity * p.price) < (
        SELECT AVG(s2.quantity * p2.price)
        FROM sales AS s2
        INNER JOIN products AS p2 ON s2.product_id = p2.product_id
    )
ORDER BY average_income;

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
with t_1 as (
    select
        e.first_name || ' ' || e.last_name as seller,
        TO_CHAR(s.sale_date, 'day') as day_of_week,
        s.quantity * p.price as income,
        EXTRACT(ISODOW from s.sale_date) as day_of_week_num
    from sales AS s
    left join employees as e on s.sales_person_id = e.employee_id
    left join products as p on p.product_id = s.product_id
)

select
    seller,
    day_of_week,
    FLOOR(SUM(income)) as income
from t_1
group by seller, day_of_week, day_of_week_num
order by day_of_week_num, seller

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
    TO_CHAR(sale_date, 'YYYY-MM') as selling_month,
    count(distinct(customer_id)) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
from sales s 
join products p using(product_id)
group by 1
order by 1 asc

-- Запрос на поиск покупателей, чья первая покупка пришлась на акцию
with ranked_sales as (
    select
        s.customer_id,
        s.sale_date,
        c.first_name || ' ' || c.last_name as customer,
        e.first_name || ' ' || e.last_name as seller,
        sum(p.price * s.quantity) as total_sum,
        row_number()
            OVER (PARTITION by s.customer_id order by s.sale_date)
        as rn
    from sales as s
    inner join products as p on s.product_id = p.product_id
inner join employees as e on s.sales_person_id = e.employee_id
inner join customers as c on s.customer_id = c.customer_id
group by
    s.customer_id,
    c.first_name,
    c.last_name,
    s.sale_date,
    e.first_name,
    e.last_name
)

select
    customer,
    sale_date,
    seller
from ranked_sales
where total_sum = 0 and rn = 1
order by customer_id
