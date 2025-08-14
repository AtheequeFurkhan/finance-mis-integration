-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
    department_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    cost_center VARCHAR(50) NOT NULL,
    manager VARCHAR(100)
);

-- Create expense categories table
CREATE TABLE IF NOT EXISTS expense_categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('REVENUE', 'EXPENSE')),
    department_id INTEGER REFERENCES departments(department_id),
    category_id INTEGER REFERENCES expense_categories(category_id),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_dept ON transactions(department_id);
CREATE INDEX IF NOT EXISTS idx_transactions_cat ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);

-- Insert sample data if tables are empty
INSERT INTO departments (name, cost_center, manager)
SELECT 'Sales', 'CC001', 'John Smith'
WHERE NOT EXISTS (SELECT 1 FROM departments LIMIT 1);

INSERT INTO departments (name, cost_center, manager)
SELECT 'Marketing', 'CC002', 'Jane Doe'
WHERE NOT EXISTS (SELECT 1 FROM departments LIMIT 1);

INSERT INTO departments (name, cost_center, manager)
SELECT 'Engineering', 'CC003', 'Mike Johnson'
WHERE NOT EXISTS (SELECT 1 FROM departments LIMIT 1);

INSERT INTO expense_categories (name, description)
SELECT 'Salaries', 'Employee salaries and wages'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories LIMIT 1);

INSERT INTO expense_categories (name, description)
SELECT 'Marketing', 'Marketing and advertising expenses'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories LIMIT 1);

INSERT INTO expense_categories (name, description)
SELECT 'Equipment', 'Office and technical equipment'
WHERE NOT EXISTS (SELECT 1 FROM expense_categories LIMIT 1);

-- Add sample transactions if none exist
INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'REVENUE', 1, 1, 5000.00, CURRENT_DATE - INTERVAL '7 days', 'Product sales - Week 1'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'EXPENSE', 2, 2, 1500.00, CURRENT_DATE - INTERVAL '6 days', 'Social media campaign'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'REVENUE', 1, 1, 7500.00, CURRENT_DATE - INTERVAL '5 days', 'Product sales - Week 2'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'EXPENSE', 3, 3, 3000.00, CURRENT_DATE - INTERVAL '4 days', 'Development server upgrade'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'EXPENSE', 1, 1, 2000.00, CURRENT_DATE - INTERVAL '3 days', 'Sales team commission'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (transaction_type, department_id, category_id, amount, transaction_date, description)
SELECT 'REVENUE', 2, 1, 3500.00, CURRENT_DATE - INTERVAL '2 days', 'Consulting service'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);