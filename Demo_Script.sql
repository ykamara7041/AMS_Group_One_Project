-- =======================================================================================
-- SMART HOME AUTOMATION SYSTEM - LIVE DEMO SCRIPT
-- Run each section one at a time during your presentation
-- =======================================================================================

USE SmartHomeDB;
GO

-- =======================================================================================
-- DEMO 1: Show the Database Structure
-- "Let's start by looking at all the tables in our database"
-- =======================================================================================

SELECT TABLE_NAME, TABLE_TYPE 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

-- =======================================================================================
-- DEMO 2: Show Current Data in All Tables
-- "Here's the sample data we've loaded into each table"
-- =======================================================================================

SELECT * FROM Users;
SELECT * FROM Devices;
SELECT * FROM AutomationRules;
SELECT * FROM EnergyUsage;
SELECT * FROM Alerts;
GO

-- =======================================================================================
-- DEMO 3: Stored Procedures in Action
-- "Now let's demonstrate our stored procedures working in real-time"
-- =======================================================================================

-- 3a: Add a new user
PRINT '--- Adding a new user ---';
EXEC usp_AddUser 'Diana Prince', 'diana@smarthome.com', '555-0200', 'Admin';
SELECT * FROM Users WHERE Email = 'diana@smarthome.com';
GO

-- 3b: Try adding a duplicate email (shows error handling)
PRINT '--- Attempting duplicate email (expect error handling) ---';
EXEC usp_AddUser 'Duplicate User', 'diana@smarthome.com', '555-0000', 'Guest';
GO

-- 3c: Register a new device
PRINT '--- Registering a new smart device ---';
EXEC sp_RegisterDevice 'Thermostat', 'Bedroom', '192.168.1.250';
SELECT * FROM Devices WHERE Location = 'Bedroom';
GO

-- 3d: Log energy usage
PRINT '--- Logging energy consumption ---';
EXEC sp_LogEnergyUsage 1, 5.0, 0.15;
SELECT TOP 3 * FROM EnergyUsage ORDER BY RecordID DESC;
GO

-- 3e: Trigger and resolve an alert
PRINT '--- Triggering a new alert ---';
EXEC sp_TriggerAlert 1, 'Unusual Power Spike', 'High';
SELECT * FROM Alerts WHERE AlertType = 'Unusual Power Spike';
GO

-- =======================================================================================
-- DEMO 4: Views for Reporting
-- "Our views provide real-time dashboards for the smart home system"
-- =======================================================================================

-- 4a: Active Alerts Dashboard
PRINT '--- Active Alerts Dashboard ---';
SELECT * FROM vw_ActiveAlerts;
GO

-- 4b: Monthly Energy Summary
PRINT '--- Monthly Energy Consumption Report ---';
SELECT * FROM vw_MonthlyEnergySummary;
GO

-- 4c: Active Automation Rules
PRINT '--- Active Automation Rules ---';
SELECT * FROM vw_ActiveAutomationRules;
GO

-- 4d: Device Status & Maintenance Report
PRINT '--- Device Maintenance Status ---';
SELECT * FROM vw_DeviceStatusReport;
GO

-- =======================================================================================
-- DEMO 5: Resolving an Alert (Full Workflow)
-- "Let's show the complete alert lifecycle"
-- =======================================================================================

PRINT '--- Before resolving: Active alerts ---';
SELECT AlertID, AlertType, Severity, ResolutionStatus FROM Alerts;
GO

-- Resolve the alert we just created
DECLARE @LastAlertID INT = (SELECT MAX(AlertID) FROM Alerts);
EXEC sp_ResolveAlert @LastAlertID;
GO

PRINT '--- After resolving: Updated alerts ---';
SELECT AlertID, AlertType, Severity, ResolutionStatus FROM Alerts;
GO

-- =======================================================================================
-- DEMO 6: Show Indexes (Performance Optimization)
-- "We've added indexes to optimize query performance"
-- =======================================================================================

SELECT 
    i.name AS IndexName,
    t.name AS TableName,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.name LIKE 'IX_%'
ORDER BY t.name, i.name;
GO

-- =======================================================================================
-- DEMO 7: Data Validation (CHECK Constraints in Action)
-- "Our constraints protect data integrity"
-- =======================================================================================

-- Try inserting an invalid device type (should fail)
PRINT '--- Attempting invalid device type ---';
BEGIN TRY
    INSERT INTO Devices (Type, Location, Status, IPAddress) 
    VALUES ('InvalidType', 'Test Room', 'Online', '0.0.0.0');
END TRY
BEGIN CATCH
    PRINT 'Constraint Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- Try inserting an invalid access level (should fail)
PRINT '--- Attempting invalid access level ---';
EXEC usp_AddUser 'Hacker', 'hack@test.com', '000-0000', 'SuperAdmin';
GO

PRINT '=== DEMO COMPLETE ===';
GO
