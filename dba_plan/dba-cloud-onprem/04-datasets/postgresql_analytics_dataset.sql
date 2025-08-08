-- PostgreSQL Analytics Dataset para Laboratorios DBA
-- Versión: 1.0
-- Descripción: Dataset realista para análisis, reportes y administración PostgreSQL
-- Tamaño aproximado: 30MB de datos

-- Conectar a la base de datos (ejecutar como superusuario)
-- \c postgres

-- Crear base de datos
CREATE DATABASE analytics_lab WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Conectar a la nueva base de datos
\c analytics_lab

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Tabla de regiones
CREATE TABLE regions (
    id SERIAL PRIMARY KEY,
    region_code VARCHAR(10) UNIQUE NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de tiendas
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    store_code VARCHAR(20) UNIQUE NOT NULL,
    store_name VARCHAR(200) NOT NULL,
    region_id INTEGER NOT NULL REFERENCES regions(id),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    manager_name VARCHAR(100),
    opening_date DATE,
    store_size_sqm DECIMAL(10,2),
    employee_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para stores
CREATE INDEX idx_stores_region ON stores(region_id);
CREATE INDEX idx_stores_city ON stores(city);
CREATE INDEX idx_stores_active ON stores(is_active);
CREATE INDEX idx_stores_opening_date ON stores(opening_date);

-- Tabla de categorías de productos
CREATE TABLE product_categories (
    id SERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_id INTEGER REFERENCES product_categories(id),
    description TEXT,
    margin_percentage DECIMAL(5,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de productos
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(30) UNIQUE NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES product_categories(id),
    brand VARCHAR(100),
    supplier VARCHAR(200),
    cost_price DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    weight_kg DECIMAL(8,3),
    dimensions JSONB,
    attributes JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para products
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_price ON products(selling_price);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_attributes ON products USING GIN(attributes);

-- Tabla de empleados
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    store_id INTEGER NOT NULL REFERENCES stores(id),
    position VARCHAR(100),
    department VARCHAR(100),
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    commission_rate DECIMAL(5,4) DEFAULT 0.0000,
    manager_id INTEGER REFERENCES employees(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para employees
CREATE INDEX idx_employees_store ON employees(store_id);
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
CREATE INDEX idx_employees_active ON employees(is_active);

-- Tabla de clientes
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    region_id INTEGER REFERENCES regions(id),
    registration_date DATE DEFAULT CURRENT_DATE,
    customer_segment VARCHAR(50) DEFAULT 'Regular',
    loyalty_points INTEGER DEFAULT 0,
    total_purchases DECIMAL(12,2) DEFAULT 0.00,
    last_purchase_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para customers
CREATE INDEX idx_customers_region ON customers(region_id);
CREATE INDEX idx_customers_city ON customers(city);
CREATE INDEX idx_customers_segment ON customers(customer_segment);
CREATE INDEX idx_customers_registration ON customers(registration_date);
CREATE INDEX idx_customers_last_purchase ON customers(last_purchase_date);

-- Tabla de ventas (transacciones)
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(30) UNIQUE NOT NULL,
    store_id INTEGER NOT NULL REFERENCES stores(id),
    employee_id INTEGER REFERENCES employees(id),
    customer_id INTEGER REFERENCES customers(id),
    sale_date DATE NOT NULL,
    sale_time TIME NOT NULL,
    sale_datetime TIMESTAMP NOT NULL,
    payment_method VARCHAR(50),
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL,
    items_count INTEGER NOT NULL,
    is_return BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para sales
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_employee ON sales(employee_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_datetime ON sales(sale_datetime);
CREATE INDEX idx_sales_payment_method ON sales(payment_method);
CREATE INDEX idx_sales_total ON sales(total_amount);
CREATE INDEX idx_sales_return ON sales(is_return);

-- Tabla de detalles de ventas
CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0.00,
    line_total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para sale_items
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);
CREATE INDEX idx_sale_items_created ON sale_items(created_at);

-- Tabla de inventario por tienda
CREATE TABLE store_inventory (
    id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    current_stock INTEGER NOT NULL DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    max_stock_level INTEGER DEFAULT 1000,
    last_restock_date DATE,
    last_sale_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(store_id, product_id)
);

-- Índices para store_inventory
CREATE INDEX idx_inventory_store ON store_inventory(store_id);
CREATE INDEX idx_inventory_product ON store_inventory(product_id);
CREATE INDEX idx_inventory_stock_level ON store_inventory(current_stock);
CREATE INDEX idx_inventory_restock ON store_inventory(last_restock_date);

-- Tabla de promociones
CREATE TABLE promotions (
    id SERIAL PRIMARY KEY,
    promotion_code VARCHAR(50) UNIQUE NOT NULL,
    promotion_name VARCHAR(200) NOT NULL,
    description TEXT,
    promotion_type VARCHAR(50), -- 'Discount', 'BOGO', 'Bundle', etc.
    discount_percentage DECIMAL(5,2),
    discount_amount DECIMAL(10,2),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    applicable_products INTEGER[], -- Array of product IDs
    applicable_categories INTEGER[], -- Array of category IDs
    min_purchase_amount DECIMAL(10,2) DEFAULT 0.00,
    usage_limit INTEGER,
    used_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para promotions
CREATE INDEX idx_promotions_dates ON promotions(start_date, end_date);
CREATE INDEX idx_promotions_active ON promotions(is_active);
CREATE INDEX idx_promotions_products ON promotions USING GIN(applicable_products);
CREATE INDEX idx_promotions_categories ON promotions USING GIN(applicable_categories);

-- Insertar datos de regiones
INSERT INTO regions (region_code, region_name, country, timezone) VALUES
('US-NE', 'Northeast', 'United States', 'America/New_York'),
('US-SE', 'Southeast', 'United States', 'America/New_York'),
('US-MW', 'Midwest', 'United States', 'America/Chicago'),
('US-SW', 'Southwest', 'United States', 'America/Denver'),
('US-W', 'West', 'United States', 'America/Los_Angeles'),
('CA-E', 'Eastern Canada', 'Canada', 'America/Toronto'),
('CA-W', 'Western Canada', 'Canada', 'America/Vancouver'),
('MX-N', 'Northern Mexico', 'Mexico', 'America/Mexico_City');

-- Insertar categorías de productos
INSERT INTO product_categories (category_code, category_name, parent_id, margin_percentage) VALUES
('ELEC', 'Electronics', NULL, 25.00),
('COMP', 'Computers', 1, 20.00),
('PHONE', 'Mobile Phones', 1, 30.00),
('AUDIO', 'Audio Equipment', 1, 35.00),
('HOME', 'Home & Garden', NULL, 40.00),
('FURN', 'Furniture', 5, 45.00),
('APPL', 'Appliances', 5, 25.00),
('CLOTH', 'Clothing', NULL, 60.00),
('MENS', 'Men\'s Clothing', 8, 55.00),
('WOMENS', 'Women\'s Clothing', 8, 65.00),
('SPORTS', 'Sports & Outdoors', NULL, 50.00),
('FITNESS', 'Fitness Equipment', 11, 45.00),
('BOOKS', 'Books & Media', NULL, 40.00),
('HEALTH', 'Health & Beauty', NULL, 70.00),
('AUTO', 'Automotive', NULL, 30.00);

-- Función para generar datos de tiendas
CREATE OR REPLACE FUNCTION generate_stores() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    region_id INTEGER;
    cities TEXT[] := ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville', 'Fort Worth', 'Columbus', 'Charlotte', 'San Francisco', 'Indianapolis', 'Seattle', 'Denver', 'Washington'];
BEGIN
    FOR i IN 1..100 LOOP
        SELECT id INTO region_id FROM regions ORDER BY RANDOM() LIMIT 1;
        
        INSERT INTO stores (
            store_code,
            store_name,
            region_id,
            address,
            city,
            postal_code,
            phone,
            email,
            manager_name,
            opening_date,
            store_size_sqm,
            employee_count
        ) VALUES (
            'ST-' || LPAD(i::TEXT, 4, '0'),
            'Store ' || i || ' - ' || cities[1 + (i % array_length(cities, 1))],
            region_id,
            (100 + (i * 17) % 9900)::TEXT || ' Commerce Street',
            cities[1 + (i % array_length(cities, 1))],
            LPAD((10000 + (i * 123) % 89999)::TEXT, 5, '0'),
            '+1-555-' || LPAD((1000 + (i * 7) % 8999)::TEXT, 4, '0'),
            'store' || i || '@company.com',
            CASE (i % 10)
                WHEN 0 THEN 'John Smith'
                WHEN 1 THEN 'Jane Doe'
                WHEN 2 THEN 'Mike Johnson'
                WHEN 3 THEN 'Sarah Wilson'
                WHEN 4 THEN 'David Brown'
                WHEN 5 THEN 'Lisa Davis'
                WHEN 6 THEN 'Robert Miller'
                WHEN 7 THEN 'Jennifer Garcia'
                WHEN 8 THEN 'William Jones'
                ELSE 'Mary Taylor'
            END,
            CURRENT_DATE - INTERVAL '1 day' * (30 + (i * 11) % 1800),
            500.0 + (i * 23.7) % 2000,
            5 + (i % 20)
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Función para generar productos
CREATE OR REPLACE FUNCTION generate_products() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    cat_id INTEGER;
    product_names TEXT[] := ARRAY['Premium', 'Standard', 'Deluxe', 'Professional', 'Home', 'Business', 'Economy', 'Advanced', 'Compact', 'Special'];
    brands TEXT[] := ARRAY['TechCorp', 'GlobalBrand', 'QualityMaker', 'InnovateCo', 'ReliableTech', 'ModernDesign', 'SmartChoice', 'ValueBrand'];
BEGIN
    FOR i IN 1..2000 LOOP
        SELECT id INTO cat_id FROM product_categories WHERE parent_id IS NOT NULL ORDER BY RANDOM() LIMIT 1;
        
        INSERT INTO products (
            product_code,
            product_name,
            category_id,
            brand,
            supplier,
            cost_price,
            selling_price,
            weight_kg,
            dimensions,
            attributes
        ) VALUES (
            'PRD-' || LPAD(i::TEXT, 6, '0'),
            product_names[1 + (i % array_length(product_names, 1))] || ' Product ' || i,
            cat_id,
            brands[1 + (i % array_length(brands, 1))],
            'Supplier ' || (1 + (i % 50)),
            ROUND((10 + (i * 1.7) % 500)::NUMERIC, 2),
            ROUND((15 + (i * 2.3) % 800)::NUMERIC, 2),
            ROUND((0.1 + (i * 0.05) % 20)::NUMERIC, 3),
            jsonb_build_object(
                'length', ROUND((5 + (i * 0.3) % 50)::NUMERIC, 1),
                'width', ROUND((3 + (i * 0.2) % 30)::NUMERIC, 1),
                'height', ROUND((2 + (i * 0.1) % 20)::NUMERIC, 1)
            ),
            jsonb_build_object(
                'color', CASE (i % 5) WHEN 0 THEN 'Black' WHEN 1 THEN 'White' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Blue' ELSE 'Red' END,
                'warranty_months', 12 + (i % 24),
                'energy_rating', CASE (i % 5) WHEN 0 THEN 'A++' WHEN 1 THEN 'A+' WHEN 2 THEN 'A' WHEN 3 THEN 'B' ELSE 'C' END
            )
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Función para generar empleados
CREATE OR REPLACE FUNCTION generate_employees() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    store_id INTEGER;
    first_names TEXT[] := ARRAY['John', 'Jane', 'Michael', 'Sarah', 'David', 'Lisa', 'Robert', 'Jennifer', 'William', 'Mary', 'James', 'Patricia', 'Christopher', 'Linda', 'Daniel', 'Barbara'];
    last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas'];
    positions TEXT[] := ARRAY['Sales Associate', 'Cashier', 'Department Manager', 'Assistant Manager', 'Store Manager', 'Stock Clerk', 'Customer Service', 'Security Guard'];
    departments TEXT[] := ARRAY['Sales', 'Customer Service', 'Inventory', 'Management', 'Security', 'Maintenance'];
BEGIN
    FOR i IN 1..500 LOOP
        SELECT id INTO store_id FROM stores ORDER BY RANDOM() LIMIT 1;
        
        INSERT INTO employees (
            employee_id,
            first_name,
            last_name,
            email,
            phone,
            store_id,
            position,
            department,
            hire_date,
            salary,
            commission_rate
        ) VALUES (
            'EMP-' || LPAD(i::TEXT, 5, '0'),
            first_names[1 + (i % array_length(first_names, 1))],
            last_names[1 + (i % array_length(last_names, 1))],
            'employee' || i || '@company.com',
            '+1-555-' || LPAD((2000 + (i * 13) % 7999)::TEXT, 4, '0'),
            store_id,
            positions[1 + (i % array_length(positions, 1))],
            departments[1 + (i % array_length(departments, 1))],
            CURRENT_DATE - INTERVAL '1 day' * (1 + (i * 7) % 1095),
            25000 + (i * 500) % 75000,
            CASE WHEN (i % 3) = 0 THEN 0.02 ELSE 0.00 END
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Función para generar clientes
CREATE OR REPLACE FUNCTION generate_customers() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    region_id INTEGER;
    first_names TEXT[] := ARRAY['John', 'Jane', 'Michael', 'Sarah', 'David', 'Lisa', 'Robert', 'Jennifer', 'William', 'Mary', 'James', 'Patricia', 'Christopher', 'Linda', 'Daniel', 'Barbara', 'Matthew', 'Elizabeth', 'Anthony', 'Helen'];
    last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin'];
    segments TEXT[] := ARRAY['Regular', 'Premium', 'VIP', 'New'];
    cities TEXT[] := ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'];
BEGIN
    FOR i IN 1..10000 LOOP
        SELECT id INTO region_id FROM regions ORDER BY RANDOM() LIMIT 1;
        
        INSERT INTO customers (
            customer_id,
            first_name,
            last_name,
            email,
            phone,
            date_of_birth,
            gender,
            address,
            city,
            postal_code,
            region_id,
            registration_date,
            customer_segment,
            loyalty_points
        ) VALUES (
            'CUST-' || LPAD(i::TEXT, 6, '0'),
            first_names[1 + (i % array_length(first_names, 1))],
            last_names[1 + (i % array_length(last_names, 1))],
            'customer' || i || '@email.com',
            '+1-555-' || LPAD((3000 + (i * 17) % 6999)::TEXT, 4, '0'),
            CURRENT_DATE - INTERVAL '1 day' * (6570 + (i * 19) % 18250), -- Age 18-68
            CASE (i % 3) WHEN 0 THEN 'Male' WHEN 1 THEN 'Female' ELSE 'Other' END,
            (100 + (i * 23) % 9900)::TEXT || ' Customer Street',
            cities[1 + (i % array_length(cities, 1))],
            LPAD((10000 + (i * 137) % 89999)::TEXT, 5, '0'),
            region_id,
            CURRENT_DATE - INTERVAL '1 day' * (1 + (i * 3) % 730),
            segments[1 + (i % array_length(segments, 1))],
            (i * 7) % 5000
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar funciones para generar datos
SELECT generate_stores();
SELECT generate_products();
SELECT generate_employees();
SELECT generate_customers();

-- Limpiar funciones temporales
DROP FUNCTION generate_stores();
DROP FUNCTION generate_products();
DROP FUNCTION generate_employees();
DROP FUNCTION generate_customers();

-- Generar inventario inicial
INSERT INTO store_inventory (store_id, product_id, current_stock, min_stock_level, max_stock_level, last_restock_date)
SELECT 
    s.id as store_id,
    p.id as product_id,
    (10 + (s.id * p.id * 7) % 100) as current_stock,
    (5 + (s.id * p.id * 3) % 20) as min_stock_level,
    (100 + (s.id * p.id * 11) % 500) as max_stock_level,
    CURRENT_DATE - INTERVAL '1 day' * ((s.id * p.id * 13) % 90)
FROM stores s
CROSS JOIN products p
WHERE (s.id * p.id) % 10 < 7; -- 70% de productos por tienda

-- Crear vistas útiles para análisis
CREATE VIEW sales_by_region AS
SELECT 
    r.region_name,
    r.country,
    COUNT(DISTINCT s.id) as store_count,
    COUNT(DISTINCT e.id) as employee_count,
    COUNT(DISTINCT c.id) as customer_count
FROM regions r
LEFT JOIN stores s ON r.id = s.region_id
LEFT JOIN employees e ON s.id = e.store_id
LEFT JOIN customers c ON r.id = c.region_id
GROUP BY r.id, r.region_name, r.country;

CREATE VIEW product_performance AS
SELECT 
    p.product_code,
    p.product_name,
    pc.category_name,
    p.brand,
    p.selling_price,
    COUNT(si.id) as total_sales,
    SUM(si.quantity) as total_quantity_sold,
    SUM(si.line_total) as total_revenue,
    AVG(si.unit_price) as avg_selling_price
FROM products p
JOIN product_categories pc ON p.category_id = pc.id
LEFT JOIN sale_items si ON p.id = si.product_id
GROUP BY p.id, p.product_code, p.product_name, pc.category_name, p.brand, p.selling_price;

CREATE VIEW low_stock_alert AS
SELECT 
    s.store_name,
    p.product_name,
    p.product_code,
    si.current_stock,
    si.min_stock_level,
    (si.min_stock_level - si.current_stock) as stock_deficit
FROM store_inventory si
JOIN stores s ON si.store_id = s.id
JOIN products p ON si.product_id = p.id
WHERE si.current_stock <= si.min_stock_level;

-- Crear funciones útiles
CREATE OR REPLACE FUNCTION get_store_revenue(store_id INTEGER, start_date DATE, end_date DATE)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    revenue DECIMAL(12,2);
BEGIN
    SELECT COALESCE(SUM(total_amount), 0.00) INTO revenue
    FROM sales s
    WHERE s.store_id = $1
    AND s.sale_date BETWEEN start_date AND end_date
    AND s.is_return = FALSE;
    
    RETURN revenue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS VOID AS $$
BEGIN
    UPDATE customers c
    SET 
        total_purchases = COALESCE(subq.total, 0.00),
        last_purchase_date = subq.last_date
    FROM (
        SELECT 
            s.customer_id,
            SUM(s.total_amount) as total,
            MAX(s.sale_date) as last_date
        FROM sales s
        WHERE s.is_return = FALSE
        GROUP BY s.customer_id
    ) subq
    WHERE c.id = subq.customer_id;
END;
$$ LANGUAGE plpgsql;

-- Insertar algunas promociones
INSERT INTO promotions (promotion_code, promotion_name, description, promotion_type, discount_percentage, start_date, end_date, min_purchase_amount) VALUES
('SUMMER2024', 'Summer Sale 2024', '20% off all electronics', 'Discount', 20.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 100.00),
('NEWCUSTOMER', 'New Customer Discount', '15% off first purchase', 'Discount', 15.00, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '60 days', 50.00),
('BULK10', 'Bulk Purchase Discount', '10% off orders over $500', 'Discount', 10.00, CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE + INTERVAL '90 days', 500.00);

-- Mostrar estadísticas del dataset
SELECT 'Dataset Creation Summary' as info;

SELECT 
    'regions' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('regions')) as table_size
FROM regions
UNION ALL
SELECT 
    'stores' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('stores')) as table_size
FROM stores
UNION ALL
SELECT 
    'product_categories' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('product_categories')) as table_size
FROM product_categories
UNION ALL
SELECT 
    'products' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('products')) as table_size
FROM products
UNION ALL
SELECT 
    'employees' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('employees')) as table_size
FROM employees
UNION ALL
SELECT 
    'customers' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('customers')) as table_size
FROM customers
UNION ALL
SELECT 
    'store_inventory' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('store_inventory')) as table_size
FROM store_inventory
UNION ALL
SELECT 
    'promotions' as table_name, 
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('promotions')) as table_size
FROM promotions;

-- Mostrar tamaño total de la base de datos
SELECT 
    pg_database.datname as database_name,
    pg_size_pretty(pg_database_size(pg_database.datname)) as database_size
FROM pg_database 
WHERE datname = 'analytics_lab';
