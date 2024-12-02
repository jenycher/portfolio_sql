-------У нас две таблицы:
-----Таблица заказов в аптеках (pharma_orders):
---pharmacy_name: название аптеки
---order_id: ID заказа
---drug_name: название препарата
---price: цена
---count: количество в штуках
---city: город, в котором был сделан заказ
---report_date: дата заказа
---customer_id: ID клиента

-----Таблица клиентов(customers)
---customer_id: ID клиента
---date_of_birth: дата рождения
---first_name: имя
---last_name: фамилия
---second_name: отчество
---gender: пол


--- 1. Вывести топ-3 аптеки
SELECT 
	pharmacy_name, 
    SUM(price * count) AS total_sales
FROM 
    pharma_orders
GROUP BY 
	pharmacy_name
ORDER BY 
	total_sales DESC
LIMIT 3;

--- 2. Вывести топ-3 лекарства
SELECT 
	drug_name, 
    SUM(price * count) AS total_sales
FROM 
	pharma_orders
GROUP BY 
	drug_name
ORDER BY 
	total_sales DESC
LIMIT 3;

--- 3. Найти аптеки с оборотом от 1.8 миллионов
SELECT 
	pharmacy_name, 
    SUM(price * count) AS total_sales
FROM 
	pharma_orders
GROUP BY 
	pharmacy_name
HAVING SUM(price * count) > 1800000;


--- 4. Посчитать накопленную сумму продаж по каждой аптеке ежедневно
SELECT pharmacy_name, 
	   report_date,
       SUM(SUM(price * count)) OVER (PARTITION BY pharmacy_name ORDER BY report_date) AS cumulative_sales
FROM 
		pharma_orders
GROUP BY 
		pharmacy_name, report_date
ORDER BY 
		pharmacy_name, report_date;


--- 5. Количество клиентов в аптеках
SELECT pharmacy_name, 
	   COUNT(DISTINCT customer_id) AS unique_customers
FROM 
		pharma_orders
GROUP BY 
		pharmacy_name
ORDER BY 
		unique_customers DESC;


--- 6. Лучшие клиенты
SELECT  c.customer_id, 
		c.first_name, 
        c.last_name, 
        c.second_name, 
        SUM(o.price * o.count) AS total_spent
FROM 
		pharma_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 
		c.customer_id, c.first_name, c.last_name, c.second_name
ORDER BY 
		total_spent DESC
LIMIT 10;


--- 7. Накопленная сумма по клиентам
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name, ' ', c.second_name) AS full_name,
       SUM(o.price * o.count) AS total_spent
FROM pharma_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.second_name
ORDER BY total_spent DESC;


--- 8. Самые частые клиенты аптек Горздрав и Здравсити
-- Создание временной таблицы для аптеки Горздрав
WITH gorzdrav_customers AS (
    SELECT c.customer_id, 
           CONCAT(c.first_name, ' ', c.last_name, ' ', c.second_name) AS full_name,
           COUNT(o.order_id) AS order_count
    FROM pharma_orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.pharmacy_name = 'Горздрав'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.second_name
    ORDER BY order_count DESC
    LIMIT 10
),

-- Создание временной таблицы для аптеки Здравсити
zdravsiti_customers AS (
    SELECT c.customer_id, 
           CONCAT(c.first_name, ' ', c.last_name, ' ', c.second_name) AS full_name,
           COUNT(o.order_id) AS order_count
    FROM pharma_orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.pharmacy_name = 'Здр
авсити'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.second_name
    ORDER BY order_count DESC
    LIMIT 10
)

-- Объединение данных
SELECT * FROM gorzdrav_customers
UNION ALL

------------
---Часть 2
--- 1. Сравнение динамики продаж между Москвой и Санкт-Петербургом
--- 1. Сравнение динамики продаж между Москвой и Санкт-Петербургом по месяцам
 WITH moscow_sales AS (
    SELECT EXTRACT(MONTH FROM TO_DATE(report_date, 'YYYY-MM-DD')) AS month, 
    SUM(price * count) AS total_sales
    FROM pharma_orders
    WHERE city = 'Москва'
    GROUP BY month
),
spb_sales AS (
    SELECT EXTRACT(MONTH FROM TO_DATE(report_date, 'YYYY-MM-DD')) AS month, 
          SUM(price * count) AS total_sales
    FROM pharma_orders
    WHERE city = 'Санкт-Петербург'
    GROUP BY month
)

SELECT 
    COALESCE(m.month, s.month) AS month,
    COALESCE(m.total_sales, 0) AS moscow_sales,
    COALESCE(s.total_sales, 0) AS spb_sales,
    (COALESCE(m.total_sales, 0) - COALESCE(s.total_sales, 0)) AS difference,
     CASE 
        WHEN COALESCE(s.total_sales, 0) = 0 THEN NULL
        ELSE (COALESCE(m.total_sales, 0) - COALESCE(s.total_sales, 0)) * 100 / COALESCE(s.total_sales, 0)
    END AS difference_percentage
FROM moscow_sales m
FULL OUTER JOIN spb_sales s ON m.month = s.month
ORDER BY month;

--- 2. Лекарства от насморка
WITH aqua_sales AS (
    SELECT LOWER(drug_name) AS drug_name, 
           SUM(price * count) AS total_sales
    FROM pharma_orders
    WHERE LOWER(drug_name) LIKE 'аква%'
    GROUP BY LOWER(drug_name)
)

SELECT 
    drug_name,
    total_sales,
    ROUND(total_sales * 100.0 / SUM(total_sales) OVER (),2) AS sales_share
FROM aqua_sales
ORDER BY total_sales DESC;


--- 3. Кто наши клиенты
--- Вычисляем возраст клиентов на основе даты рождения.
---  Рассчитать количество клиентов по группам. Наши группы:
---1. мужчины младше 30, 
---2. мужчины от 30 до 45, 
---3. мужчины старше 45. 
---4. Женщины младше 30,
---5  женщины от 30 до 45, 
---6 женщины старше 45.
---Подсчитываем долю продаж на каждую группу
WITH age_groups AS (
    SELECT 
        customer_id,
        gender,
        EXTRACT(YEAR FROM AGE(date_of_birth::date)) AS age,
        CASE
            WHEN gender = 'муж' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) < 30 THEN 'Мужчины младше 30'
            WHEN gender = 'муж' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) BETWEEN 30 AND 45 THEN 'Мужчины от 30 до 45'
            WHEN gender = 'муж' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) > 45 THEN 'Мужчины старше 45'
            WHEN gender = 'жен' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) < 30 THEN 'Женщины младше 30'
            WHEN gender = 'жен' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) BETWEEN 30 AND 45 THEN 'Женщины от 30 до 45'
            WHEN gender = 'жен' AND EXTRACT(YEAR FROM AGE(date_of_birth::date)) > 45 THEN 'Женщины старше 45'
        END AS age_group
    FROM customers
)
SELECT 
    age_group, 
    COUNT(DISTINCT g.customer_id) AS client_count,
    COALESCE(SUM(o.price * o.count), 0) AS total_sales,
    ROUND(COALESCE(SUM(o.price * o.count), 0) * 100.0 / NULLIF(SUM(SUM(o.price * o.count)) OVER (), 0),2) AS sales_share
FROM age_groups g
LEFT JOIN pharma_orders o ON g.customer_id = o.customer_id
WHERE age_group IS NOT NULL
GROUP BY age_group
ORDER BY age_group;



