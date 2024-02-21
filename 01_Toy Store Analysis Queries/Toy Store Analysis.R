library(readr)
head(BAToysPurchasesJan2019)
head(BAToysTAXSalesJan2017)
head(BAToysTAXSalesJan2019)
head(PriceListing2017)
head(PriceListing2019)
summary(BAToysPurchasesJan2019)

#1. To generate total revenue by state, city, brand, and store, and to sort the results:
library(dplyr)

BAToysTAXSalesJan2019 %>%
  group_by(State, City, Brand, Store) %>%
  summarise(TotalRevenue = sum(SalesDollars, na.rm = TRUE)) %>%
  arrange(desc(TotalRevenue))

#2. To calculate total revenue, average revenue, minimum, and maximum revenue for each state/store:

BAToysTAXSalesJan2019 %>%
  group_by(State, Store) %>%
  summarise(
    SumRevenue = sum(SalesDollars, na.rm = TRUE),
    AvgRevenue = mean(SalesDollars, na.rm = TRUE),
    MinRevenue = min(SalesDollars, na.rm = TRUE),
    MaxRevenue = max(SalesDollars, na.rm = TRUE)
  )

#3. For each store, calculate the total revenue as a percentage of the company's total revenues:

total_revenue <- sum(BAToysTAXSalesJan2019$SalesDollars, na.rm = TRUE)

BAToysTAXSalesJan2019 %>%
  group_by(Store) %>%
  summarise(TotalRevenue = sum(SalesDollars, na.rm = TRUE)) %>%
  mutate(RevenuePercentage = (TotalRevenue / total_revenue) * 100)

#4. For each store, calculate COGS and express it as a percentage of the company's total COGS. Assuming that COGS is the product of SalesQuantity and PurchasePrice:

BAToysTAXSalesJan2019$COGS <- BAToysTAXSalesJan2019$SalesQuantity * BAToysTAXSalesJan2019$PurchasePrice
total_cogs <- sum(BAToysTAXSalesJan2019$COGS, na.rm = TRUE)

BAToysTAXSalesJan2019 %>%
  group_by(Store) %>%
  summarise(TotalCOGS = sum(COGS, na.rm = TRUE)) %>%
  mutate(COGSPercentage = (TotalCOGS / total_cogs) * 100)

#6 To find the month and day that generated the most revenue, including the day of the week:

BAToysTAXSalesJan2019$SalesDate <- as.Date(BAToysTAXSalesJan2019$SalesDate)
BAToysTAXSalesJan2019$DayOfWeek <- weekdays(BAToysTAXSalesJan2019$SalesDate)

BAToysTAXSalesJan2019 %>%
  group_by(SalesDate, DayOfWeek) %>%
  summarise(TotalRevenue = sum(SalesDollars, na.rm = TRUE)) %>%
  arrange(desc(TotalRevenue)) %>%
  slice(1)


#7 Top 5 Products by Revenue and Gross Profit:Assuming that gross profit is SalesDollars minus COGS:

BAToysTAXSalesJan2019$GrossProfit <- BAToysTAXSalesJan2019$SalesDollars - (BAToysTAXSalesJan2019$SalesQuantity * BAToysTAXSalesJan2019$PurchasePrice)

BAToysTAXSalesJan2019 %>%
  group_by(Description, Brand, Store) %>%
  summarise(
    TotalRevenue = sum(SalesDollars, na.rm = TRUE),
    TotalGrossProfit = sum(GrossProfit, na.rm = TRUE)
  ) %>%
  arrange(desc(TotalRevenue), desc(TotalGrossProfit)) %>%
  slice_head(n = 5)


#8 To find the store with the smallest contribution to gross profit and revenue:

BAToysTAXSalesJan2019  %>%
  group_by(Store) %>%
  summarise(
    TotalRevenue = sum(SalesDollars, na.rm = TRUE),
    TotalGrossProfit = sum(GrossProfit, na.rm = TRUE)
  ) %>%
  arrange(TotalRevenue, TotalGrossProfit) %>%
  slice(1)

#9 To determine the most and least expensive products offered for sale:

PriceListing2019 %>%
  summarise(
    MostExpensive = max(SalesPrice, na.rm = TRUE),
    LeastExpensive = min(SalesPrice, na.rm = TRUE)
  )

#10 To find out which vendor the company bought the most from based on total dollar amount and total product quantity:

BAToysPurchasesJan2019 %>%
  group_by(VendorName) %>%
  summarise(
    TotalDollarAmount = sum(PurchasePrice * PurchaseQuantity, na.rm = TRUE),
    TotalQuantity = sum(PurchaseQuantity, na.rm = TRUE)
  ) %>%
  arrange(desc(TotalDollarAmount), desc(TotalQuantity))


#11Assuming that you have a list of products (with unique identifiers) for both years and their sales data, to determine which products were not sold in both years:

# Let's assume you have a dataframe called products_2017 and products_2019 that lists all products offered in each year.
# And a dataframe called sales_2017 and sales_2019 that contains the sales data for each year.

unsold_2017 <- setdiff(PriceListing2017$ProductId, BAToysTAXSalesJan2017$ProductID)
unsold_2019 <- setdiff(PriceListing2019$ProductId, BAToysTAXSalesJan2019$ProductId)

unsold_both_years <- intersect(unsold_2017, unsold_2019)





