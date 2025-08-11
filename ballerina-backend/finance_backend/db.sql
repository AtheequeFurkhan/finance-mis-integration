CREATE DATABASE IF NOT EXISTS finance_db;
USE finance_db;

CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Add indexes for better performance
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_amount ON transactions(amount);

INSERT INTO transactions (name, amount, category, description) VALUES
('Opening ARR', 5000.00, 'Revenue', 'Annual Recurring Revenue at start'),
('New Sales', 1200.50, 'Revenue', 'New customer acquisition'),
('Expansion', 800.75, 'Revenue', 'Existing customer upsell'),
('Churn', -300.00, 'Revenue', 'Customer cancellation'),
('Renewals', 2500.00, 'Revenue', 'Customer renewal revenue'),
('Office Rent', -2000.00, 'Expense', 'Monthly office space rental'),
('Marketing Campaign', -500.00, 'Expense', 'Digital marketing spend'),
('Software Licenses', -300.00, 'Expense', 'Monthly SaaS subscriptions'),
('Employee Salaries', -8000.00, 'Expense', 'Monthly payroll expense'),
('Consulting Fee', 1500.00, 'Revenue', 'Professional services revenue');
