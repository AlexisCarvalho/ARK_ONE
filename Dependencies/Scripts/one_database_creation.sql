-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create the category table to store product categories
CREATE TABLE category (
    id_category UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_father_category UUID, -- Parent category UUID (nullable)
    category_name VARCHAR(50) UNIQUE NOT NULL,
    category_description VARCHAR(200),

    CONSTRAINT fk_category_parent 
        FOREIGN KEY (id_father_category) REFERENCES category(id_category) ON DELETE SET NULL
);

-- Create the products table to store product information
CREATE TABLE products (
    id_product UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_name VARCHAR(50) UNIQUE NOT NULL,
    product_description VARCHAR(200),
    id_category UUID, -- Foreign key to category
    location_dependent BOOLEAN NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL, 

    CONSTRAINT fk_products_to_category 
        FOREIGN KEY (id_category) REFERENCES category(id_category) ON DELETE SET NULL
);

-- Create the user_data table to store user information
CREATE TABLE user_data (
    id_user UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(60) NOT NULL,
    user_role VARCHAR(20) DEFAULT 'moderator',
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT chk_user_role_pd_values 
        CHECK (user_role IN ('analyst', 'moderator', 'admin')),

    CONSTRAINT chk_valid_email 
        CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE user_affiliations (
    id_analyst UUID,
    id_owner UUID,

    PRIMARY KEY (id_analyst, id_owner),
    CONSTRAINT chk_analyst_not_owner
        CHECK (id_analyst <> id_owner),
    CONSTRAINT fk_user_affiliations_analyst_to_user 
        FOREIGN KEY (id_analyst) REFERENCES user_data(id_user) ON DELETE CASCADE,
    CONSTRAINT fk_user_affiliations_owner_to_user 
        FOREIGN KEY (id_owner) REFERENCES user_data(id_user) ON DELETE CASCADE
);

-- Create the product_instance table to store instances of products owned by users
CREATE TABLE product_instance (
    id_product_instance UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_product UUID NOT NULL,
    id_user UUID NOT NULL,
    esp32_unique_id VARCHAR(20) NOT NULL UNIQUE,  -- Unique identifier for the ESP32 device
    
    CONSTRAINT fk_product_instance_to_products 
        FOREIGN KEY (id_product) REFERENCES products(id_product) ON DELETE CASCADE,
    CONSTRAINT fk_product_instance_to_user_data 
        FOREIGN KEY (id_user) REFERENCES user_data(id_user) ON DELETE CASCADE
);

-- Create the location_data table to store geographical information related to product instances
CREATE TABLE location_data (
    id_location UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_product_instance UUID UNIQUE NOT NULL,
    latitude DECIMAL(9, 6),  -- Latitude for location-dependent products
    longitude DECIMAL(9, 6), -- Longitude for location-dependent products

    CONSTRAINT chk_location_coordinates 
        CHECK (
            (latitude IS NULL AND longitude IS NULL) OR 
            (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        ),
    
    CONSTRAINT fk_location_data_to_product_instance 
        FOREIGN KEY (id_product_instance) REFERENCES product_instance(id_product_instance) ON DELETE CASCADE
);

-- Create the esp32_data table to store general ESP32 data with JSON fields for product-specific values
CREATE TABLE esp32_data (
    id_insertion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_product_instance UUID,
    common_data JSONB NOT NULL,  -- Store common fields like voltage, current in JSON
    product_specific_data JSONB,  -- Store product-specific fields in JSON
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_esp32_data_to_product_instance 
        FOREIGN KEY (id_product_instance) REFERENCES product_instance(id_product_instance) ON DELETE CASCADE
);

-- Create the user_products table to store which users own which products (many-to-many relationship)
CREATE TABLE user_products (
    id_user UUID,
    id_product UUID,

    PRIMARY KEY (id_user, id_product),
    CONSTRAINT fk_user_products_to_user 
        FOREIGN KEY (id_user) REFERENCES user_data(id_user) ON DELETE CASCADE,
    CONSTRAINT fk_user_products_to_products 
        FOREIGN KEY (id_product) REFERENCES products(id_product) ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION insert_user_product()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_products (id_user, id_product)
    VALUES (NEW.id_user, NEW.id_product)
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_insert_user_product
AFTER INSERT ON product_instance
FOR EACH ROW
EXECUTE FUNCTION insert_user_product();

CREATE OR REPLACE FUNCTION get_esp32_data_today(instance_id UUID)
RETURNS TABLE (
  id_insertion UUID,
  id_product_instance UUID,
  common_data JSONB,
  product_specific_data JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT e.id_insertion, e.id_product_instance, e.common_data, e.product_specific_data, e.created_at
  FROM esp32_data e
  WHERE e.id_product_instance = instance_id
    AND e.created_at::date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_esp32_data_week(instance_id UUID)
RETURNS TABLE (
  id_insertion UUID,
  id_product_instance UUID,
  common_data JSONB,
  product_specific_data JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT e.id_insertion, e.id_product_instance, e.common_data, e.product_specific_data, e.created_at
  FROM esp32_data e
  WHERE e.id_product_instance = instance_id
    AND e.created_at::date >= date_trunc('week', CURRENT_DATE)
    AND e.created_at::date < date_trunc('week', CURRENT_DATE) + INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Indexes to improve performance on foreign key lookups
CREATE INDEX idx_product_category ON products(id_category);
CREATE INDEX idx_product_instance_user ON product_instance(id_user);
CREATE INDEX idx_location_product_instance ON location_data(id_product_instance);
CREATE INDEX idx_esp32_data_product_instance ON esp32_data(id_product_instance);