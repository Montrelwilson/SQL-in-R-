
library(sqldf)
library(readr)
library(utils)
Purchases2019 = read.csv("BAToysPurchasesJan2019.csv", header = T)
Sales2019 = read.csv("BAToysTAXSalesJan2019.csv", header = T)
Price2019 = read.csv("PriceListing2019.csv", header = T)
Sales2017 = read.csv("BAToysTAXSalesJan2017.csv", header = T)
Price2017 = read.csv("PriceListing2017.csv", header = T)


#1. Query to generate total revenue by state, city, brand, and store

sqldf("SELECT State, City, Brand, Store, SUM(SalesDollars) AS TotalRevenue
    FROM Sales2019
    GROUP BY State, City, Brand, Store
    ORDER BY TotalRevenue DESC
")

#---------------------------------------------------------------------------------------------------------
#2 Query to generate total, average, min, and max revenue for each state/store

sqldf("SELECT State, Store,
       SUM(SalesDollars) AS TotalRevenue,
       AVG(SalesDollars) AS avgRevenue,
       MIN(SalesDollars) AS minRevenue,
       MAX(SalesDollars) AS maxRevenue
FROM Sales2019
GROUP BY State, Store
")

#---------------------------------------------------------------------------------------------------------

#3 For each store, generate the total revenue and express it as a percentage of the company's total revenues.

        # There is two ways to solve this:

# First, calculate the company's total revenue
total_company_revenue_query <- "SELECT SUM(SalesDollars) AS TotalCompanyRevenue FROM Sales2019"
total_company_revenue <- sqldf(total_company_revenue_query)$TotalCompanyRevenue
total_company_revenue

# Then, calculate each store's total revenue as a percentage of the company's total revenue
store_revenue_percentage_query <- sprintf("
SELECT Store, SUM(SalesDollars) AS StoreTotalRevenue,
       (SUM(SalesDollars) / %f) * 100 AS RevenuePercentage
FROM Sales2019
GROUP BY Store
", total_company_revenue)

store_revenue_percentage <- sqldf(store_revenue_percentage_query)
store_revenue_percentage


#Second way using a subquery
sqldf("SELECT Store, SUM(SalesDollars) AS StoreTotalRevenue, 
    (SUM(SalesDollars) / (SELECT SUM(SalesDollars) FROM Sales2019)) * 100 AS RevenuePercentage
    FROM Sales2019
    GROUP BY Store
    ")


#---------------------------------------------------------------------------------------------------------

#4 For each store, calculate COGS and express it as a percentage of the company's total COGS. 

    # There is two ways to solve this:

#First, calculate the company's total COGS
total_company_cogs_query <- "SELECT SUM(PurchasePrice * SalesQuantity) AS TotalCompanyCOGS FROM Sales2019"
total_company_cogs <- sqldf(total_company_cogs_query)$TotalCompanyCOGS

# Then, calculate each store's COGS as a percentage of the company's total COGS
store_cogs_percentage_query <- sprintf("
SELECT Store, SUM(PurchasePrice * SalesQuantity) AS StoreCOGS,
       (SUM(PurchasePrice * SalesQuantity) / %f) * 100 AS COGSPercentage
FROM Sales2019
GROUP BY Store
", total_company_cogs)

store_cogs_percentage <- sqldf(store_cogs_percentage_query)
store_cogs_percentage


#Second way using a subquery
sqldf("SELECT Store, SUM(PurchasePrice * SalesQuantity) AS StoreCOGS,
(SUM(PurchasePrice * SalesQuantity) / (SELECT SUM(PurchasePrice * SalesQuantity) FROM Sales2019)) * 100 AS COGSPercentage
    FROM Sales2019
    GROUP BY Store
      ")



#---------------------------------------------------------------------------------------------------------

#5 Determine the number of products offered for sale in 2019 that were not sold.
# Assuming you have a 'products_2019' dataframe with all products offered in 2019

unsold_products_query <- "
SELECT p.ToyDescription
FROM Price2019 p
LEFT JOIN Sales2019 s ON p.BrandId = s.Brand AND p.ToyDescription = s.Description
WHERE s.SalesQuantity IS NULL OR s.SalesQuantity = 0
GROUP BY p.ToyDescription
"
unsold_products <- sqldf(unsold_products_query)
nrow(unsold_products)

#---------------------------------------------------------------------------------------------------------

#6. Determine the month and day that generated the most revenue across all stores. Include the day of the week in your analysis.
# Extract month and day from the SalesDate column and determine the highest revenue

sqldf(" SELECT strftime('%m', SalesDate) AS Month, strftime('%d', SalesDate) AS Day, SUM(SalesDollars) AS TotalRevenue
  FROM Sales2019
  GROUP BY Month, Day
  ORDER BY TotalRevenue DESC
  LIMIT 1
")

#---------------------------------------------------------------------------------------------------------

#7. Determine the Top 5 products based on revenue and gross profit sold across all stores for 2019. Include the Brand and Description in the output.
# Calculate revenue and gross profit for each product

sqldf("SELECT Description, Brand, SUM(SalesDollars) AS Revenue,
       SUM(SalesDollars - (PurchasePrice * SalesQuantity)) AS GrossProfit
      FROM Sales2019
      GROUP BY Description, Brand
      ORDER BY Revenue DESC, GrossProfit DESC
      LIMIT 5
")

#---------------------------------------------------------------------------------------------------------

#8. Of the 21 stores, which one produced the smallest contribution to Gross Profit and the generated the least amount of Revenue. Note: This could be two different stores.
# Calculate gross profit and revenue for each store, then find the store with the smallest contribution

sqldf("SELECT Store, SUM(SalesDollars - (PurchasePrice * SalesQuantity)) AS GrossProfit,
      SUM(SalesDollars) AS Revenue
      FROM Sales2019
      GROUP BY Store
      ORDER BY GrossProfit ASC, Revenue ASC
      LIMIT 1
")

#---------------------------------------------------------------------------------------------------------

#9. Determine the most and least expensive products offered for sale by the toy company.
# Find the most and least expensive products

      # There is two different tables we can get the info from to solve this:
most_least_expensive_products_query <- "
SELECT Description, MAX(SalesPrice) AS MostExpensive, MIN(SalesPrice) AS LeastExpensive
FROM Sales2019
"
most_least_expensive_products <- sqldf(most_least_expensive_products_query)
most_least_expensive_products

#Other way
sqldf("Select ToyDescription, MAX(SalesPrice) AS MostExpensive, MIN(SalesPrice) AS LeastExpensive
    FROM Price2019
      ")

#---------------------------------------------------------------------------------------------------------

#10. The Toy Company purchases all of its products from 4 different vendors. Which vendor did the company by the most product from based on total dollar amount and total product quantity? Note: this could be two different vendors.
# Calculate the total dollar amount and quantity for each vendor
sqldf("SELECT VendorName, SUM(PurchasePrice * SalesQuantity) AS TotalDollarAmount,
       SUM(SalesQuantity) AS TotalQuantity
      FROM Sales2019
      GROUP BY VendorName
      ORDER BY TotalDollarAmount DESC, TotalQuantity DESC
      LIMIT 1
")


#---------------------------------------------------------------------------------------------------------

#11. Finally, per a review of the product price listing for two years prior, 2017, the Toy company offers 5025 products for sale-the same as 2019.
# determine which, if any, products were not sold in both years.


sqldf("SELECT p2017.ToyDescription
    FROM Price2017 p2017 LEFT JOIN Sales2017 s2017 ON p2017.BrandId = s2017.Brand AND p2017.ToyDescription = s2017.Description
    LEFT JOIN Sales2019 s2019 ON p2017.BrandId = s2019.Brand AND p2017.ToyDescription = s2019.Description
    WHERE s2017.SalesQuantity IS NULL OR s2017.SalesQuantity = 0
    AND s2019.SalesQuantity IS NULL OR s2019.SalesQuantity = 0
    GROUP BY p2017.ToyDescription
")







