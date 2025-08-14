// import ballerina/time;

# Department record type
#
# + department_id - field description  
# + name - field description  
# + cost_center - field description  
# + manager - field description
public type Department record {|
    int department_id;
    string name;
    string cost_center;
    string manager?;
|};

# Expense Category record type
#
# + category_id - field description  
# + name - field description  
# + description - field description
public type ExpenseCategory record {|
    int category_id;
    string name;
    string description?;
|};

# Transaction record type
#
# + transaction_id - field description  
# + transaction_type - field description  
# + department_id - field description  
# + category_id - field description  
# + amount - field description  
# + transaction_date - field description  
# + description - field description
public type Transaction record {|
    int transaction_id;
    string transaction_type;
    int department_id?;
    int category_id?;
    decimal amount;
    string transaction_date;
    string description?;
|};

# Department Revenue record type
#
# + department_id - field description  
# + department_name - field description  
# + cost_center - field description  
# + total_revenue - field description
public type DepartmentRevenue record {|
    int department_id;
    string department_name;
    string cost_center;
    decimal total_revenue;
|};

# Category Expense record type
#
# + category_id - field description  
# + category_name - field description  
# + total_expenses - field description
public type CategoryExpense record {|
    int category_id;
    string category_name;
    decimal total_expenses;
|};

# Daily Financial record type
#
# + date - field description  
# + total_revenue - field description  
# + total_expenses - field description  
# + net_income - field description
public type DailyFinancial record {|
    string date;
    decimal total_revenue;
    decimal total_expenses;
    decimal net_income;
|};