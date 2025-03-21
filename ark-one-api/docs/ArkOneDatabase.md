# Database Documentation

## 1. Introduction
This document describes the database structure, including tables, constraints, foreign keys, and record deletion behavior. Additionally, it includes a section for `CONSTRAINTS`.

## 2. Table Structure

### 2.1. Category (`category`)
Stores product categories, allowing a hierarchical structure.

- `id_category` (UUID, PK, DEFAULT gen_random_uuid())
- `id_father_category` (UUID, FK to `category(id_category)`, can be NULL)
- `category_name` (VARCHAR(50), UNIQUE, NOT NULL)
- `category_description` (VARCHAR(200))

**Deletion Rules:**
- If a parent category is deleted, its subcategories will have `id_father_category` set to `NULL`. (*ON DELETE SET NULL*)

---

### 2.2. Products (`products`)
Stores product information.

- `id_product` (UUID, PK, DEFAULT gen_random_uuid())
- `product_name` (VARCHAR(50), NOT NULL)
- `product_description` (VARCHAR(200))
- `id_category` (UUID, FK to `category(id_category)`, can be NULL)
- `location_dependent` (BOOLEAN, NOT NULL)
- `product_price` (DECIMAL(10, 2), NOT NULL)

**Deletion Rules:**
- If a category is deleted, associated products will have `id_category` set to `NULL`. (*ON DELETE SET NULL*)

---

### 2.3. Users (`user_data`)
Stores user data.

- `id_user` (UUID, PK, DEFAULT gen_random_uuid())
- `name` (VARCHAR(100), NOT NULL)
- `email` (VARCHAR(100), UNIQUE, NOT NULL)
- `password` (VARCHAR(60), NOT NULL)
- `user_type` (VARCHAR(20), DEFAULT 'regular', CHECK `('regular', 'admin', 'moderator')`)
- `registration_date` (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())

---

### 2.4. Product Instance (`product_instance`)
Associates a product with a user and an ESP32 device.

- `id_product_instance` (UUID, PK, DEFAULT gen_random_uuid())
- `id_product` (UUID, FK to `products(id_product)`, NOT NULL)
- `id_user` (UUID, FK to `user_data(id_user)`, NOT NULL)
- `esp32_unique_id` (VARCHAR(20), UNIQUE, NOT NULL)

**Deletion Rules:**
- If a product is deleted, all instances of that product will be deleted. (*ON DELETE CASCADE*)
- If a user is deleted, all associated product instances will be deleted. (*ON DELETE CASCADE*)

---

### 2.5. Location (`location_data`)
Stores product location information.

- `id_location` (UUID, PK, DEFAULT gen_random_uuid())
- `id_product_instance` (UUID, FK to `product_instance(id_product_instance)`, NOT NULL)
- `latitude` (DECIMAL(9, 6))
- `longitude` (DECIMAL(9, 6))

**Deletion Rules:**
- If a product instance is deleted, its location data will also be deleted. (*ON DELETE CASCADE*)

---

### 2.6. ESP32 Data (`esp32_data`)
Stores sensor data and other ESP32-related JSON data.

- `id_insertion` (UUID, PK, DEFAULT gen_random_uuid())
- `id_product_instance` (UUID, FK to `product_instance(id_product_instance)`, can be NULL)
- `common_data` (JSONB, NOT NULL)
- `product_specific_data` (JSONB)
- `created_at` (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())

**Deletion Rules:**
- If a product instance is deleted, associated data will also be deleted. (*ON DELETE CASCADE*)

---

### 2.7. User-Product Relationship (`user_products`)
Many-to-many relationship between users and products.

- `id_user` (UUID, FK to `user_data(id_user)`, NOT NULL)
- `id_product` (UUID, FK to `products(id_product)`, NOT NULL)

**Deletion Rules:**
- If a user is deleted, their product associations will be removed. (*ON DELETE CASCADE*)
- If a product is deleted, its associations with users will be removed. (*ON DELETE CASCADE*)

---

## 3. Indexes

Indexes are created to improve query performance by optimizing lookups on foreign keys and frequently queried fields.

### 3.1. Product Category Index (`idx_product_category`)
- **Table:** `products`
- **Column:** `id_category`
- **Purpose:** Speeds up queries filtering products by category.
- **Example Query:**
  ```sql
  SELECT * FROM products WHERE id_category = 'some-uuid';
  ```

---

### 3.2. Product Instance User Index (`idx_product_instance_user`)
- **Table:** `product_instance`
- **Column:** `id_user`
- **Purpose:** Enhances performance when retrieving all product instances associated with a user.
- **Example Query:**
  ```sql
  SELECT * FROM product_instance WHERE id_user = 'some-user-uuid';
  ```

---

### 3.3. Location Product Instance Index (`idx_location_product_instance`)
- **Table:** `location_data`
- **Column:** `id_product_instance`
- **Purpose:** Optimizes searches for the location of specific product instances.
- **Example Query:**
  ```sql
  SELECT * FROM location_data WHERE id_product_instance = 'some-instance-uuid';
  ```

---

### 3.4. ESP32 Data Product Instance Index (`idx_esp32_data_product_instance`)
- **Table:** `esp32_data`
- **Column:** `id_product_instance`
- **Purpose:** Improves retrieval of ESP32 data for specific product instances.
- **Example Query:**
  ```sql
  SELECT * FROM esp32_data WHERE id_product_instance = 'some-instance-uuid';
  ```

---

## 4. Deletion Behavior (`ON DELETE CASCADE` and `ON DELETE SET NULL`)
This table summarizes the effect of record deletion across different tables:

| Source Table | Affected Table | Action |
|--------------|---------------------|----------------|
| `category` | `products` | `id_category` → NULL |
| `category` | `category` (subcategories) | `id_father_category` → NULL |
| `products` | `product_instance` | DELETE |
| `products` | `user_products` | DELETE |
| `user_data` | `product_instance` | DELETE |
| `user_data` | `user_products` | DELETE |
| `product_instance` | `location_data` | DELETE |
| `product_instance` | `esp32_data` | DELETE |

## 5. Constraints

### 🔹 CHECK Constraints

---

**`chk_user_type_pd_values`**

- ***Table:*** user_data
- **Column:** `user_type`  
- ***Description:*** Ensures that the `user_type` column only contains one of the predefined values: 'regular', 'admin', or 'moderator'.
- ***Effect:*** Prevents invalid user roles from being inserted.

---

**`chk_valid_email`**

- ***Table:*** user_data
- **Column:** `email`  
- ***Description:*** Ensures that the `email` column contains a valid email address format using a regular expression.
- ***Effect:*** Prevents invalid email formats from being inserted into the table. This means that only emails that conform to the pattern `something@something.something` will be accepted.

---

**`chk_location_coordinates`**

- ***Table:*** location_data
- **Columns:** `latitude` `longitude`  
- ***Description:*** Ensures that both `latitude` and `longitude` are either provided together as valid coordinates or left NULL together. It verifies too if latitude is in between -90 AND 90 as well if longitude is between -180 and 180
- ***Effect:*** Prevents inconsistent location data (e.g., having a latitude without a longitude or invalid values).

### 🔹 UNIQUE Constraints

---

### **`user_data_email_key`**  
- **Table:** `user_data`  
- **Column:** `email`  
- **Description:** Ensures that no users have the same registered email.  
- **Effect:** Prevents the creation of users with duplicate emails.  

---

### **`category_category_name_key`**  
- **Table:** `category`  
- **Column:** `category_name`  
- **Description:** Ensures that each category has a unique name.  
- **Effect:** Prevents duplicate categories with the same name.  

---

### **`location_data_id_product_instance_key`**  
- **Table:** `location_data`  
- **Column:** `id_product_instance`  
- **Description:** Ensures that each product instance has at most one associated location entry.  
- **Effect:** Prevents multiple location records for the same product instance, enforcing a one-to-one relationship between `product_instance` and `location_data`.  

---

### **`product_instance_esp32_unique_id_key`**  
- **Table:** `product_instance`  
- **Column:** `esp32_unique_id`  
- **Description:** Ensures that each ESP32 has a unique identifier in the database.  
- **Effect:** Prevents the registration of a duplicate `esp32_unique_id`.  

---

### **`products_product_name_key`**  
- **Table:** `products`  
- **Column:** `product_name`  
- **Description:** Ensures that each product has a unique name.  
- **Effect:** Prevents the creation of multiple products with the same name, ensuring product names remain distinct.  

### 🔹 PRIMARY KEY Constraints

---

### **`user_data_pkey`**  
- **Table:** `user_data`  
- **Description:** Ensures that each user has a unique identifier (`id_user`).  
- **Effect:** Prevents the insertion of users with the same `id_user`, ensuring that each record in the `user_data` table has a unique identity.  

---

### **`category_pkey`**  
- **Table:** `category`  
- **Description:** Ensures that each category has a unique identifier (`id_category`).  
- **Effect:** Prevents ID duplication, ensuring that each category is unique within the table.  

---

### **`products_pkey`**  
- **Table:** `products`  
- **Description:** Ensures that each product has a unique identifier (`id_product`).  
- **Effect:** Prevents duplicate product records with the same ID.  

---

### **`product_instance_pkey`**  
- **Table:** `product_instance`  
- **Description:** Ensures that each product instance has a unique identifier (`id_product_instance`).  
- **Effect:** Guarantees that each product instance is unique and traceable.  

---

### **`location_data_pkey`**  
- **Table:** `location_data`  
- **Description:** Ensures that each location has a unique identifier (`id_location`).  
- **Effect:** Prevents duplicate entries in the location table.  

---

### **`esp32_data_pkey`**  
- **Table:** `esp32_data`  
- **Description:** Ensures that each ESP32 data entry has a unique identifier (`id_insertion`).  
- **Effect:** Maintains data integrity and prevents duplicate records.  

---

### **`user_products_pkey`**  
- **Table:** `user_products`  
- **Description:** Ensures that the relationship between users and products is unique.  
- **Effect:** Since the primary key is composed of `(id_user, id_product)`, it prevents the same user from having a product listed more than once in the table.  

### 🔹 FOREIGN KEY Violations

---

### **`fk_category_parent`**  
- **Table:** `category`  
- **References:** `category(id_category)`  
- **Description:** Ensures that the parent category (`id_father_category`) references an existing category.  
- **Effect:** Prevents the insertion of a non-existent `id_father_category`.  

---

### **`fk_products_to_category`**  
- **Table:** `products`  
- **References:** `category(id_category)`  
- **Description:** Ensures that each product is linked to a valid category.  
- **Effect:** Prevents the insertion of a product with a non-existent `id_category`.  

---

### **`fk_product_instance_to_products`**  
- **Table:** `product_instance`  
- **References:** `products(id_product)`  
- **Description:** Ensures that each product instance is associated with an existing product.  
- **Effect:** Prevents product instances that do not exist in the `products` table.  

---

### **`fk_product_instance_to_user_data`**  
- **Table:** `product_instance`  
- **References:** `user_data(id_user)`  
- **Description:** Ensures that each product instance belongs to a valid user.  
- **Effect:** Prevents product records for non-existent users.  

---

### **`fk_location_data_to_product_instance`**  
- **Table:** `location_data`  
- **References:** `product_instance(id_product_instance)`  
- **Description:** Ensures that each location belongs to an existing `id_product_instance`.  
- **Effect:** Prevents the creation of location data for non-existent product instances.  

---

### **`fk_esp32_data_to_product_instance`**  
- **Table:** `esp32_data`  
- **References:** `product_instance(id_product_instance)`  
- **Description:** Ensures that the data collected from ESP32 is linked to a valid product instance.  
- **Effect:** Prevents the storage of data without a corresponding product instance.  

---

### **`fk_user_products_to_user`**  
- **Table:** `user_products`  
- **References:** `user_data(id_user)`  
- **Description:** Ensures that each entry in `user_products` has a valid user.  
- **Effect:** Prevents the association of products with non-existent users.  

---

### **`fk_user_products_to_products`**  
- **Table:** `user_products`  
- **References:** `products(id_product)`  
- **Description:** Ensures that each entry in `user_products` has a valid product.  
- **Effect:** Prevents records of products that do not exist in the `products` table.  