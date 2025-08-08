-- Insert test data
USE training_db;

-- Insert users
INSERT INTO users (username, email) VALUES
('john_doe', 'john@example.com'),
('jane_smith', 'jane@example.com'),
('bob_wilson', 'bob@example.com'),
('alice_brown', 'alice@example.com'),
('charlie_davis', 'charlie@example.com');

-- Insert products
INSERT INTO products (name, price, stock_quantity, category_id) VALUES
('Laptop Pro', 1299.99, 50, 1),
('Wireless Mouse', 29.99, 200, 1),
('Mechanical Keyboard', 89.99, 100, 1),
('Monitor 27"', 299.99, 75, 1),
('USB Cable', 9.99, 500, 1),
('Smartphone', 699.99, 30, 2),
('Tablet', 399.99, 40, 2),
('Headphones', 149.99, 80, 2),
('Speaker', 79.99, 60, 2),
('Charger', 19.99, 150, 2);

-- Insert some initial orders
INSERT INTO orders (user_id, total_amount, status) VALUES
(1, 1329.98, 'completed'),
(2, 89.99, 'processing'),
(3, 299.99, 'pending'),
(4, 719.98, 'completed'),
(5, 29.99, 'cancelled');

-- Insert order items
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 1299.99),
(1, 2, 1, 29.99),
(2, 3, 1, 89.99),
(3, 4, 1, 299.99),
(4, 6, 1, 699.99),
(4, 5, 2, 9.99),
(5, 2, 1, 29.99);

-- Insert inventory movements
INSERT INTO inventory_movements (product_id, movement_type, quantity, reference_id) VALUES
(1, 'in', 100, NULL),
(2, 'in', 300, NULL),
(3, 'in', 150, NULL),
(4, 'in', 100, NULL),
(5, 'in', 600, NULL),
(1, 'out', 1, 1),
(2, 'out', 1, 1),
(3, 'out', 1, 2),
(4, 'out', 1, 3),
(6, 'out', 1, 4),
(5, 'out', 2, 4),
(2, 'out', 1, 5);
