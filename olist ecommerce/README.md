## 1. Project Scope

### 1.1 Objective

Design and deliver an end-to-end interactive business intelligence solution built on the Olist Brazilian E-Commerce public dataset.

The dashboard translates 100,000+ real-world marketplace orders into actionable insights for three distinct audiences within a single Power BI report.

The project demonstrates proficiency across the full BI development lifecycle, including data modelling, DAX measure authoring, UX-driven report design, and interactive storytelling through bookmark-driven navigation and dynamic visuals.

### 1.2 Key Business Questions

- Revenue & Growth
    - How much revenue did the business generate in the selected period, and is it growing month-over-month?
    - Which product categories are the top and bottom revenue drivers?
    - Which cities generate the most and least sales, and where is growth concentrated?
- Orders & Customer Behavior
    - How are order volumes and unique customer counts trending over time?
    - Which payment methods do customers prefer, and how is that split evolving?
    - Can we correlate spikes in orders with specific days, months, or quarters?
- Fulfilment & Delivery Quality
    - What share of orders are successfully delivered, and how does that rate trend?
    - What percentage of deliveries arrive on or before the promised date?
    - Where are late deliveries concentrated geographically, and which order statuses are stuck?
    - How many extra days, on average, are late orders taking beyond the estimated delivery date?

### 1.3 Report Pages (Audience & Key Visuals)

| **Page** | **Audience** | **Key visuals** |
| --- | --- | --- |
| **Executives** | C-suite, senior management | 3 KPI cards with MoM% + sparklines, Top/Bottom 5 products, Top/Bottom 5 cities, global slicers |
| **Sales Analysis** | Sales managers, analysts, marketing | Trend line chart (orders & customers), payment type donut, KPI cards, table view, time-granularity toggles |
| **Customer Service** | Operations, logistics, support teams | 4 delivery KPI cards, order status funnel, undelivered orders chart, top late-delivery cities, table view |

### 1.4 Shared UX Elements

- **Global slicers:** Year Month, State, Product Category Name
- **Reset control:** Reset All Slicers button to restore the full unfiltered dataset in one click
- **Navigation:** Consistent page navigation bar across all report pages
- **Documentation:** Information overlay panel (ⓘ button) describing each visual and filter

## 2. Data Sources

The project is powered entirely by the Olist Brazilian E-Commerce Public Dataset, originally published on Kaggle.

Olist is a Brazilian marketplace platform that connects small merchants to major online retailers.

The dataset spans orders placed between 2016 and 2018 across the full Brazilian territory.

### 2.1 Dataset Summary

| **Dataset** | Olist Brazilian E-Commerce Public Dataset (Kaggle) |
| --- | --- |
| **Order volume** | ~100,000 orders across the full dataset period |
| **Time range** | 2016 – 2018 |
| **Geography** | Brazil — multiple states and cities |
| **Grain** | One row per order item; orders may contain multiple items |
| **License** | Public domain / open data — permitted for portfolio and educational use |

### 2.2 Core Entities (Model Components)

| **Orders** | Order ID, purchase timestamp, approval timestamp, order status, estimated and actual delivery dates |
| --- | --- |
| **Customers** | Unique customer ID, city, state |
| **Products** | Product ID, category (translated to English) |
| **Payments** | Payment type (credit card, boleto, voucher, debit card), payment value |
| **Order Items** | Links orders to products; carries price and freight value |
| **Reviews** | Review score (1–5) per order, surfaced in the Customer Service table view |
| **Date table** | Standard calendar table enabling time-intelligence measures (MoM, trend lines) |

---

### 2.3 Data Pipeline
<img width="1433" height="458" alt="image" src="https://github.com/user-attachments/assets/06e06abf-2aee-4cb6-830e-af79ff935d39" />
