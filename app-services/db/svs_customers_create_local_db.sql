-- 1. Create the new dedicated database
DROP DATABASE IF EXISTS customers_svs;
CREATE DATABASE customers_svs;

-- 2. Select the database
USE customers_svs;

-- 3. Create the 'customers' table in the new database
CREATE TABLE customers (
  customer_id INT NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  family_name VARCHAR(60) NOT NULL,
  email VARCHAR(120),
  phone VARCHAR(30) NOT NULL,
  date_joined DATE NOT NULL,
  PRIMARY KEY (customer_id),
  INDEX idx_customer_name (family_name, first_name)
);


-- 4. INSERT the data from your old 'svs' database into the new 'customers_svs' database.
-- (This is the critical data transfer step)
INSERT INTO customers_svs.customers (customer_id, first_name, family_name, email, phone, date_joined)
SELECT customer_id, first_name, family_name, email, phone, date_joined
FROM customers_svs.customers;

-- Optional: Create a specific user/permissions for this new service
-- CREATE USER 'catalog_user'@'localhost' IDENTIFIED BY 'CatalogP@ss';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON customers_svs.* TO 'catalog_user'@'localhost';

-- Ensure we are using the correct database context
USE appointments_svs;

-- Clear existing data for a clean start
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE customers;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- 1. Populate Customers
-- Manual IDs are set to 101+ to match the Appointment script logic
-- ---------------------------------------------------------
INSERT INTO customers (customer_id, first_name, family_name, email, phone, date_joined) VALUES
(101, 'Alice', 'Smith', 'alice.smith@example.com', '555-0101', '2025-01-15'),
(102, 'Bob', 'Johnson', 'bjohnson@provider.net', '555-0102', '2025-02-10'),
(103, 'Charlie', 'Davis', 'charlie.d@webmail.com', '555-0103', '2025-03-05'),
(104, 'Diana', 'Prince', 'diana.p@service.com', '555-0104', '2025-03-20'),
(105, 'Edward', 'Norton', 'ed.norton@cinema.com', '555-0105', '2025-04-01');

-- ---------------------------------------------------------
-- 2. Reset Auto-Increment
-- Ensures the next record added starts after our manual IDs
-- ---------------------------------------------------------
ALTER TABLE customers AUTO_INCREMENT = 106;