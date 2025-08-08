-- MySQL E-commerce Dataset para Laboratorios DBA
-- Versión: 1.0
-- Descripción: Dataset realista para pruebas de performance, backups y administración
-- Tamaño aproximado: 50MB de datos

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS ecommerce_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_lab;

-- Tabla de categorías
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_parent (parent_id),
    INDEX idx_active (is_active),
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Tabla de proveedores
CREATE TABLE suppliers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    tax_id VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_city (city),
    INDEX idx_country (country),
    INDEX idx_active (is_active)
);

-- Tabla de productos
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    supplier_id INT,
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    min_stock_level INT DEFAULT 0,
    weight DECIMAL(8,3),
    dimensions VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_name (name),
    INDEX idx_category (category_id),
    INDEX idx_supplier (supplier_id),
    INDEX idx_price (price),
    INDEX idx_stock (stock_quantity),
    INDEX idx_active (is_active),
    INDEX idx_created (created_at),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- Tabla de clientes
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('M', 'F', 'Other'),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    customer_type ENUM('Regular', 'Premium', 'VIP') DEFAULT 'Regular',
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_code (customer_code),
    INDEX idx_email (email),
    INDEX idx_name (last_name, first_name),
    INDEX idx_registration (registration_date),
    INDEX idx_type (customer_type),
    INDEX idx_active (is_active)
);

-- Tabla de direcciones de clientes
CREATE TABLE customer_addresses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    address_type ENUM('Billing', 'Shipping', 'Both') DEFAULT 'Both',
    street_address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_type (address_type),
    INDEX idx_city (city),
    INDEX idx_country (country),
    INDEX idx_default (is_default),
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Tabla de órdenes
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded') DEFAULT 'Pending',
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash') DEFAULT 'Credit Card',
    payment_status ENUM('Pending', 'Paid', 'Failed', 'Refunded') DEFAULT 'Pending',
    shipping_address_id INT,
    billing_address_id INT,
    notes TEXT,
    shipped_date TIMESTAMP NULL,
    delivered_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_number (order_number),
    INDEX idx_customer (customer_id),
    INDEX idx_order_date (order_date),
    INDEX idx_status (status),
    INDEX idx_payment_status (payment_status),
    INDEX idx_total (total_amount),
    INDEX idx_shipped (shipped_date),
    INDEX idx_delivered (delivered_date),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (shipping_address_id) REFERENCES customer_addresses(id),
    FOREIGN KEY (billing_address_id) REFERENCES customer_addresses(id)
);

-- Tabla de detalles de órdenes
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id),
    INDEX idx_created (created_at),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Tabla de inventario (movimientos)
CREATE TABLE inventory_movements (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    movement_type ENUM('IN', 'OUT', 'ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL,
    reference_type ENUM('Purchase', 'Sale', 'Return', 'Adjustment', 'Transfer') NOT NULL,
    reference_id INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    INDEX idx_product (product_id),
    INDEX idx_type (movement_type),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_created (created_at),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Tabla de reseñas de productos
CREATE TABLE product_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_id INT,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    helpful_votes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_customer (customer_id),
    INDEX idx_order (order_id),
    INDEX idx_rating (rating),
    INDEX idx_approved (is_approved),
    INDEX idx_created (created_at),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Tabla de cupones de descuento
CREATE TABLE discount_coupons (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    discount_type ENUM('Percentage', 'Fixed Amount') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_order_amount DECIMAL(10,2) DEFAULT 0.00,
    maximum_discount_amount DECIMAL(10,2),
    usage_limit INT,
    used_count INT DEFAULT 0,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_valid_from (valid_from),
    INDEX idx_valid_until (valid_until),
    INDEX idx_active (is_active)
);

-- Tabla de uso de cupones
CREATE TABLE coupon_usage (
    id INT PRIMARY KEY AUTO_INCREMENT,
    coupon_id INT NOT NULL,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_coupon (coupon_id),
    INDEX idx_order (order_id),
    INDEX idx_customer (customer_id),
    INDEX idx_used_at (used_at),
    FOREIGN KEY (coupon_id) REFERENCES discount_coupons(id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Insertar datos de categorías
INSERT INTO categories (name, description, parent_id) VALUES
('Electronics', 'Electronic devices and accessories', NULL),
('Computers', 'Desktop and laptop computers', 1),
('Mobile Devices', 'Smartphones and tablets', 1),
('Audio', 'Headphones, speakers, and audio equipment', 1),
('Gaming', 'Gaming consoles and accessories', 1),
('Home & Garden', 'Home improvement and garden supplies', NULL),
('Furniture', 'Indoor and outdoor furniture', 6),
('Tools', 'Hand tools and power tools', 6),
('Clothing', 'Apparel for men, women, and children', NULL),
('Men\'s Clothing', 'Clothing for men', 9),
('Women\'s Clothing', 'Clothing for women', 9),
('Sports & Outdoors', 'Sports equipment and outdoor gear', NULL),
('Fitness', 'Exercise equipment and accessories', 12),
('Books', 'Physical and digital books', NULL),
('Health & Beauty', 'Health and beauty products', NULL);

-- Insertar datos de proveedores
INSERT INTO suppliers (name, contact_person, email, phone, address, city, country, postal_code, tax_id) VALUES
('TechSupply Corp', 'John Smith', 'john@techsupply.com', '+1-555-0101', '123 Tech Street', 'San Francisco', 'USA', '94105', 'US123456789'),
('Global Electronics Ltd', 'Maria Garcia', 'maria@globalelec.com', '+1-555-0102', '456 Electronics Ave', 'Los Angeles', 'USA', '90210', 'US987654321'),
('Fashion Forward Inc', 'David Johnson', 'david@fashionforward.com', '+1-555-0103', '789 Fashion Blvd', 'New York', 'USA', '10001', 'US456789123'),
('Home Essentials Co', 'Sarah Wilson', 'sarah@homeessentials.com', '+1-555-0104', '321 Home Street', 'Chicago', 'USA', '60601', 'US789123456'),
('Sports Gear Pro', 'Mike Brown', 'mike@sportsgear.com', '+1-555-0105', '654 Sports Way', 'Denver', 'USA', '80202', 'US321654987'),
('Book World Publishers', 'Lisa Davis', 'lisa@bookworld.com', '+1-555-0106', '987 Book Lane', 'Boston', 'USA', '02101', 'US654987321'),
('Beauty Plus Supplies', 'Jennifer Miller', 'jennifer@beautyplus.com', '+1-555-0107', '147 Beauty Street', 'Miami', 'USA', '33101', 'US147258369'),
('Outdoor Adventure Co', 'Robert Taylor', 'robert@outdooradv.com', '+1-555-0108', '258 Adventure Road', 'Seattle', 'USA', '98101', 'US258369147');

-- Procedimiento para insertar productos (se ejecutará después)
DELIMITER //
CREATE PROCEDURE InsertSampleProducts()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE category_count INT;
    DECLARE supplier_count INT;
    
    SELECT COUNT(*) INTO category_count FROM categories WHERE parent_id IS NOT NULL;
    SELECT COUNT(*) INTO supplier_count FROM suppliers;
    
    WHILE i <= 1000 DO
        INSERT INTO products (
            sku, 
            name, 
            description, 
            category_id, 
            supplier_id, 
            price, 
            cost, 
            stock_quantity, 
            min_stock_level,
            weight
        ) VALUES (
            CONCAT('SKU-', LPAD(i, 6, '0')),
            CONCAT('Product ', i, ' - ', 
                CASE (i % 10)
                    WHEN 0 THEN 'Premium Edition'
                    WHEN 1 THEN 'Standard Model'
                    WHEN 2 THEN 'Deluxe Version'
                    WHEN 3 THEN 'Professional Grade'
                    WHEN 4 THEN 'Home Edition'
                    WHEN 5 THEN 'Business Class'
                    WHEN 6 THEN 'Economy Model'
                    WHEN 7 THEN 'Advanced Series'
                    WHEN 8 THEN 'Compact Design'
                    ELSE 'Special Edition'
                END
            ),
            CONCAT('High-quality product with excellent features. Product number ', i, ' offers great value and performance.'),
            (SELECT id FROM categories WHERE parent_id IS NOT NULL ORDER BY RAND() LIMIT 1),
            (SELECT id FROM suppliers ORDER BY RAND() LIMIT 1),
            ROUND(RAND() * 999 + 10, 2),
            ROUND(RAND() * 500 + 5, 2),
            FLOOR(RAND() * 100),
            FLOOR(RAND() * 10) + 5,
            ROUND(RAND() * 10 + 0.1, 3)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Procedimiento para insertar clientes
DELIMITER //
CREATE PROCEDURE InsertSampleCustomers()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE first_names TEXT DEFAULT 'John,Jane,Michael,Sarah,David,Lisa,Robert,Jennifer,William,Mary,James,Patricia,Christopher,Linda,Daniel,Barbara,Matthew,Elizabeth,Anthony,Helen,Mark,Nancy,Donald,Betty,Steven,Dorothy,Paul,Sandra,Andrew,Kimberly';
    DECLARE last_names TEXT DEFAULT 'Smith,Johnson,Williams,Brown,Jones,Garcia,Miller,Davis,Rodriguez,Martinez,Hernandez,Lopez,Gonzalez,Wilson,Anderson,Thomas,Taylor,Moore,Jackson,Martin,Lee,Perez,Thompson,White,Harris,Sanchez,Clark,Ramirez,Lewis,Robinson';
    DECLARE domains TEXT DEFAULT 'gmail.com,yahoo.com,hotmail.com,outlook.com,aol.com,icloud.com,protonmail.com,mail.com';
    
    WHILE i <= 5000 DO
        SET @first_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(first_names, ',', FLOOR(RAND() * 30) + 1), ',', -1));
        SET @last_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(last_names, ',', FLOOR(RAND() * 30) + 1), ',', -1));
        SET @domain = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(domains, ',', FLOOR(RAND() * 8) + 1), ',', -1));
        
        INSERT INTO customers (
            customer_code,
            first_name,
            last_name,
            email,
            phone,
            date_of_birth,
            gender,
            customer_type,
            registration_date
        ) VALUES (
            CONCAT('CUST-', LPAD(i, 6, '0')),
            @first_name,
            @last_name,
            CONCAT(LOWER(@first_name), '.', LOWER(@last_name), i, '@', @domain),
            CONCAT('+1-555-', LPAD(FLOOR(RAND() * 10000), 4, '0')),
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365 * 50) + 365 * 18 DAY),
            CASE FLOOR(RAND() * 3) WHEN 0 THEN 'M' WHEN 1 THEN 'F' ELSE 'Other' END,
            CASE FLOOR(RAND() * 10) WHEN 0 THEN 'VIP' WHEN 1 THEN 'Premium' ELSE 'Regular' END,
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365 * 3) DAY)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Procedimiento para insertar direcciones de clientes
DELIMITER //
CREATE PROCEDURE InsertCustomerAddresses()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE customer_id INT;
    DECLARE customer_cursor CURSOR FOR SELECT id FROM customers;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN customer_cursor;
    
    customer_loop: LOOP
        FETCH customer_cursor INTO customer_id;
        IF done THEN
            LEAVE customer_loop;
        END IF;
        
        -- Insertar dirección principal
        INSERT INTO customer_addresses (
            customer_id,
            address_type,
            street_address,
            city,
            state_province,
            postal_code,
            country,
            is_default
        ) VALUES (
            customer_id,
            'Both',
            CONCAT(FLOOR(RAND() * 9999) + 1, ' ', 
                CASE FLOOR(RAND() * 10)
                    WHEN 0 THEN 'Main Street'
                    WHEN 1 THEN 'Oak Avenue'
                    WHEN 2 THEN 'Pine Road'
                    WHEN 3 THEN 'Elm Drive'
                    WHEN 4 THEN 'Maple Lane'
                    WHEN 5 THEN 'Cedar Boulevard'
                    WHEN 6 THEN 'Birch Way'
                    WHEN 7 THEN 'Willow Court'
                    WHEN 8 THEN 'Spruce Circle'
                    ELSE 'Aspen Place'
                END
            ),
            CASE FLOOR(RAND() * 10)
                WHEN 0 THEN 'New York'
                WHEN 1 THEN 'Los Angeles'
                WHEN 2 THEN 'Chicago'
                WHEN 3 THEN 'Houston'
                WHEN 4 THEN 'Phoenix'
                WHEN 5 THEN 'Philadelphia'
                WHEN 6 THEN 'San Antonio'
                WHEN 7 THEN 'San Diego'
                WHEN 8 THEN 'Dallas'
                ELSE 'San Jose'
            END,
            CASE FLOOR(RAND() * 10)
                WHEN 0 THEN 'NY'
                WHEN 1 THEN 'CA'
                WHEN 2 THEN 'IL'
                WHEN 3 THEN 'TX'
                WHEN 4 THEN 'AZ'
                WHEN 5 THEN 'PA'
                WHEN 6 THEN 'TX'
                WHEN 7 THEN 'CA'
                WHEN 8 THEN 'TX'
                ELSE 'CA'
            END,
            LPAD(FLOOR(RAND() * 99999), 5, '0'),
            'USA',
            TRUE
        );
        
        -- 30% de probabilidad de tener una segunda dirección
        IF RAND() < 0.3 THEN
            INSERT INTO customer_addresses (
                customer_id,
                address_type,
                street_address,
                city,
                state_province,
                postal_code,
                country,
                is_default
            ) VALUES (
                customer_id,
                CASE FLOOR(RAND() * 2) WHEN 0 THEN 'Shipping' ELSE 'Billing' END,
                CONCAT(FLOOR(RAND() * 9999) + 1, ' Secondary Address'),
                'Secondary City',
                'SC',
                LPAD(FLOOR(RAND() * 99999), 5, '0'),
                'USA',
                FALSE
            );
        END IF;
    END LOOP;
    
    CLOSE customer_cursor;
END //
DELIMITER ;

-- Ejecutar procedimientos para insertar datos
CALL InsertSampleProducts();
CALL InsertSampleCustomers();
CALL InsertCustomerAddresses();

-- Limpiar procedimientos temporales
DROP PROCEDURE InsertSampleProducts;
DROP PROCEDURE InsertSampleCustomers;
DROP PROCEDURE InsertCustomerAddresses;

-- Insertar cupones de descuento
INSERT INTO discount_coupons (code, description, discount_type, discount_value, minimum_order_amount, usage_limit, valid_from, valid_until) VALUES
('WELCOME10', '10% discount for new customers', 'Percentage', 10.00, 50.00, 1000, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR)),
('SAVE20', '$20 off orders over $100', 'Fixed Amount', 20.00, 100.00, 500, NOW(), DATE_ADD(NOW(), INTERVAL 6 MONTH)),
('SUMMER15', '15% summer discount', 'Percentage', 15.00, 75.00, 2000, NOW(), DATE_ADD(NOW(), INTERVAL 3 MONTH)),
('BULK25', '$25 off bulk orders over $200', 'Fixed Amount', 25.00, 200.00, 100, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR)),
('LOYALTY5', '5% loyalty discount', 'Percentage', 5.00, 0.00, NULL, NOW(), DATE_ADD(NOW(), INTERVAL 2 YEAR));

-- Crear vista para reportes de ventas
CREATE VIEW sales_summary AS
SELECT 
    DATE(o.order_date) as sale_date,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value,
    COUNT(DISTINCT o.customer_id) as unique_customers
FROM orders o
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY DATE(o.order_date);

-- Crear vista para inventario bajo
CREATE VIEW low_stock_products AS
SELECT 
    p.id,
    p.sku,
    p.name,
    p.stock_quantity,
    p.min_stock_level,
    c.name as category_name,
    s.name as supplier_name
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN suppliers s ON p.supplier_id = s.id
WHERE p.stock_quantity <= p.min_stock_level
AND p.is_active = TRUE;

-- Crear función para calcular el total gastado por cliente
DELIMITER //
CREATE FUNCTION GetCustomerTotalSpent(customer_id INT) 
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(12,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(total_amount), 0.00) INTO total
    FROM orders 
    WHERE customer_id = customer_id 
    AND status IN ('Delivered', 'Shipped');
    
    RETURN total;
END //
DELIMITER ;

-- Crear procedimiento para actualizar estadísticas de clientes
DELIMITER //
CREATE PROCEDURE UpdateCustomerStats()
BEGIN
    UPDATE customers c
    SET 
        total_orders = (
            SELECT COUNT(*) 
            FROM orders o 
            WHERE o.customer_id = c.id 
            AND o.status IN ('Delivered', 'Shipped')
        ),
        total_spent = GetCustomerTotalSpent(c.id);
END //
DELIMITER ;

-- Crear trigger para actualizar stock después de una venta
DELIMITER //
CREATE TRIGGER update_stock_after_order
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE id = NEW.product_id;
    
    INSERT INTO inventory_movements (
        product_id, 
        movement_type, 
        quantity, 
        reference_type, 
        reference_id, 
        notes
    ) VALUES (
        NEW.product_id,
        'OUT',
        NEW.quantity,
        'Sale',
        NEW.order_id,
        CONCAT('Sale - Order Item ID: ', NEW.id)
    );
END //
DELIMITER ;

-- Mostrar estadísticas finales
SELECT 'Dataset Creation Summary' as info;
SELECT 'Categories' as table_name, COUNT(*) as record_count FROM categories
UNION ALL
SELECT 'Suppliers' as table_name, COUNT(*) as record_count FROM suppliers
UNION ALL
SELECT 'Products' as table_name, COUNT(*) as record_count FROM products
UNION ALL
SELECT 'Customers' as table_name, COUNT(*) as record_count FROM customers
UNION ALL
SELECT 'Customer Addresses' as table_name, COUNT(*) as record_count FROM customer_addresses
UNION ALL
SELECT 'Discount Coupons' as table_name, COUNT(*) as record_count FROM discount_coupons;

-- Mostrar información de tamaño de la base de datos
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.tables 
WHERE table_schema = 'ecommerce_lab'
ORDER BY (data_length + index_length) DESC;
