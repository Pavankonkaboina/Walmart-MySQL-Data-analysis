create database if not exists Walmart;

create table if not exists sales (
invoice_ID  VARCHAR (30) NOT NULL PRIMARY KEY,
branch	VARCHAR (10) NOT NULL,
city VARCHAR (30) NOT NULL,	
customer_type VARCHAR (30) NOT NULL ,
gender VARCHAR (30) NOT NULL,	
product_line VARCHAR (150) NOT NULL,	
unit_price DECIMAL (10,2) NOT NULL ,	
quantity INT NOT NULL,	
vat FLOAT(6,4) NOT NULL	,
total DECIMAL (12,4) NOT NULL,	
date DATETIME NOT NULL	,
time TIME NOT NULL ,	
payment_method VARCHAR(15) NOT NULL	,
cogs DECIMAL (10,2) NOT NULL ,	
gross_margin_prct FLOAT (11,9) NOT NULL ,
gross_income DECIMAL(12,4) NOT NULL ,
rating FLOAT (2,1) NOT NULL
);


select * from sales;

-- creating time_of_day 
select time ,
	(case 
		when time between "00:00:00" and "12:00:00" then "Morning"
		when time between "12:01:00" and "16:00:00" then "Afternoon"
		else "Evening"
	End ) as time_of_day from sales;
    
--
Alter table sales add column time_of_day VARCHAR (25);

--
UPDATE sales
SET time_of_day = (case 
		when time between "00:00:00" and "12:00:00" then "Morning"
		when time between "12:01:00" and "16:00:00" then "Afternoon"
		else "Evening"
	End);
    
-- creating day_name 
select date, 
DAYNAME (date)
from sales ;

-- 
Alter table sales add column day_name VARCHAR (15);

--
UPDATE sales
SET day_name = DAYNAME (date);

-- creating month_name
select date,
Monthname (date)
from sales ;

-- 
Alter table sales add column month_name VARCHAR (10);

--
UPDATE sales
SET month_name = MonthNAME (date);

-- ------------------------------------------------- Generic questions -----------------------------------------------------------------------

-- how many distinct city are there in the data
select distinct city from sales;

-- In which city is each branch?
select distinct city, branch from sales;

-- ------------------------------------------------- Product ---------------------------------------------------------------------------------

--  How many unique product lines does the data have?
select count(distinct product_line) as unique_product_lines from sales;

-- What is the most common payment method?
select distinct payment_method , count(*) from sales
group by payment_method
order by 2 desc ;

 -- What is the most selling product line?
select distinct product_line , count(*) from sales
group by product_line
order by 2 desc ; 

-- What is the total revenue by month?
select month_name , sum(total) from sales
group by 1;

-- What month had the largest COGS?
select month_name , sum(cogs) from sales
group by 1
order by 2 desc;

-- What product line had the largest revenue?
select distinct product_line , sum(gross_income)as profit from sales
group by 1
order by 2 desc ; 

-- What is the city with the largest revenue?
select city , sum(gross_income ) from sales
group by 1
order by 2 desc;

-- What product line had the largest VAT?
select product_line , sum(vat) from sales
group by 1 
order by 2 desc;

-- Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
select product_line , sum(quantity),
case 
when sum(quantity) > (select(avg(quantity)) from sales ) then 'Good'
else 'Bad'
end as t1
from sales
group by 1;

-- Which branch sold more products than average product sold?
select branch, sum(quantity) as qty
from sales
group by branch 
having sum(quantity) > (select avg(quantity) from sales) ;

-- What is the most common product line by gender?
select gender, product_line, purchase_count from 
( select gender , product_line , count(*) as purchase_count,
	rank() over (partition by gender order by count(*) desc) as rnk from sales 
    group by gender , product_line  
)ranked
where rnk = 1;

-- What is the average rating of each product line?
select round(avg(rating),2) , product_line from sales
group by 2
order by 1;

-- -------------------------------------------------------------Sales-------------------------------------------------------------------------

-- Number of sales made in each time of the day per weekday
select count(quantity) , time_of_day, day_name from sales
where day_name not like  "Sunday" and day_name not like "Saturday" 
group by 2 , 3
order by 1 desc ;

-- Which of the customer types brings the most revenue?
select customer_type , sum(total) as most_revenue from sales
group by 1
order by 2 desc 
limit 1;

-- Which city has the largest tax percent/ VAT (Value Added Tax)?
select city , avg(vat)  from sales
group by 1 
order by 2 desc
limit 1;

-- Which customer type pays the most in VAT?
select customer_type , avg(vat) from sales 
group by 1
order by 2 desc
limit 1;

-- Week-over-week sales growth per branch
SELECT branch, WEEK(date) AS week_no, SUM(total) AS weekly_sales,
LAG(SUM(total)) OVER (PARTITION BY branch ORDER BY WEEK(date)) AS prev_week_sales,
(SUM(total) - LAG(SUM(total)) OVER (PARTITION BY branch ORDER BY WEEK(date))) / LAG(SUM(total)) OVER (PARTITION BY branch ORDER BY WEEK(date)) * 100 AS wow_growth
FROM sales
GROUP BY branch, WEEK(date);

-- ---------------------------------------------------------Customer--------------------------------------------------------------------------

-- How many unique customer types does the data have?
select distinct(customer_type) from sales;

-- How many unique payment methods does the data have?
select distinct (payment_method) from sales;

-- What is the most common customer type?
select customer_type , count(*) from sales
group by 1 
order by 2 desc
limit 1;

-- Which customer type buys the most?
select customer_type , sum(total) from sales
group by 1
order by 2 desc
limit 1;
-- What is the gender of most of the customers?
select gender , count(*) from sales
group by 1 
order by 2 desc 
limit 1;

-- What is the gender distribution per branch?
select gender , branch , count(*) from sales
group by 1,2 
order by 3;

-- Which time of the day do customers give most ratings?
select time_of_day, count(rating) from sales
group by 1
order by 2 desc;

-- Which time of the day do customers give most ratings per branch?
select time_of_day , branch from 
(select time_of_day , branch, count(rating) ,
rank() over (partition by branch order by count(rating)) as rnk
from sales
group by 1,2) ranking
where rnk = 1 ;

-- Which day of the week has the best avg ratings?
select avg(rating) , day_name from sales
group by 2 
order by 1 desc 
limit 1; 

-- Which day of the week has the best average ratings per branch?
select day_name , branch , best_rating from 
( select day_name , branch, avg(rating) as best_rating ,
rank () over (partition by branch order by avg(rating) desc) as rnk
from sales
group by 1,2 )ranking
where rnk = 1;

-- What is the average spend per customer type and how does it vary across branches? 
select branch , avg(total) , customer_type from sales
group by 1, 3
order by 2; 

-- How many customers fall into each spend category: low (<$100), medium ($100–$300), high (>$300) only for one visit?
select customer_type,
(case
when total < 100 then "Low spending" 
when total > 100 and total < 300 then "Medium spending"
else "High spending" 
end ) spending_category
from sales;







