#Install Packages
library(data.table)
library(sqldf)
library(utils)

#Import Files
sales <-fread("BCGG_Sales6302023.csv")
customers <-fread("BCGG_Customer6302023.csv")
custInvoices <-fread("BCGG_InvoiceSales6302023.csv")
purchases <-fread("BCGG_Purchases6302023.csv")
prices <-fread("BCGG_PriceFile6302023.csv")
vendors <-fread("BCGG_Vendors6302023.csv")

#Change Date Fields
sales$SODate <-as.Date(sales$SODate, '%m/%d/%Y')
custInvoices$SODate <-as.Date(custInvoices$SODate, '%m/%d/%Y')
purchases$PurchaseDate <-as.Date(purchases$PurchaseDate, '%m/%d/%Y')

#Questions (1-8)

#1.	What product was sold the most based upon quantity by BCGG?  
#Include the BrandID, Description, and Quantity Sold in the result.

sqldf("SELECT s.BrandID, p.Description, SUM(s.Quantitysold) as TotalQuantitySold
        FROM sales s LEFT JOIN prices p ON s.BrandID = p.BrandID
        GROUP BY s.BrandID, p.Description
        ORDER BY TotalQuantitySold DESC
        LIMIT 1")

#-----------------------------------------------------------------------------------

#2.	What Zip Code did BCGG generate the largest amount of Revenue from for the period?
#Include the City, State, ZIP Code and Revenue in the result.
#A list in descending order is sufficient.

sqldf(" SELECT  c.City, c.State, c.ZIPCode, SUM(s.Dollars) as TotalRevenue
    FROM sales s JOIN customers c ON s.CustNumber = c.CustomerNum
    GROUP BY c.City, c.State, c.ZIPCode
    ORDER BY TotalRevenue DESC")

#-----------------------------------------------------------------------------------

#3.	What product produced the largest amount of Gross Profit for BCGG
#for the period 7/1/2022-12/31/2022?  Include the BrandID, Description,
#and Gross Profit in the result.  Note the entire sales files includes 
#the period from 7/1/2022-6/30/2023.
sqldf("SELECT  s.BrandID, p.Description, SUM(s.Dollars - (t.QuantityPurchased*t.PurchasePrice)) AS GrossProfit
      FROM  sales s LEFT JOIN prices p ON s.BrandID = p.BrandID LEFT JOIN purchases t on s.BrandID = t.BrandID
      WHERE  s.SODate BETWEEN '2022-07-01' AND '2022-12-31'
      GROUP BY s.BrandID, p.Description
      ORDER BY GrossProfit DESC
      LIMIT 1")

#-----------------------------------------------------------------------------------

#4.	In what month and day of week did BCGG generate the most revenue?
#You can create two different queries and include Month and Revenue in one result,
#and Day of Week and Revenue in the second result.


#Finding Month 
sqldf("
SELECT strftime('%m', SODate) AS Month, SUM(Dollars) AS TotalRevenue
      FROM sales
      GROUP BY Month
      ORDER BY TotalRevenue DESC
      LIMIT 1")


#Finding Week
sqldf("SELECT strftime('%w', SODate) AS DayOfWeek,CASE strftime('%w', SODate) 
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS DayName, SUM(Dollars) AS TotalRevenue
FROM sales
GROUP BY DayOfWeek
ORDER BY  TotalRevenue DESC
LIMIT 1")

#-----------------------------------------------------------------------------------

#5.	Management of BCGG would like to ensure that customers were invoiced for all
#amounts sold during the period.  Provide a reconciliation of sales revenue to amounts
#invoiced at the customer level for the period.  Note any exceptions.  
#The listing should include the Customer Number and Revenue, and any other fields
#that you would like to provide.
library(sqldf)

# SQL query for reconciliation
sqldf("SELECT s.CustomerNum, s.TotalSalesRevenue,
    COALESCE(i.TotalInvoicedAmount, 0) AS TotalInvoicedAmount,
    (s.TotalSalesRevenue - COALESCE(i.TotalInvoicedAmount, 0)) AS Discrepancy
FROM 
    (SELECT CustNumber AS CustomerNum, SUM(Dollars) AS TotalSalesRevenue
    FROM sales
    GROUP BY CustNumber) s LEFT JOIN   (SELECT  CustNumber AS CustomerNum, SUM(Dollars) AS TotalInvoicedAmount
    FROM 
        custInvoices
    GROUP BY 
        CustNumber) i ON s.CustomerNum = i.CustomerNum
ORDER BY 
    Discrepancy DESC")


#-----------------------------------------------------------------------------------

#6.	What is the highest priced item that BCGG sells?  Please include the BrandID,
#Description, Retail Price, and Sales Price in the result.  Base the highest priced
#item on Sales Price.

sqldf("SELECT BrandID, Description, RetailPrice, SalesPrice
    FROM prices
    ORDER BY SalesPrice DESC
    LIMIT 1")

#-----------------------------------------------------------------------------------

#7.	Identify the Vendor who BCGG purchased the most product from during the period
#based on purchase price.  Include the Vendor Number, Vendor Name, and Total Dollar
#Amount in the result.

sqldf("SELECT p.VendorNumber, v.VendorName, SUM(p.Dollars) AS TotalPurchaseAmount
     FROM purchases p JOIN vendors v ON p.BrandID = v.BrandID
     GROUP BY p.VendorNumber, v.VendorName
     ORDER BY TotalPurchaseAmount DESC
     LIMIT 1")

#-----------------------------------------------------------------------------------

#8.	Determine which product generates the highest gross profit on a per unit basis
#for BCGG.  Include BrandID, Description, Sales Price, Cost per unit, and Gross Profit
#in the result.

sqldf("SELECT p.BrandID, p.Description, p.SalesPrice, p.PurchasePrice AS CostPerUnit, (p.SalesPrice - p.PurchasePrice) AS GrossProfitPerUnit
    FROM prices p
    ORDER BY GrossProfitPerUnit DESC
    LIMIT 1")

#-----------------------------------------------------------------------------------

#9.	How many different customers purchased Gentleman Jack 1750ML?  Include the
#Customer Number, Customer Name, and total bottles purchased in the result.

sqldf("SELECT c.CustomerNum, c.CustomerName, SUM(s.QuantitySold) AS TotalBottlesPurchased
      FROM sales s JOIN prices p ON s.BrandID = p.BrandID JOIN customers c ON s.CustNumber = c.CustomerNum
      WHERE p.Description like '%Gentleman Jack%' AND p.Size = '750mL'
      GROUP BY c.CustomerNum, c.CustomerName
      ORDER BY TotalBottlesPurchased DESC")


#-----------------------------------------------------------------------------------

#Bonus Question

#Total revenue at the customer level 

sqldf("SELECT s.CustNumber, sum(s.Dollars), c.CustomerName, c.CustomerNum
FROM sales s left join customers c on s.CustNumber = c.CustomerNum
GROUP BY c.CustomerNum
ORDER BY sum(Dollars) desc")

