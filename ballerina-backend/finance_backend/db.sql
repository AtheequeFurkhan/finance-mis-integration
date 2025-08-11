CREATE DATABASE IF NOT EXISTS finance_db;
USE finance_db;

CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO transactions (name, amount) VALUES
('Opening ARR', 5000.00),
('New Sales', 1200.50),
('Expansion', 800.75),
('Churn', -300.00),
('Renewals', 2500.00);
