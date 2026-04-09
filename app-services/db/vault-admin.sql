-- For Vault Admin
CREATE USER 'vault_admin'@'%' IDENTIFIED BY 'VaultP@ssw0rd';
GRANT ALL PRIVILEGES ON *.* TO 'vault_admin'@'%';
FLUSH PRIVILEGES;

GRANT CREATE USER, GRANT OPTION
ON *.* TO 'vault_admin'@'%';
FLUSH PRIVILEGES;

-- If Permissions error occurs, run the above two GRANT statements again to ensure vault_admin has necessary permissions to manage users and roles for Vault's database secrets engine.

-- Grant full permissions to the Vault admin on the specific database
GRANT ALL PRIVILEGES ON customers_svs.* TO 'vault_admin'@'%';

-- Vault MUST have this to create the dynamic 'svs-customer-role' users
GRANT CREATE USER, RELOAD, PROCESS ON *.* TO 'vault_admin'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;