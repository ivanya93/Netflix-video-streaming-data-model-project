# Netflix-Like Video Streaming Data Model Project

## Project Overview

A comprehensive **dimensional data warehouse design** for a Netflix-like video streaming platform. This project demonstrates enterprise-grade data modeling using **Kimball's 4-Stage Dimensional Design methodology** with a dual fact table architecture to support both engagement analytics and financial reporting.

---

## 📋 Table of Contents
- [Project Details](#project-details)
- [Business Context](#business-context)
- [Data Architecture](#data-architecture)
- [Key Features](#key-features)
- [Dimensional Model](#dimensional-model)
- [KPIs & Analytics](#kpis--analytics)
- [Files & Documentation](#files--documentation)
- [Technologies](#technologies)
- [Team](#team)
- [References](#references)

---

## Project Details

**Course:** Business Intelligence  
**Institution:** Porto Business School  
**Year:** 2026  
**Contact:** [Ivanaloveraruiz@gmail.com](mailto:Ivanaloveraruiz@gmail.com)

---

## Business Context

Netflix-like streaming companies face a fundamental challenge: they need to answer two completely different questions simultaneously:

### Engagement Questions (Product Team)
- Which episodes are most watched?
- Do viewers complete Season 1 more than later seasons?
- What quality issues cause buffering?
- Who drops off and when?

### Financial Questions (Finance Team)
- How much profit did each subscription generate?
- Which subscription tier is most profitable?
- What's our cost to serve each user?
- Which content has the best ROI?

**The Solution:** A dual fact table architecture that serves both use cases optimally.

---

## Data Architecture

### Two Fact Tables at Different Granularities

#### FactWatchEvent (Session Grain)
- **Grain:** One row per watch session
- **Cardinality:** 1 billion+ rows/year
- **Purpose:** Engagement detail analysis, episode performance, quality tracking
- **Dimensions:** Date, Time, User, Device, Content (Show/Episode/Movie)
- **Facts:** MinutesWatched, IsCompleted, IsContinued, UserRating, QualityLevel, BufferingEventCount

#### FactSubscriptionMonth (Month Grain)
- **Grain:** One row per user per month
- **Cardinality:** 500M - 1B rows/year
- **Purpose:** Financial reporting, KPIs, profitability analysis
- **Dimensions:** Date, User, SubscriptionType, Device, Content
- **Facts:** 
  - Revenue: SubscriptionRevenue, AdRevenue, TotalRevenue
  - Costs: ContentDeliveryCost, ContentLicensingCost, ContentProductionCost, OperationalCost
  - Profitability: GrossProfit, GrossProfitMargin
  - Aggregated Engagement: MinutesWatched, SessionCount, IsActive, Completion Rates

**ETL Relationship:** FactWatchEvent (detailed) → Aggregates to → FactSubscriptionMonth (summarized)

---

## Key Features

✅ **Hierarchical Content Dimensions**
- DimShow → DimSeason → DimEpisode (normalized TV content hierarchy) -- We decided to use DimContent and not normalized these ones
- DimMovie (flat, separate for movies)
- Self-referencing ParentContentKey to handle hierarchy in flat denormalized DimContent option

✅ **Type 2 Slowly Changing Dimensions (SCD)**
- DimUser: Track subscription tier changes, demographic updates
- DimShow/Season/Episode: Track metadata changes (DimContent)
- DimMovie: Track when movies added to platform
- DimDevice: Track device capability evolution
- Complete history: StartDate, EndDate, IsCurrent columns

✅ **Conformed Dimensions**
- DimDate, DimUser, DimDevice, DimSubscriptionType shared across both fact tables
- Enables drill-across analysis
- Consistent definitions enterprise-wide

✅ **Session Management**
- DimSession handles operational SessionID recycling
- Composite natural key: (SessionID + SessionStartDate + SessionStartTime)
- Prevents data integrity issues from ID reuse

✅ **Complete Financial Modeling**
- Cost allocation strategies (delivery, licensing, production, operations)
- Margin calculations at subscriber level
- Profitability analysis by subscription type, content, device

---

## Dimensional Model

### Dimension Tables (9 Total)

| Table | Columns | Purpose |
|-------|---------|---------|
| **DimDate** | 15 | Temporal context (seasonality, trends, day-of-week effects) |
| **DimTime** | 5 | Time-of-day patterns (peak watching hours) |
| **DimUser** | 17 | User segmentation, behavior (Type 2 SCD) |
| **DimSubscriptionType** | 14 | Pricing tiers, features, profitability |
| **DimMovie** | 22 | Movie metadata, licensing info (Type 2 SCD) |
| **DimDevice** | 14 | Device tracking, delivery costs (Type 2 SCD) |
| **DimSession** | 8 | Session ID mapping, handles operational ID recycling |
| **DimContent** | 21 | Denormalized flat option for shows/seasons/episodes |

### Star Schema

```
                    DimDate
                      ↑
                      │
        DimTime      DimUser ────────────┐
          ↑             ↑                 │
          │             │                 │
    FactWatchEvent    FactSubscriptionMonth
    (Session Grain)   (Month Grain)
          ↑                 ↑             │
          │                 │             │
    DimContent ────┼─────────┼─────────────┤
                   │         │             │
    DimMovie ───-──┴─────────┼─────────────┤
                  │         │             │
              DimSession    │             │
                  │         │             │
                  └─────────┼─────────────┘
                            │
                  DimSubscriptionType
                            │
                        DimDevice
```

---

## KPIs & Analytics

### Total Active Subscribers
**Definition:** Count of unique users with active subscription in a given month

```sql
SELECT 
    DateKey,
    COUNT(DISTINCT UserKey) as ActiveSubscribers
FROM FactSubscriptionMonth
WHERE IsActiveThisMonth = 1
GROUP BY DateKey
```

**Business Value:**
- Most visible metric (reported in earnings calls)
- Indicates market reach and valuation multiple
- Direct correlation to revenue

### Gross Profit Margin by Subscription Type
**Definition:** Total profit divided by total revenue, grouped by tier

```sql
SELECT 
    st.SubscriptionTypeName,
    SUM(fsm.SubscriptionRevenue) as TotalRevenue,
    SUM(fsm.TotalCost) as TotalCost,
    SUM(fsm.GrossProfit) as TotalProfit,
    AVG(fsm.GrossProfitMargin) as AvgMargin
FROM FactSubscriptionMonth fsm
JOIN DimSubscriptionType st ON fsm.SubscriptionTypeKey = st.SubscriptionTypeKey
WHERE fsm.IsActiveThisMonth = 1
GROUP BY st.SubscriptionTypeName
```

### Episode Completion Rate
**Definition:** Percentage of sessions where user watched entire episode

```sql
SELECT 
    e.EpisodeName,
    COUNT(*) as TotalSessions,
    SUM(CASE WHEN IsCompleted = 1 THEN 1 ELSE 0 END) as CompletedSessions,
    (SUM(CASE WHEN IsCompleted = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) 
        as CompletionRate_Pct
FROM FactWatchEvent we
JOIN DimEpisode e ON we.EpisodeKey = e.EpisodeKey
WHERE we.ContentType = 1
GROUP BY e.EpisodeName
ORDER BY CompletionRate_Pct DESC
```

---

## Files & Documentation

### Core Documentation
- **Netflix_Model_4Stage_Dimensional_Design.md** - Complete 4-stage dimensional design walkthrough
- **Data_Warehouse_Schema.csv** - Full table schema reference with all columns
- **Integration_Hierarchical_Dimensions.md** - How to integrate normalized Show/Season/Episode hierarchy
- **Two_Fact_Tables_Integration.md** - Complete guide on dual fact table architecture
- **Facts_Source_Storage_ETL.md** - Where facts come from and how they're calculated

### Synthetic Data
- **DimMovie_Full_SyntheticData.csv** - 10 movies (Avengers, The Irishman, etc.)
- **DimContent_Flat_Denormalized.csv** - 10 rows denormalized content hierarchy
- **DimSubscriptionType_SyntheticData.csv** - 10 subscription tier variations
- **DimDevice_SyntheticData.csv** - 10 device types (SmartTV, Mobile, Tablet, Desktop)
- **DimSession_SyntheticData.csv** - 10 sessions showing ID recycling handling

### Analytics
- **KPI_Total_Active_Subscribers_Graph.py** - Matplotlib visualization of subscriber growth KPI
- **KPI_Total_Active_Subscribers.png** - Generated graph showing 24-month trend

---

## Design Principles

### 1. Grain is Everything
- FactWatchEvent: One row per session (atomic, most detailed)
- FactSubscriptionMonth: One row per user per month (aggregated)
- All dimensions align to grain

### 2. Conformed Dimensions
- DimDate, DimUser, DimDevice used by BOTH fact tables
- Enables drill-across analysis
- Consistent definitions across enterprise

### 3. Surrogate Keys
- Disconnect from source systems
- Enable Type 2 SCD tracking
- Small integer keys for performance

### 4. Type 2 Slowly Changing Dimensions
- Track when dimensions change
- Preserve historical accuracy
- StartDate/EndDate/IsCurrent columns

### 5. Hierarchical Content Dimensions
- Show → Season → Episode hierarchy (TV series) -- DimContent (Denormalized)
- Movie as separate dimension (movies are flat)
- Foreign keys properly reference hierarchy

### 6. Additive Facts
- MinutesWatched, GrossProfit: Always additive (can sum)
- UserRating: Semi-additive (average, not sum)
- QualityLevel: Non-additive (categorical)

### 7. Separation of Concerns
- Engagement analysis: Use FactWatchEvent
- Financial reporting: Use FactSubscriptionMonth
- Join both for correlation analysis
- No mixing concerns in queries

---

## Technologies

- **Database Design:** Kimball Dimensional Modeling
- **Data Modeling:** Star Schema with Type 2 SCD
- **Data Types:** MySQL/SQL compatible
- **Visualization:** Python matplotlib
- **Documentation:** Markdown, CSV

---

## Implementation Approach

### 4-Stage Dimensional Design Process

**Stage 1: Identify the Business Event**
- Primary: User Watch Session
- Secondary: Subscription Month

**Stage 2: Identify & Define Granularity**
- FactWatchEvent: One row per session
- FactSubscriptionMonth: One row per user per month

**Stage 3: Identify Dimensions**
- 10 dimension tables providing complete business context
- Hierarchical content dimensions
- Type 2 SCD for historical tracking

**Stage 4: Identify Facts**
- FactWatchEvent: 7 engagement measures
- FactSubscriptionMonth: 27 measures (engagement + financial)

---

## Key Assumptions

1. **Monthly Billing Cycle** - Subscriptions renew monthly
2. **Content Hierarchy** - TV shows have seasons/episodes; movies are flat
3. **Costs Allocatable** - Can allocate CDN, production, operations costs per user
4. **Type 2 SCD** - Want to track dimension changes historically
5. **Surrogate Keys** - Isolate from source system ID changes
6. **Watch Session Grain** - Most appropriate atomic unit for engagement
7. **Profit Calculation** - GrossProfit = Revenue - AllCosts

---

## Data Warehouse Benefits

✅ **Complete Business Context**
- User (who), Time (when), Device (how)
- Content hierarchy (what)
- Subscription tier (pricing)
- Session tracking (operational ID management)

✅ **Dual Grain Architecture**
- Session-level engagement detail (FactWatchEvent)
- Monthly financial summaries (FactSubscriptionMonth)
- ETL aggregation between them

✅ **Historical Tracking**
- Type 2 SCD on all key dimensions
- Understand how business has changed
- Track user behavior changes over time

✅ **Enterprise-Ready**
- Conformed dimensions enable cross-functional analysis
- Surrogate keys isolate from source systems
- Scalable to billions of rows per year

✅ **Analytics**
- Clear grain definitions
- Additive facts for easy aggregation
- Hierarchical dimensions for drill-down
- Ready for all major BI tools (Power BI, Tableau, Looker)

---

## Next Steps

1. **Database Implementation** - Create MySQL DDL statements
2. **Sample Data Loading** - Populate with realistic data volumes
3. **ETL Development** - Build aggregation pipelines
4. **Query Optimization** - Index strategy and performance tuning
5. **BI Tool Integration** - Connect to Power BI/Tableau
6. **Reporting** - Create executive dashboards

---

## Learning Outcomes

✓ Understands Kimball dimensional modeling fundamentals  
✓ Can design star schema following 4-stage process  
✓ Knows how to handle dimensional hierarchies  
✓ Can derive actionable KPIs from data model  
✓ Understands realistic business economics (thin margins, unit economics)  
✓ Knows when/how to use multiple fact tables  
✓ Can handle operational ID recycling in dimensional models  
✓ Understands Type 2 SCD implementation

---

## Citations & References

**Foundational Work:**
- Kimball Group. (n.d.). *Dimension table core concepts*. Retrieved from https://www.kimballgroup.com/category/dimension-table-core-concepts/

**Data Sources:**
- Lucifierx. (2024). *Netflix* [Data set; Code]. Kaggle. https://www.kaggle.com/code/lucifierx/netflix
- Netflix Media. (2024). *Netflix media center images*. Retrieved from https://media.netflix.com/en/

**AI Assistance:**
- Anthropic. (2024). Claude (Version 3.5 Sonnet) [Large language model]. Retrieved from https://claude.ai

---

## Team

| Name | Role |
|------|------|
| Emmanuel Momoh | Team Member |
| Ivana Ruiz | Team Member & GitHub Manager |
| Hugo Lima | Team Member |
| Rita Sousa | Team Member |
| Nikita Teterin | Team Member |

**Contact:** [Ivanaloveraruiz@gmail.com](mailto:Ivanaloveraruiz@gmail.com)

---

## License

This project is created for educational purposes as part of the Business Intelligence course at Porto Business School (2026).

---

## Disclaimer

This is a **fictional streaming platform data model** designed for learning purposes. While it follows industry best practices and real Netflix-like economics, it is not based on Netflix's actual data warehouse architecture.

---

**Last Updated:** March 2026  
**Status:** Complete - Ready for Presentation

---

## Quick Start

1. Review the **Netflix_Model_4Stage_Dimensional_Design.md** for complete overview
2. Check **Data_Warehouse_Schema.csv** for table definitions
3. Explore **DimMovie_Full_SyntheticData.csv**, **DimDevice_SyntheticData.csv**, etc. for sample data
4. Run **KPI_Total_Active_Subscribers_Graph.py** to see KPI visualization
5. Study **Two_Fact_Tables_Integration.md** to understand the dual fact table approach
6. Review the SQL query examples in documentation for implementation patterns

---

*A comprehensive data warehouse design demonstrating enterprise-grade dimensional modeling for streaming analytics and financial reporting.*
