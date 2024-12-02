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


