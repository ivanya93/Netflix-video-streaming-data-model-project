-- ================================================================
-- NETFLIX VIDEO STREAMING DATA WAREHOUSE
-- MySQL Database Schema - CORRECTED VERSION
-- Business Intelligence Project - Porto Business School 2026
-- ================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS netflix_dw;
USE netflix_dw;

-- ================================================================
-- DIMENSION TABLES
-- ================================================================

-- DimDate
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY AUTO_INCREMENT,
    CalendarDate DATE NOT NULL UNIQUE,
    DayOfWeek VARCHAR(10) NOT NULL,
    DayOfWeekNumber INT NOT NULL,
    Week VARCHAR(10),
    Month VARCHAR(10) NOT NULL,
    MonthNumber INT NOT NULL,
    Quarter VARCHAR(3) NOT NULL,
    QuarterNumber INT NOT NULL,
    Year INT NOT NULL,
    DayOfMonth INT NOT NULL,
    IsWeekend BIT NOT NULL DEFAULT 0,
    IsHoliday BIT NOT NULL DEFAULT 0,
    HolidayName VARCHAR(50),
    YearMonth VARCHAR(7) NOT NULL,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_calendar_date (CalendarDate),
    INDEX idx_year_month (YearMonth),
    INDEX idx_is_weekend (IsWeekend)
);

-- DimTime
CREATE TABLE DimTime (
    TimeKey INT PRIMARY KEY AUTO_INCREMENT,
    TimeOfDay TIME NOT NULL UNIQUE,
    Hour INT NOT NULL,
    Minute INT NOT NULL,
    HourOfDay INT NOT NULL,
    PeriodOfDay VARCHAR(20) NOT NULL,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_hour_of_day (HourOfDay),
    INDEX idx_period_of_day (PeriodOfDay)
);

-- DimSession
CREATE TABLE DimSession (
    SessionKey INT PRIMARY KEY AUTO_INCREMENT,
    SessionID VARCHAR(50) NOT NULL,
    SessionStartDate DATE NOT NULL,
    SessionStartTime TIME NOT NULL,
    SessionStartDateTime DATETIME NOT NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_session_composite (SessionID, SessionStartDate, SessionStartTime),
    INDEX idx_session_id (SessionID),
    INDEX idx_is_current (IsCurrent)
);

-- DimUser (Type 2 SCD)
CREATE TABLE DimUser (
    UserKey INT PRIMARY KEY AUTO_INCREMENT,
    UserID VARCHAR(50) NOT NULL,
    Username VARCHAR(100) NOT NULL,
    BirthDate DATE,
    Email VARCHAR(100),
    Country VARCHAR(100),
    Region VARCHAR(100),
    City VARCHAR(100),
    AgeGroup VARCHAR(20),
    Gender VARCHAR(10),
    RegistrationDate DATE,
    IsCurrent BIT NOT NULL DEFAULT 1,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (UserID),
    INDEX idx_is_current (IsCurrent),
    INDEX idx_country (Country)
);

-- DimSubscriptionType
CREATE TABLE DimSubscriptionType (
    SubscriptionTypeKey INT PRIMARY KEY AUTO_INCREMENT,
    SubscriptionID VARCHAR(50) NOT NULL UNIQUE,
    SubscriptionTypeName VARCHAR(100) NOT NULL,
    MonthlyPrice DECIMAL(10, 2) NOT NULL,
    AnnualPrice DECIMAL(10, 2),
    MaxScreens INT,
    QualitySupported VARCHAR(20),
    AdSupportedFlag BIT NOT NULL DEFAULT 0,
    SimultaneousStreams INT,
    DownloadAllowed BIT NOT NULL DEFAULT 0,
    ProfilesAllowed INT,
    TargetSegment VARCHAR(100),
    IsActive BIT NOT NULL DEFAULT 1,
    LaunchDate DATE,
    IsPaidUser BIT NOT NULL DEFAULT 0,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_subscription_name (SubscriptionTypeName),
    INDEX idx_is_active (IsActive),
    INDEX idx_is_paid_user (IsPaidUser)
);

-- DimDevice (Type 2 SCD) - THIS WAS MISSING!
CREATE TABLE DimDevice (
    DeviceKey INT PRIMARY KEY AUTO_INCREMENT,
    DeviceID VARCHAR(50) NOT NULL,
    DeviceType VARCHAR(50) NOT NULL,
    DeviceBrand VARCHAR(100),
    DeviceModel VARCHAR(100),
    OperatingSystem VARCHAR(50),
    OSVersion VARCHAR(20),
    BrowserType VARCHAR(50),
    IsSmartDevice BIT NOT NULL DEFAULT 0,
    EstimatedDeliveryCostPerStream DECIMAL(10, 4),
    IsUltra4K BIT NOT NULL DEFAULT 0,
    IsCurrent BIT NOT NULL DEFAULT 1,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_device_id_scd (DeviceID, StartDate),
    INDEX idx_device_type (DeviceType),
    INDEX idx_is_current (IsCurrent),
    INDEX idx_is_smart_device (IsSmartDevice)
);

-- DimMovie (Type 2 SCD)
CREATE TABLE DimMovie (
    MovieKey INT PRIMARY KEY AUTO_INCREMENT,
    MovieID VARCHAR(50) NOT NULL,
    MovieName VARCHAR(255) NOT NULL,
    PrimaryGenre VARCHAR(50),
    OriginCountry VARCHAR(100),
    Language VARCHAR(50),
    Rating VARCHAR(10),
    RuntimeMinutes INT,
    Director VARCHAR(255),
    Studio VARCHAR(255),
    IMDBScore DECIMAL(3, 1),
    ReleaseDate DATE,
    IsNetflixOriginal BIT NOT NULL DEFAULT 0,
    ProductionBudget DECIMAL(15, 2),
    AddedToStreamingDate DATE,
    IsCurrent BIT NOT NULL DEFAULT 1,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_movie_id_scd (MovieID, StartDate),
    INDEX idx_movie_name (MovieName),
    INDEX idx_is_current (IsCurrent),
    INDEX idx_primary_genre (PrimaryGenre)
);

-- DimShow (Denormalized - Shows/Seasons/Episodes in one table)
CREATE TABLE DimShow (
    ShowKey INT PRIMARY KEY AUTO_INCREMENT,
    ShowID VARCHAR(50) NOT NULL UNIQUE,
    ContentName VARCHAR(255) NOT NULL,
    ContentType VARCHAR(20) NOT NULL,
    ParentContentKey INT,
    ShowName VARCHAR(255),
    SeasonNumber INT,
    EpisodeNumber INT,
    PrimaryGenre VARCHAR(50),
    RuntimeMinutes INT,
    Director VARCHAR(255),
    AirDate DATE,
    IsNetflixOriginal BIT NOT NULL DEFAULT 0,
    ProductionBudget DECIMAL(15, 2),
    TotalSeasons INT,
    TotalEpisodes INT,
    NumberOfEpisodes INT,
    IsPremiere BIT DEFAULT 0,
    IsFinale BIT DEFAULT 0,
    Status VARCHAR(20),
    IsCurrent BIT NOT NULL DEFAULT 1,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (ParentContentKey) REFERENCES DimShow(ShowKey),
    INDEX idx_content_type (ContentType),
    INDEX idx_show_name (ShowName),
    INDEX idx_is_current (IsCurrent),
    INDEX idx_primary_genre (PrimaryGenre)
);

-- ================================================================
-- FACT TABLES
-- ================================================================

-- FactWatchEvent (Session Grain) 
CREATE TABLE FactWatchEvent (
    WatchEventKey BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Foreign Keys to Dimensions
    DateKey INT NOT NULL,
    TimeKey INT NOT NULL,
    UserKey INT NOT NULL,
    DeviceKey INT NOT NULL,
    SessionKey INT NOT NULL,
    
    -- Content Foreign Keys (Mutually Exclusive)
    ContentType BIT NOT NULL,  -- 0=Movie, 1=Show
    ShowKey INT,
    MovieKey INT,
    
    -- Facts (Measures)
    MinutesWatched INT NOT NULL DEFAULT 0,
    IsCompleted BIT,
    UserRating DECIMAL(3, 1),
    -- QualityLevel VARCHAR(20),
    BufferingEventCount INT DEFAULT 0,
    
    -- Degenerate Dimensions
    SessionStartDate DATE NOT NULL,
    SessionStartTime TIME NOT NULL,
    SessionEndTime TIME,
    
    -- Metadata
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_watch_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT fk_watch_time FOREIGN KEY (TimeKey) REFERENCES DimTime(TimeKey),
    CONSTRAINT fk_watch_user FOREIGN KEY (UserKey) REFERENCES DimUser(UserKey),
    CONSTRAINT fk_watch_device FOREIGN KEY (DeviceKey) REFERENCES DimDevice(DeviceKey),
    CONSTRAINT fk_watch_session FOREIGN KEY (SessionKey) REFERENCES DimSession(SessionKey),
    CONSTRAINT fk_watch_show FOREIGN KEY (ShowKey) REFERENCES DimShow(ShowKey),
    CONSTRAINT fk_watch_movie FOREIGN KEY (MovieKey) REFERENCES DimMovie(MovieKey),
    
    -- Indexes
    INDEX idx_user_date (UserKey, DateKey),
    INDEX idx_content_type (ContentType),
    INDEX idx_show_key (ShowKey),
    INDEX idx_movie_key (MovieKey),
    INDEX idx_session_date (SessionStartDate)
);

-- FactSubscriptionMonth (Month Grain) -
CREATE TABLE FactSubscriptionMonth (
    SubscriptionMonthKey INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Foreign Keys to Dimensions
    DateKey INT NOT NULL,
    UserKey INT NOT NULL,
    SubscriptionTypeKey INT NOT NULL,
    DeviceKey INT NOT NULL,
    
    -- Content Foreign Keys (Mutually Exclusive)
    ContentType BIT NOT NULL,  -- 0=Movie, 1=Show
    ShowKey INT,
    MovieKey INT,
    
    -- Engagement Facts (Aggregated from FactWatchEvent)
    MinutesWatchedThisMonth INT NOT NULL DEFAULT 0,
    SessionCountThisMonth INT NOT NULL DEFAULT 0,
    -- IsActiveThisMonth BIT NOT NULL DEFAULT 0,
    DaysActiveThisMonth INT DEFAULT 0,
    -- CompletedSessionsCount INT DEFAULT 0,
    -- ContinuedSessionsCount INT DEFAULT 0,
    -- AverageSessionDuration INT,
    -- AverageBufferingPerSession DECIMAL(5, 2),
    -- DominantQualityLevel VARCHAR(20),
    -- AverageUserRating DECIMAL(3, 1),
    -- RatedSessionsCount INT DEFAULT 0,
    
    -- Revenue Facts
    SubscriptionRevenue DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    -- AdRevenue DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    -- TotalRevenue DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    
    /*-- Cost Facts
    ContentDeliveryCost DECIMAL(10, 4) NOT NULL DEFAULT 0.0000,
    ContentLicensingCost DECIMAL(10, 4) NOT NULL DEFAULT 0.0000,
    ContentProductionCost DECIMAL(10, 4) NOT NULL DEFAULT 0.0000,
    OperationalCost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    TotalCost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    
    -- Profitability Facts
    GrossProfit DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    GrossProfitMargin DECIMAL(5, 2),*/
    
    -- Churn & Acquisition Flags
    CancelledSubscription BIT DEFAULT 0,
    IsNewSubscriberThisMonth BIT DEFAULT 0,
    
    -- Metadata
    LoadTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_sub_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT fk_sub_user FOREIGN KEY (UserKey) REFERENCES DimUser(UserKey),
    CONSTRAINT fk_sub_type FOREIGN KEY (SubscriptionTypeKey) REFERENCES DimSubscriptionType(SubscriptionTypeKey),
    CONSTRAINT fk_sub_device FOREIGN KEY (DeviceKey) REFERENCES DimDevice(DeviceKey),
    CONSTRAINT fk_sub_show FOREIGN KEY (ShowKey) REFERENCES DimShow(ShowKey),
    CONSTRAINT fk_sub_movie FOREIGN KEY (MovieKey) REFERENCES DimMovie(MovieKey),
    
    -- Indexes
    INDEX idx_user_month (UserKey, DateKey),
    INDEX idx_content_type (ContentType),
    INDEX idx_show_key (ShowKey),
    INDEX idx_movie_key (MovieKey),
    INDEX idx_cancelled (CancelledSubscription)
);

-- ================================================================
-- VIEWS FOR COMMON QUERIES
-- ================================================================

-- View: Active Subscribers by Month/* CREATE VIEW v_active_subscribers_by_month AS

/*SELECT 
    d.YearMonth,
    COUNT(DISTINCT fsm.UserKey) as ActiveSubscribers,
    SUM(fsm.SubscriptionRevenue + fsm.AdRevenue) as TotalRevenue,
    SUM(fsm.TotalCost) as TotalCost,
    SUM(fsm.GrossProfit) as TotalProfit
FROM FactSubscriptionMonth fsm
JOIN DimDate d ON fsm.DateKey = d.DateKey
WHERE fsm.IsActiveThisMonth = 1
GROUP BY d.YearMonth
ORDER BY d.YearMonth DESC;*/

-- View: Profitability by Subscription Type
/*CREATE VIEW v_profitability_by_subscription AS
SELECT 
    st.SubscriptionTypeName,
    COUNT(*) as ActiveSubscriptions,
    SUM(fsm.SubscriptionRevenue + fsm.AdRevenue) as TotalRevenue,
    SUM(fsm.TotalCost) as TotalCost,
    SUM(fsm.GrossProfit) as TotalProfit,
    AVG(fsm.GrossProfitMargin) as AvgMargin
FROM FactSubscriptionMonth fsm
JOIN DimSubscriptionType st ON fsm.SubscriptionTypeKey = st.SubscriptionTypeKey
WHERE fsm.IsActiveThisMonth = 1
GROUP BY st.SubscriptionTypeName
ORDER BY TotalProfit DESC;*/

-- View: Episode Completion Rates
CREATE VIEW v_episode_completion_rates AS
SELECT 
    ds.ShowName,
    COUNT(*) as TotalSessions,
    SUM(CASE WHEN we.IsCompleted = 1 THEN 1 ELSE 0 END) as CompletedSessions,
    (SUM(CASE WHEN we.IsCompleted = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) 
        as CompletionRate_Pct
FROM FactWatchEvent we
JOIN DimShow ds ON we.ShowKey = ds.ShowKey
WHERE we.ContentType = 1
GROUP BY ds.ShowName
ORDER BY CompletionRate_Pct DESC;

-- View: Show Profitability
/*CREATE VIEW v_show_profitability AS
SELECT 
    ds.ShowName,
    ds.PrimaryGenre,
    ds.IsNetflixOriginal,
    COUNT(DISTINCT fsm.UserKey) as UniqueViewers,
    SUM(fsm.SubscriptionRevenue + fsm.AdRevenue) as TotalRevenue,
    SUM(fsm.TotalCost) as TotalCost,
    SUM(fsm.GrossProfit) as TotalProfit,
    AVG(fsm.GrossProfitMargin) as AvgMargin
FROM FactSubscriptionMonth fsm
JOIN DimShow ds ON fsm.ShowKey = ds.ShowKey
WHERE fsm.IsActiveThisMonth = 1 AND fsm.ContentType = 1
GROUP BY ds.ShowKey, ds.ShowName, ds.PrimaryGenre, ds.IsNetflixOriginal
ORDER BY TotalProfit DESC;*/

-- ================================================================
-- STORED PROCEDURES
-- ================================================================

/*DELIMITER //
CREATE PROCEDURE sp_calculate_monthly_profits()
BEGIN
    UPDATE FactSubscriptionMonth
    SET 
        GrossProfit = (SubscriptionRevenue + AdRevenue) - 
                      (ContentDeliveryCost + ContentLicensingCost + 
                       ContentProductionCost + OperationalCost),
        GrossProfitMargin = (((SubscriptionRevenue + AdRevenue) - 
                              (ContentDeliveryCost + ContentLicensingCost + 
                               ContentProductionCost + OperationalCost)) / 
                             (SubscriptionRevenue + AdRevenue) * 100)
    WHERE (SubscriptionRevenue + AdRevenue) > 0;
END//
DELIMITER ;*/

-- ================================================================
-- VERIFICATION
-- ================================================================

-- Display all tables
SHOW TABLES;

-- Verify tables were created
SELECT COUNT(*) as TableCount FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'netflix_dw';

-- Success message
SELECT 'Database netflix_dw created successfully!' as Status;