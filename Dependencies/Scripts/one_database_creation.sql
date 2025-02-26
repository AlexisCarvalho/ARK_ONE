-- Create the category table to store product categories
CREATE TABLE category (
    id_category SERIAL PRIMARY KEY,
    id_father_category INT,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    category_description VARCHAR(200),
    
    CONSTRAINT fk_category_parent 
    	FOREIGN KEY (id_father_category) REFERENCES category(id_category) ON DELETE SET NULL  -- Optional reference to parent category
);

-- Create the products table to store product information
CREATE TABLE products (
    id_product SERIAL PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    product_description VARCHAR(200),
    id_category INT,  -- Allowing NULL for products without a category
    location_dependent BOOLEAN NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL,  -- Column for product price
    
    CONSTRAINT fk_products_to_category 
    	FOREIGN KEY (id_category) REFERENCES category(id_category) ON DELETE SET NULL  -- Reference to product category
);

-- Create the user_data table to store user information
CREATE TABLE user_data (
    id_user SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    user_type VARCHAR(20) DEFAULT 'regular',
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT chk_user_type_pd_values 
    	CHECK (user_type IN ('regular', 'admin', 'moderator'))  
);


-- Create the product_instance table to store instances of products owned by users
CREATE TABLE product_instance (
    id_product_instance SERIAL PRIMARY KEY,  -- Unique ID for each product instance
    id_product INT NOT NULL,
    id_user INT NOT NULL,
    esp32_unique_id VARCHAR(20) NOT NULL UNIQUE,  -- Unique identifier for the ESP32 device
    
    CONSTRAINT fk_product_instance_to_products 
    	FOREIGN KEY (id_product) REFERENCES products(id_product) ON DELETE CASCADE,  -- Reference to the product
    CONSTRAINT fk_product_instance_to_user_data 
    	FOREIGN KEY (id_user) REFERENCES user_data(id_user) ON DELETE CASCADE  -- Reference to the user who owns this product instance
);

-- Create the location_data table to store geographical information related to product instances
CREATE TABLE location_data (
    id_location SERIAL PRIMARY KEY,  -- Unique ID for each location entry
    id_product_instance INT,
    latitude DECIMAL(9, 6),  -- Latitude for location-dependent products
    longitude DECIMAL(9, 6), -- Longitude for location-dependent products
    
    CONSTRAINT chk_lat_lon_mandatory_together 
    	CHECK (latitude IS NOT NULL AND longitude IS NOT NULL OR latitude IS NULL AND longitude IS NULL),  -- Ensure both or none are provided
    CONSTRAINT fk_location_data_to_product_instance 
    	FOREIGN KEY (id_product_instance) REFERENCES product_instance(id_product_instance) ON DELETE CASCADE  -- Link to product instance
);

-- Create the esp32_data table to store general ESP32 data with JSON fields for product-specific values
CREATE TABLE esp32_data (
    id_insertion SERIAL PRIMARY KEY,  -- Unique ID for each insertion
    id_product_instance INT,
    common_data JSONB NOT NULL,  -- Store common fields like voltage, current in JSON
    product_specific_data JSONB,  -- Store product-specific fields in JSON
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  -- Automatically track when the data is inserted
    
    CONSTRAINT fk_esp32_data_to_product_instance 
    	FOREIGN KEY (id_product_instance) REFERENCES product_instance(id_product_instance) ON DELETE CASCADE  -- Link to product instance
);

-- Create the user_products table to store which users own which products (many-to-many relationship)
CREATE TABLE user_products (
    id_user INT,
    id_product INT,
    
    PRIMARY KEY (id_user, id_product),  -- Composite primary key to ensure uniqueness
    CONSTRAINT fk_user_products_to_user 
    	FOREIGN KEY (id_user) REFERENCES user_data(id_user) ON DELETE CASCADE,
    CONSTRAINT fk_user_products_to_products 
    	FOREIGN KEY (id_product) REFERENCES products(id_product) ON DELETE CASCADE
);

-- To test the admin temporary page you need to set the user_type from here
UPDATE user_data SET user_type = 'admin' WHERE id_user = $1;