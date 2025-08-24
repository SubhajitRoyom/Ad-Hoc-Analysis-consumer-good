-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market from dim_customer
where region = "APAC"
and customer ="Atliq Exclusive"
order by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields  
-- unique_products_2020, unique_products_2021, percentage_chg
with
unique_prod_20 as(
select
     count(distinct product_code) as unique_product_2020
from fact_sales_monthly
where fiscal_year= 2020
),
unique_prod_21 as(
select
     count(distinct product_code) as unique_product_2021
from fact_sales_monthly
where fiscal_year= 2021
)
select
     a.unique_product_2020,
     b.unique_product_2021,
     round((b.unique_product_2021-a.unique_product_2020)*100/a.unique_product_2020,2) as percentage_chg
from
     unique_prod_20 a,
     unique_prod_21 b;
     
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields,
-- segment, product_count.
select
     segment,
     count(distinct product_code) as product_count
from 
    dim_product
group by segment
order by  product_count DESC; 

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment
-- product_count_2020, product_count_2021, difference
with 
prod_count_20 as(
select
     p.segment,
     count(distinct s.product_code) as product_count_2020
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code
where s.fiscal_year = 2020
group by p.segment
),
prod_count_21 as(
select
     p.segment,
     count(distinct s.product_code) as product_count_2021
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code
where s.fiscal_year = 2021
group by p.segment
)
select
      a.segment,
      a.product_count_2020,
      b.product_count_2021,
      (b.product_count_2021-a.product_count_2020) as difference
from
    prod_count_20 a
join prod_count_21 b
on a.segment = b.segment
order by  difference desc;

-- 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, product, manufacturing_cost
   
select
      p.product_code,
      p.product,
      m.manufacturing_cost
from fact_manufacturing_cost m 
join dim_product p
on m.product_code = p.product_code
where m.manufacturing_cost in(
                              select max(manufacturing_cost) from fact_manufacturing_cost
                              union
                              select min(manufacturing_cost) from fact_manufacturing_cost
                              )
order by m.manufacturing_cost desc;

--  6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
-- customer_code, customer, average_discount_percentage

select
      c.customer_code,
      c.customer,
      avg(p.pre_invoice_discount_pct) as average_discount_percentage
from fact_pre_invoice_deductions p
join dim_customer c
on p.customer_code = c.customer_code
where c.market ="India" and
fiscal_year = 2021
group by c.customer
order by p.pre_invoice_discount_pct desc
limit 5;	

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns:
-- Month, Year, Gross sales Amount

select
     monthname(s.date) as month,
     s.fiscal_year as fiscal_year,
     round(sum(s.sold_quantity*g.gross_price),2) as gross_sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on s.product_code=g.product_code
and s.fiscal_year=g.fiscal_year
join dim_customer c 
on s.customer_code=c.customer_code
where
     c.customer = "Atliq Exclusive"
group by month, fiscal_year
order by fiscal_year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
-- Quarter, total_sold_quantity

select
     case
         when month(date) in (9,10,11) then 'Q1'
         when month(date) in (12,1,2) then 'Q2'
         when month(date) in (3,4,5) then 'Q3'
         when month(date) in (6,7,8) then 'Q4'
	 end as Quarter,
     sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year= 2020
group by
       case
         when month(date) in (9,10,11) then 'Q1'
         when month(date) in (12,1,2) then 'Q2'
         when month(date) in (3,4,5) then 'Q3'
         when month(date) in (6,7,8) then 'Q4'
	 end
order by total_sold_quantity desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
-- channel, gross_sales_mln, percentage

with
    channel_sales_21 as(
select	
      c.channel,
      round(sum(s.sold_quantity*g.gross_price/1000000),2) as gross_sales_mln
from fact_sales_monthly s 
join dim_customer c 
on s.customer_code = c.customer_code
join fact_gross_price g
on g.product_code=s.product_code
and g.fiscal_year=s.fiscal_year
where s.fiscal_year = 2021
group by c.channel
order by gross_sales_mln desc
),
total_sales_2021 as(
select
     sum(gross_sales_mln) as total_gross_sales_mln
from
   channel_sales_21
)
select
     cs.channel,
     cs.gross_sales_mln,
     round(cs.gross_sales_mln*100/ts.total_gross_sales_mln,2) as percentage
from
   channel_sales_21 cs,
   total_sales_2021 ts;
   
-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division, product_code
with
Product_Ranking as(
select p.division,
       p.product_code,
       p.product,
       sum(s.sold_quantity) as total_sold_quantity,
       dense_rank() over(partition by division order by sum(s.sold_quantity)desc) as rank_order
from
    fact_sales_monthly s 
join dim_product p 
using (product_code)
where s.fiscal_year = 2021
group by p.division, p.product_code
)
select division,
       product_code,
       total_sold_quantity
from
    Product_Ranking
where rank_order<=3;

