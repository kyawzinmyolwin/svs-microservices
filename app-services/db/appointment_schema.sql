CREATE DATABASE appointments_svs;
CREATE USER 'appointments_user'@'%' IDENTIFIED BY 'AppointmentsP@ss';
GRANT ALL PRIVILEGES ON appointments_svs.* TO 'appointments_user'@'%';
FLUSH PRIVILEGES;

USE appointments_svs;

-- Drop existing tables to ensure a clean setup [1, 2]
DROP TABLE IF EXISTS appointment_services;
DROP TABLE IF EXISTS appointments;

-- 1. Appointments Table
-- Stores the core scheduling data. customer_id is a logical reference to the Customer Service [3].
CREATE TABLE appointments (
    appt_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL, -- Logical ID; no FK to CustomerDB
    appt_datetime DATETIME NOT NULL,
    notes VARCHAR(255) NULL,
    PRIMARY KEY (appt_id),
    INDEX idx_appt_datetime (appt_datetime) -- For faster sorting of appointment lists [4]
);

-- 2. Appointment to Services Table
-- A many-to-many junction table linking appointments to treatment IDs [4].
CREATE TABLE appointment_services (
    appt_id INT NOT NULL,
    service_id INT NOT NULL, -- Logical ID; no FK to CatalogDB
    PRIMARY KEY (appt_id, service_id),
    -- Local constraint to ensure data integrity within this service [4]
    CONSTRAINT fk_as_appt FOREIGN KEY (appt_id) REFERENCES appointments(appt_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- Populate with sample data for testing [5]
USE appointments_svs;

-- Clear existing data to prevent primary key collisions during testing
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE appointment_services;
TRUNCATE TABLE appointments;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- 1. Populate Appointments
-- Linking to logical customer IDs 101 through 105
-- ---------------------------------------------------------
INSERT INTO appointments (customer_id, appt_datetime, notes) VALUES
(101, '2026-05-01 09:00:00', 'First-time customer, prefers morning slots.'),
(102, '2026-05-01 11:30:00', 'Standard follow-up appointment.'),
(103, '2026-05-02 14:00:00', 'Wants to discuss pricing for multi-session packages.'),
(101, '2026-05-15 10:00:00', 'Recurring monthly visit.'),
(104, '2026-05-20 16:45:00', NULL),
(105, '2026-05-22 08:30:00', 'Requires handicap accessible room.');

-- ---------------------------------------------------------
-- 2. Populate Appointment Services (Junction Table)
-- Linking Appt IDs to logical service IDs (50-55) from CatalogDB
-- ---------------------------------------------------------
INSERT INTO appointment_services (appt_id, service_id) VALUES
(1, 50), (1, 51), -- Appt 1 has two services
(2, 50),          -- Appt 2 has one service
(3, 52), (3, 55), -- Appt 3 has two services
(4, 50),          -- Appt 4 has one service
(5, 53),          -- Appt 5 has one service
(6, 50), (6, 54); -- Appt 6 has two services