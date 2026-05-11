-- =======================================================================================
-- Smart Home Automation System - Database Implementation
-- =======================================================================================

-- Create Database
CREATE DATABASE SmartHomeDB;
GO

USE SmartHomeDB;
GO

-- =======================================================================================
-- 1. Tables Creation with Validation Constraints
-- =======================================================================================

-- Users Table
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    Mobile NVARCHAR(20),
    AccessLevel NVARCHAR(20) NOT NULL CHECK (AccessLevel IN ('Admin', 'Standard', 'Guest')),
    LastLogin DATETIME NULL
);
GO

-- Devices Table
CREATE TABLE Devices (
    DeviceID INT IDENTITY(1,1) PRIMARY KEY,
    Type NVARCHAR(50) NOT NULL CHECK (Type IN ('Light', 'Thermostat', 'Camera')),
    Location NVARCHAR(100) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Offline',
    IPAddress NVARCHAR(15),
    LastMaintenance DATETIME NULL
);
GO

-- AutomationRules Table
CREATE TABLE AutomationRules (
    RuleID INT IDENTITY(1,1) PRIMARY KEY,
    DeviceID INT NOT NULL,
    TriggerCondition NVARCHAR(255) NOT NULL,
    Action NVARCHAR(255) NOT NULL,
    Schedule NVARCHAR(100),
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_AutomationRules_Devices FOREIGN KEY (DeviceID) REFERENCES Devices(DeviceID) ON DELETE CASCADE
);
GO

-- EnergyUsage Table
CREATE TABLE EnergyUsage (
    RecordID INT IDENTITY(1,1) PRIMARY KEY,
    DeviceID INT NOT NULL,
    Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
    PowerConsumption DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_EnergyUsage_Devices FOREIGN KEY (DeviceID) REFERENCES Devices(DeviceID) ON DELETE CASCADE
);
GO

-- Alerts Table
CREATE TABLE Alerts (
    AlertID INT IDENTITY(1,1) PRIMARY KEY,
    DeviceID INT NOT NULL,
    AlertType NVARCHAR(100) NOT NULL,
    Severity NVARCHAR(20) NOT NULL CHECK (Severity IN ('Low', 'Medium', 'High', 'Critical')),
    Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
    ResolutionStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_Alerts_Devices FOREIGN KEY (DeviceID) REFERENCES Devices(DeviceID) ON DELETE CASCADE
);
GO

-- =======================================================================================
-- 2. Indexes for Performance Optimization
-- =======================================================================================

-- Improve searches for devices based on location and status
CREATE NONCLUSTERED INDEX IX_Devices_Location ON Devices(Location);
CREATE NONCLUSTERED INDEX IX_Devices_Status ON Devices(Status);

-- Improve time-series queries for energy usage
CREATE NONCLUSTERED INDEX IX_EnergyUsage_Device_Timestamp ON EnergyUsage(DeviceID, Timestamp);

-- Improve filtering on unresolved alerts
CREATE NONCLUSTERED INDEX IX_Alerts_ResolutionStatus ON Alerts(ResolutionStatus);
CREATE NONCLUSTERED INDEX IX_Alerts_Severity ON Alerts(Severity);

-- Improve looking up rules for specific devices
CREATE NONCLUSTERED INDEX IX_AutomationRules_DeviceID ON AutomationRules(DeviceID);
GO

-- =======================================================================================
-- 3. Stored Procedures (5 Essential)
-- =======================================================================================

-- SP 1: Add a new user securely
CREATE PROCEDURE usp_AddUser
    @Name NVARCHAR(100),
    @Email NVARCHAR(255),
    @Mobile NVARCHAR(20),
    @AccessLevel NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO Users (Name, Email, Mobile, AccessLevel)
        VALUES (@Name, @Email, @Mobile, @AccessLevel);
        PRINT 'User added successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error adding user: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP 2: Register a new IoT device
CREATE PROCEDURE sp_RegisterDevice
    @Type NVARCHAR(50),
    @Location NVARCHAR(100),
    @IPAddress NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Devices (Type, Location, IPAddress, Status)
    VALUES (@Type, @Location, @IPAddress, 'Online');
END;
GO

-- SP 3: Log energy usage for a device
CREATE PROCEDURE sp_LogEnergyUsage
    @DeviceID INT,
    @PowerConsumption DECIMAL(10,2),
    @CostPerUnit DECIMAL(10,2) -- E.g., cost per kWh
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalCost DECIMAL(10,2) = @PowerConsumption * @CostPerUnit;
    
    INSERT INTO EnergyUsage (DeviceID, PowerConsumption, Cost)
    VALUES (@DeviceID, @PowerConsumption, @TotalCost);
END;
GO

-- SP 4: Trigger an alert for a specific device
CREATE PROCEDURE sp_TriggerAlert
    @DeviceID INT,
    @AlertType NVARCHAR(100),
    @Severity NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Alerts (DeviceID, AlertType, Severity)
    VALUES (@DeviceID, @AlertType, @Severity);
END;
GO

-- SP 5: Resolve an alert
CREATE PROCEDURE sp_ResolveAlert
    @AlertID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Alerts
    SET ResolutionStatus = 'Resolved'
    WHERE AlertID = @AlertID;
END;
GO

-- =======================================================================================
-- 4. Views for Reporting (4 Critical Views)
-- =======================================================================================

-- View 1: Active Alerts Summary
CREATE VIEW vw_ActiveAlerts AS
SELECT 
    a.AlertID,
    d.DeviceID,
    d.Type AS DeviceType,
    d.Location,
    a.AlertType,
    a.Severity,
    a.Timestamp AS AlertTime
FROM Alerts a
JOIN Devices d ON a.DeviceID = d.DeviceID
WHERE a.ResolutionStatus = 'Pending';
GO

-- View 2: Monthly Energy Consumption & Cost per Device
CREATE VIEW vw_MonthlyEnergySummary AS
SELECT 
    d.DeviceID,
    d.Type AS DeviceType,
    d.Location,
    YEAR(e.Timestamp) AS Year,
    MONTH(e.Timestamp) AS Month,
    SUM(e.PowerConsumption) AS TotalConsumption,
    SUM(e.Cost) AS TotalCost
FROM EnergyUsage e
JOIN Devices d ON e.DeviceID = d.DeviceID
GROUP BY 
    d.DeviceID, d.Type, d.Location, YEAR(e.Timestamp), MONTH(e.Timestamp);
GO

-- View 3: Automation Rules Dashboard
CREATE VIEW vw_ActiveAutomationRules AS
SELECT 
    ar.RuleID,
    d.Type AS DeviceType,
    d.Location,
    ar.TriggerCondition,
    ar.Action,
    ar.Schedule
FROM AutomationRules ar
JOIN Devices d ON ar.DeviceID = d.DeviceID
WHERE ar.IsActive = 1;
GO

-- View 4: Device Status Report
CREATE VIEW vw_DeviceStatusReport AS
SELECT 
    DeviceID,
    Type,
    Location,
    Status,
    LastMaintenance,
    DATEDIFF(day, LastMaintenance, GETDATE()) AS DaysSinceLastMaintenance
FROM Devices;
GO

-- =======================================================================================
-- 5. Sample Datasets for Testing
-- =======================================================================================

-- Insert Users
EXEC usp_AddUser 'Alice Smith', 'alice@example.com', '555-0101', 'Admin';
EXEC usp_AddUser 'Bob Johnson', 'bob@example.com', '555-0102', 'Standard';
EXEC usp_AddUser 'Charlie Brown', 'charlie@example.com', '555-0103', 'Guest';
GO

-- Insert Devices
EXEC sp_RegisterDevice 'Light', 'Living Room', '192.168.1.101';
EXEC sp_RegisterDevice 'Thermostat', 'Hallway', '192.168.1.102';
EXEC sp_RegisterDevice 'Camera', 'Front Door', '192.168.1.103';
EXEC sp_RegisterDevice 'Light', 'Kitchen', '192.168.1.104';
EXEC sp_RegisterDevice 'Camera', 'Backyard', '192.168.1.105';
GO

-- Update some devices with LastMaintenance
UPDATE Devices SET LastMaintenance = DATEADD(month, -2, GETDATE()) WHERE DeviceID IN (1, 2);
UPDATE Devices SET LastMaintenance = DATEADD(month, -6, GETDATE()) WHERE DeviceID = 3;
GO

-- Insert Automation Rules
INSERT INTO AutomationRules (DeviceID, TriggerCondition, Action, Schedule)
VALUES 
(1, 'Motion Detected', 'Turn On', '18:00-06:00'),
(2, 'Temperature < 68F', 'Set Heat to 72F', '24/7'),
(3, 'Motion Detected', 'Record Video & Notify', '24/7'),
(4, 'Time is 22:00', 'Turn Off', 'Daily');
GO

-- Log Energy Usage (Assume $0.15 per unit)
EXEC sp_LogEnergyUsage 1, 1.5, 0.15;
EXEC sp_LogEnergyUsage 2, 12.0, 0.15;
EXEC sp_LogEnergyUsage 4, 2.0, 0.15;
-- Adding historical data manually for demonstration
INSERT INTO EnergyUsage (DeviceID, Timestamp, PowerConsumption, Cost)
VALUES 
(1, DATEADD(day, -1, GETDATE()), 1.2, 0.18),
(2, DATEADD(day, -1, GETDATE()), 15.0, 2.25),
(2, DATEADD(day, -2, GETDATE()), 14.5, 2.17);
GO

-- Trigger Alerts
EXEC sp_TriggerAlert 3, 'Camera Disconnected', 'Critical';
EXEC sp_TriggerAlert 2, 'Filter Replacement Needed', 'Medium';
EXEC sp_TriggerAlert 5, 'Low Battery', 'Low';
GO

-- Resolve one alert
EXEC sp_ResolveAlert 2;
GO
