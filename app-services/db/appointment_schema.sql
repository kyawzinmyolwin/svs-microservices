CREATE DATABASE appointments_svs;
CREATE USER 'appointments_user'@'%' IDENTIFIED BY 'AppointmentsP@ss';
GRANT ALL PRIVILEGES ON customers_svs.* TO 'appointments_user'@'%';
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
