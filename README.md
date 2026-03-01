# 📦 Supply Chain KPI Dashboard

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)

## 📌 Project Overview

An end-to-end **supply chain analytics project** that transforms raw logistics and shipment data into actionable KPI dashboards. This project simulates a real-world scenario where a logistics company needs to monitor delivery performance, optimize shipping costs, and identify bottleneck areas across its supply chain network.

**Business Problem:** The operations team lacks visibility into key supply chain metrics — leading to delayed shipments, cost overruns, and poor vendor performance tracking. This dashboard provides a centralized view of all critical KPIs to enable data-driven decision-making.

---

## 🎯 Key Business Questions Answered

1. What is the **on-time delivery rate** across regions and shipping modes?
2. Which **product categories** generate the highest revenue vs. highest shipping costs?
3. Are there **seasonal trends** in order volumes and delivery delays?
4. Which **vendors/suppliers** consistently underperform on delivery timelines?
5. What is the **average shipping cost per unit** by region and category?
6. How does **order priority** impact late delivery risk?
7. What are the **top 10 customers** by lifetime value and order frequency?
8. Where are the **geographic bottlenecks** causing shipment delays?

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **SQL (PostgreSQL)** | Data extraction, transformation, aggregation |
| **Python (Pandas, Matplotlib, Seaborn)** | Exploratory Data Analysis (EDA), statistical analysis |
| **Power BI** | Interactive KPI dashboard with drill-down capabilities |
| **Excel** | Initial data profiling and quick pivot analysis |
| **Git/GitHub** | Version control and project documentation |

---

## 📂 Project Structure

```
Supply-Chain-KPI-Dashboard/
│
├── README.md                          # Project documentation
├── data/
│   ├── raw_supply_chain_data.csv      # Original dataset
│   └── cleaned_supply_chain_data.csv  # Processed dataset
│
├── sql/
│   ├── 01_create_tables.sql           # Schema creation
│   ├── 02_data_cleaning.sql           # Data cleaning queries
│   ├── 03_kpi_queries.sql             # KPI calculation queries
│   └── 04_advanced_analysis.sql       # Window functions, CTEs, rankings
│
├── notebooks/
│   └── supply_chain_eda.ipynb         # Python EDA notebook
│
├── dashboards/
│   ├── Supply_Chain_Dashboard.pbix    # Power BI file
│   └── dashboard_screenshots/         # Dashboard images
│
└── images/                            # README images & diagrams
```

---

## 📊 Dataset

**Source:** [DataCo Smart Supply Chain Dataset](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis) (Kaggle)

| Feature | Description |
|---------|-------------|
| **Records** | 180,519 transactions |
| **Time Period** | 2015–2018 |
| **Columns** | 53 features |
| **Key Fields** | Order date, ship date, delivery status, shipping mode, customer segment, product category, sales, profit, region, market |

---

## 🔑 Key KPIs Tracked

| KPI | Formula | Target |
|-----|---------|--------|
| **On-Time Delivery Rate** | (On-time Orders / Total Orders) × 100 | ≥ 95% |
| **Late Delivery Rate** | (Late Orders / Total Orders) × 100 | ≤ 5% |
| **Average Shipping Cost** | Total Shipping Cost / Total Orders | Minimize |
| **Order Fulfillment Time** | Ship Date – Order Date (avg days) | ≤ 3 days |
| **Revenue per Region** | SUM(Sales) GROUP BY Region | Track trend |
| **Profit Margin** | (Profit / Sales) × 100 | ≥ 20% |
| **Cost per Unit Shipped** | Shipping Cost / Units Shipped | Minimize |
| **Customer Lifetime Value** | SUM(Sales) per Customer | Maximize |

---

## 🧹 Data Cleaning Steps

1. **Removed duplicates** — 342 duplicate order records identified and removed
2. **Handled missing values** — Filled missing `Order Zipcode` using mode by city; dropped rows with null `Customer ID` (0.02%)
3. **Standardized date formats** — Converted `order date` and `shipping date` to proper DATETIME
4. **Created calculated columns** — `delivery_days`, `is_late`, `shipping_cost_per_unit`, `profit_margin_%`
5. **Filtered outliers** — Removed orders with negative quantities and extreme shipping cost outliers (>3 std dev)

---

## 📈 Key Findings & Insights

### 1. Late Delivery Crisis
> **54.8% of all orders were delivered late** — significantly above the 5% industry target. Same-Day shipping mode had the worst late delivery rate at 59.7%.

### 2. Regional Performance Gap
> **Latin America (LATAM)** accounts for 25% of total orders but has the highest average delivery delay of 2.4 days. **Western Europe** performs best with an average delay of only 0.8 days.

### 3. High-Value Product Category Risk
> **Technology products** generate the highest revenue ($8.2M) but also the highest late delivery rate (57.1%), putting premium customer relationships at risk.

### 4. Shipping Mode Paradox
> **Standard Class** shipping, despite being the slowest, has the best on-time rate at 49.2%. Expedited modes (First Class, Same Day) show worse performance — suggesting capacity or logistics partner issues.

### 5. Seasonal Spikes
> Order volumes peak in **October–December (Q4)**, with November showing 23% more orders than the annual average. Late deliveries spike by 31% during this period.

---

## 💡 Business Recommendations

1. **Renegotiate SLAs with Same-Day/First-Class carriers** — Current performance is unacceptable; switch vendors or add penalty clauses
2. **Increase LATAM warehouse capacity** — Regional fulfillment centers can cut 1.5 days from average delivery time
3. **Implement Q4 surge planning** — Pre-position inventory and secure additional carrier capacity by September
4. **Prioritize Technology category shipments** — High-value, high-risk segment needs dedicated logistics tracking
5. **Deploy real-time delivery tracking dashboard** — Enable operations team to intervene on at-risk shipments proactively

---

## 🖥️ Dashboard Preview

### Overview Page
![Dashboard Overview](dashboards/dashboard_screenshots/overview.png)

### Delivery Performance Page
![Delivery Performance](dashboards/dashboard_screenshots/delivery_performance.png)

### Regional Analysis Page
![Regional Analysis](dashboards/dashboard_screenshots/regional_analysis.png)

---

## 🚀 How to Reproduce

### Prerequisites
- Python 3.8+ with pandas, matplotlib, seaborn
- PostgreSQL (or any SQL database)
- Power BI Desktop (free)

### Steps
```bash
# 1. Clone this repository
git clone https://github.com/YOUR_USERNAME/Supply-Chain-KPI-Dashboard.git
cd Supply-Chain-KPI-Dashboard

# 2. Download dataset from Kaggle and place in /data folder

# 3. Run SQL scripts in order
psql -d your_database -f sql/01_create_tables.sql
psql -d your_database -f sql/02_data_cleaning.sql
psql -d your_database -f sql/03_kpi_queries.sql

# 4. Run Python EDA notebook
jupyter notebook notebooks/supply_chain_eda.ipynb

# 5. Open Power BI dashboard
# Open dashboards/Supply_Chain_Dashboard.pbix in Power BI Desktop
```

---

## 👤 Author

**Vaibhavi Panasa**
- [LinkedIn](https://www.linkedin.com/in/vaibhavipanasa)
- [GitHub](https://github.com/YOUR_USERNAME)
- 📧 vaibhavipanasa@gmail.com

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
