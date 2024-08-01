-- Запрос на всю таблицу customers
select count(customer_id)
from customers;

-- Запрос для поиска продавцов с маленькой средней выручкой
select
    e.first_name || ' ' || e.last_name as seller,
    floor(avg(s.quantity * p.price)) as average_income
from sales as s
inner join products as p on s.product_id = p.product_id
inner join employees as e on s.sales_person_id = e.employee_id
group by e.first_name || ' ' || e.last_name
having
    avg(s.quantity * p.price) < (
        select avg(s.quantity * p.price)
        from sales as s
        inner join products as p on sales.product_id = p.product_id
    )
order by average_income;

-- Запрос для поиска топ-10 лучших продавцов
select
    e.first_name || ' ' || e.last_name as seller,
    count(s.sales_id) as operations,
    floor(sum(s.quantity * p.price)) as income
from sales as s
left join employees as e on s.sales_person_id = e.employee_id
left join products as p on s.product_id = p.product_id
group by e.first_name || ' ' || e.last_name
order by income desc
limit 10;

-- Запрос для поиска выручки по дням недели
select 
    e.first_name || ' ' || e.last_name AS seller,
    to_char(s.sale_date, 'day') AS day_of_week,
    floor(sum(s.quantity * p.price)) AS income
from sales as s
left join employees as e on s.sales_person_id = e.employee_id
left join products as p on s.product_id = p.product_id
group by e.first_name, e.last_name, to_char(s.sale_date, 'day'), extract(isodow from s.sale_date)
order by extract(isodow FROM s.sale_date), seller;

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
group by age_category
order by age_category asc;

-- Запрос на подсчёт количества уникальных покупателей по месяцам
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(s.quantity * p.price)) as income
from sales as s
inner join products as p on s.product_id = p.product_id
group by to_char(s.sale_date, 'YYYY-MM')
order by selling_month;

-- Запрос на поиск покупателей, чья первая покупка пришлась на акцию
with ranked_sales as (
    select
        s.customer_id,
        s.sale_date,
        c.first_name || ' ' || c.last_name as customer,
        e.first_name || ' ' || e.last_name as seller,
        sum(p.price * s.quantity) as total_sum,
        row_number()
            over (partition by s.customer_id order by s.sale_date)
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
order by customer_id;
