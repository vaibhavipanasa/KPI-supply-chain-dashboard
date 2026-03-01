# %% [markdown]
# # 📦 Supply Chain KPI Dashboard — Exploratory Data Analysis
# **Author:** Vaibhavi Panasa
#
# This notebook performs comprehensive EDA on the DataCo Smart Supply Chain dataset
# to uncover delivery patterns, revenue trends, and operational bottlenecks.

# %% [markdown]
# ## 1. Setup & Data Loading

# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings

warnings.filterwarnings('ignore')
sns.set_theme(style="whitegrid", palette="muted")
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 12

print("Libraries loaded successfully ✅")

# %%
# Load dataset
df = pd.read_csv('data/raw_supply_chain_data.csv', encoding='latin-1')
print(f"Dataset Shape: {df.shape[0]:,} rows × {df.shape[1]} columns")
df.head()

# %% [markdown]
# ## 2. Data Overview & Quality Check

# %%
# Basic info
print("=" * 60)
print("DATASET OVERVIEW")
print("=" * 60)
print(f"Total Records:    {df.shape[0]:,}")
print(f"Total Features:   {df.shape[1]}")
print(f"Memory Usage:     {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
print(f"Duplicate Rows:   {df.duplicated().sum()}")
print()

# Data types
print("Column Data Types:")
print(df.dtypes.value_counts())

# %%
# Missing values analysis
missing = df.isnull().sum()
missing_pct = (missing / len(df) * 100).round(2)
missing_df = pd.DataFrame({
    'Missing Count': missing,
    'Missing %': missing_pct
}).query('`Missing Count` > 0').sort_values('Missing %', ascending=False)

if len(missing_df) > 0:
    print("Columns with Missing Values:")
    print(missing_df.to_string())
else:
    print("No missing values found ✅")

# %%
# Key columns for analysis
key_cols = [
    'order date (DateOrders)', 'shipping date (DateOrders)',
    'Days for shipping (real)', 'Days for shipment (scheduled)',
    'Delivery Status', 'Late_delivery_risk',
    'Category Name', 'Sales', 'Order Profit Per Order',
    'Order Region', 'Market', 'Order Country',
    'Shipping Mode', 'Customer Segment', 'Order Priority',
    'Order Item Quantity', 'Order Item Discount Rate'
]

# Rename columns for easier use
df_clean = df[key_cols].copy()
df_clean.columns = [
    'order_date', 'ship_date',
    'actual_ship_days', 'scheduled_ship_days',
    'delivery_status', 'late_delivery_risk',
    'category', 'sales', 'profit',
    'region', 'market', 'country',
    'shipping_mode', 'customer_segment', 'order_priority',
    'quantity', 'discount_rate'
]

# Convert dates
df_clean['order_date'] = pd.to_datetime(df_clean['order_date'])
df_clean['ship_date'] = pd.to_datetime(df_clean['ship_date'])

# Calculated columns
df_clean['delivery_delay'] = df_clean['actual_ship_days'] - df_clean['scheduled_ship_days']
df_clean['is_late'] = df_clean['delivery_status'] == 'Late delivery'
df_clean['profit_margin'] = np.where(df_clean['sales'] > 0, (df_clean['profit'] / df_clean['sales']) * 100, 0)
df_clean['order_month'] = df_clean['order_date'].dt.to_period('M')
df_clean['order_year'] = df_clean['order_date'].dt.year
df_clean['order_quarter'] = df_clean['order_date'].dt.quarter

print(f"Cleaned dataset: {df_clean.shape[0]:,} rows × {df_clean.shape[1]} columns ✅")
df_clean.head()

# %% [markdown]
# ## 3. Delivery Performance Analysis

# %%
# Overall Delivery Status Distribution
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Pie chart
delivery_counts = df_clean['delivery_status'].value_counts()
colors = ['#e74c3c', '#2ecc71', '#3498db', '#95a5a6']
axes[0].pie(delivery_counts, labels=delivery_counts.index, autopct='%1.1f%%',
            colors=colors, startangle=90, textprops={'fontsize': 10})
axes[0].set_title('Delivery Status Distribution', fontsize=14, fontweight='bold')

# Bar chart by shipping mode
late_by_mode = df_clean.groupby('shipping_mode')['is_late'].mean().sort_values() * 100
late_by_mode.plot(kind='barh', ax=axes[1], color='#e74c3c', edgecolor='black')
axes[1].set_xlabel('Late Delivery Rate (%)')
axes[1].set_title('Late Delivery Rate by Shipping Mode', fontsize=14, fontweight='bold')
for i, v in enumerate(late_by_mode):
    axes[1].text(v + 0.5, i, f'{v:.1f}%', va='center', fontweight='bold')

plt.tight_layout()
plt.savefig('images/delivery_performance.png', dpi=150, bbox_inches='tight')
plt.show()

print(f"\n📊 Overall Late Delivery Rate: {df_clean['is_late'].mean()*100:.1f}%")

# %%
# Late Delivery Rate by Region
fig, ax = plt.subplots(figsize=(12, 6))
late_by_region = df_clean.groupby('region').agg(
    total_orders=('is_late', 'count'),
    late_rate=('is_late', 'mean'),
    avg_delay=('delivery_delay', 'mean')
).sort_values('late_rate', ascending=False)

late_by_region['late_rate_pct'] = late_by_region['late_rate'] * 100

bars = ax.bar(late_by_region.index, late_by_region['late_rate_pct'],
              color=sns.color_palette("YlOrRd", len(late_by_region)), edgecolor='black')
ax.axhline(y=5, color='green', linestyle='--', linewidth=2, label='Target: 5%')
ax.set_ylabel('Late Delivery Rate (%)')
ax.set_title('Late Delivery Rate by Region', fontsize=14, fontweight='bold')
ax.legend()
plt.xticks(rotation=45, ha='right')

for bar, val in zip(bars, late_by_region['late_rate_pct']):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
            f'{val:.1f}%', ha='center', fontweight='bold', fontsize=9)

plt.tight_layout()
plt.savefig('images/late_delivery_by_region.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 4. Revenue & Profit Analysis

# %%
# Revenue by Category
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

category_metrics = df_clean.groupby('category').agg(
    revenue=('sales', 'sum'),
    profit=('profit', 'sum'),
    orders=('sales', 'count'),
    avg_margin=('profit_margin', 'mean')
).sort_values('revenue', ascending=True)

# Revenue bar chart
category_metrics['revenue'].plot(kind='barh', ax=axes[0], color='#2980b9', edgecolor='black')
axes[0].set_xlabel('Total Revenue ($)')
axes[0].set_title('Revenue by Product Category', fontsize=14, fontweight='bold')
axes[0].xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x/1e6:.1f}M'))

# Profit margin
category_metrics['avg_margin'].plot(kind='barh', ax=axes[1], color='#27ae60', edgecolor='black')
axes[1].set_xlabel('Average Profit Margin (%)')
axes[1].set_title('Profit Margin by Category', fontsize=14, fontweight='bold')

plt.tight_layout()
plt.savefig('images/revenue_by_category.png', dpi=150, bbox_inches='tight')
plt.show()

# %%
# Monthly Revenue Trend
monthly_trend = df_clean.groupby('order_month').agg(
    revenue=('sales', 'sum'),
    orders=('sales', 'count'),
    late_rate=('is_late', 'mean')
).reset_index()
monthly_trend['order_month'] = monthly_trend['order_month'].dt.to_timestamp()

fig, ax1 = plt.subplots(figsize=(14, 6))

ax1.fill_between(monthly_trend['order_month'], monthly_trend['revenue'],
                 alpha=0.3, color='#3498db')
ax1.plot(monthly_trend['order_month'], monthly_trend['revenue'],
         color='#2980b9', linewidth=2, marker='o', markersize=4)
ax1.set_xlabel('Month')
ax1.set_ylabel('Revenue ($)', color='#2980b9')
ax1.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x/1e6:.1f}M'))

ax2 = ax1.twinx()
ax2.plot(monthly_trend['order_month'], monthly_trend['late_rate'] * 100,
         color='#e74c3c', linewidth=2, linestyle='--', marker='s', markersize=4)
ax2.set_ylabel('Late Delivery Rate (%)', color='#e74c3c')

ax1.set_title('Monthly Revenue Trend & Late Delivery Rate', fontsize=14, fontweight='bold')
fig.legend(['Revenue', 'Late Rate'], loc='upper left', bbox_to_anchor=(0.12, 0.95))
plt.tight_layout()
plt.savefig('images/monthly_trend.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 5. Shipping Cost Analysis

# %%
# Shipping cost distribution by mode
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Box plot
sns.boxplot(data=df_clean, x='shipping_mode', y='sales',
            palette='Set2', ax=axes[0], showfliers=False)
axes[0].set_title('Sales Distribution by Shipping Mode', fontsize=13, fontweight='bold')
axes[0].set_ylabel('Sales ($)')
axes[0].tick_params(axis='x', rotation=20)

# Avg shipping cost per unit by region
avg_cost = df_clean.groupby('region').apply(
    lambda x: x['sales'].sum() / x['quantity'].sum()
).sort_values(ascending=False)

avg_cost.plot(kind='bar', ax=axes[1], color='#8e44ad', edgecolor='black')
axes[1].set_title('Avg Revenue per Unit by Region', fontsize=13, fontweight='bold')
axes[1].set_ylabel('Revenue per Unit ($)')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('images/shipping_cost_analysis.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 6. Customer Segment Analysis

# %%
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Revenue by segment
seg_revenue = df_clean.groupby('customer_segment')['sales'].sum().sort_values()
seg_revenue.plot(kind='barh', ax=axes[0], color=['#1abc9c', '#e67e22', '#9b59b6'], edgecolor='black')
axes[0].set_xlabel('Total Revenue ($)')
axes[0].set_title('Revenue by Customer Segment', fontsize=13, fontweight='bold')
axes[0].xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x/1e6:.1f}M'))

# Late delivery by segment
seg_late = df_clean.groupby('customer_segment')['is_late'].mean().sort_values() * 100
seg_late.plot(kind='barh', ax=axes[1], color=['#1abc9c', '#e67e22', '#9b59b6'], edgecolor='black')
axes[1].set_xlabel('Late Delivery Rate (%)')
axes[1].set_title('Late Delivery Rate by Segment', fontsize=13, fontweight='bold')

plt.tight_layout()
plt.savefig('images/customer_segment.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 7. Correlation Heatmap

# %%
numeric_cols = ['sales', 'profit', 'quantity', 'discount_rate',
                'actual_ship_days', 'scheduled_ship_days',
                'delivery_delay', 'profit_margin']

corr_matrix = df_clean[numeric_cols].corr()

fig, ax = plt.subplots(figsize=(10, 8))
mask = np.triu(np.ones_like(corr_matrix, dtype=bool))
sns.heatmap(corr_matrix, mask=mask, annot=True, fmt='.2f', cmap='coolwarm',
            center=0, linewidths=1, ax=ax, vmin=-1, vmax=1)
ax.set_title('Correlation Heatmap — Key Metrics', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('images/correlation_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 8. Seasonal Analysis

# %%
fig, ax = plt.subplots(figsize=(12, 5))

seasonal = df_clean.groupby([df_clean['order_date'].dt.month]).agg(
    avg_orders=('sales', 'count'),
    avg_late_rate=('is_late', 'mean')
)
seasonal.index.name = 'Month'

month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

bars = ax.bar(range(1, 13), seasonal['avg_orders'], color='#3498db',
              edgecolor='black', alpha=0.7, label='Order Volume')
ax.set_xticks(range(1, 13))
ax.set_xticklabels(month_names)
ax.set_ylabel('Order Count', color='#3498db')

ax2 = ax.twinx()
ax2.plot(range(1, 13), seasonal['avg_late_rate'] * 100, color='#e74c3c',
         marker='D', linewidth=2.5, label='Late Rate %')
ax2.set_ylabel('Late Delivery Rate (%)', color='#e74c3c')

ax.set_title('Seasonal Order Volume & Late Delivery Rate', fontsize=14, fontweight='bold')
fig.legend(loc='upper left', bbox_to_anchor=(0.12, 0.95))
plt.tight_layout()
plt.savefig('images/seasonal_analysis.png', dpi=150, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## 9. Summary Statistics & Export

# %%
print("=" * 60)
print("📊 EXECUTIVE SUMMARY")
print("=" * 60)
print(f"Total Orders:              {len(df_clean):,}")
print(f"Total Revenue:             ${df_clean['sales'].sum():,.2f}")
print(f"Total Profit:              ${df_clean['profit'].sum():,.2f}")
print(f"Avg Profit Margin:         {df_clean['profit_margin'].mean():.1f}%")
print(f"Late Delivery Rate:        {df_clean['is_late'].mean()*100:.1f}%")
print(f"Avg Delivery Delay:        {df_clean['delivery_delay'].mean():.1f} days")
print(f"Unique Customers:          {df_clean.shape[0]:,}")  # Approximate
print(f"Markets Covered:           {df_clean['market'].nunique()}")
print(f"Regions Covered:           {df_clean['region'].nunique()}")
print(f"Date Range:                {df_clean['order_date'].min().date()} to {df_clean['order_date'].max().date()}")
print("=" * 60)

# %%
# Export cleaned data
df_clean.to_csv('data/cleaned_supply_chain_data.csv', index=False)
print("✅ Cleaned dataset exported to data/cleaned_supply_chain_data.csv")
