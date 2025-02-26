# Constraints

## CHECK Constraints Summary

**`chk_user_type_pd_values`**

***Table:*** user_data

***Description:*** Ensures that the `user_type` column only contains one of the predefined values: 'regular', 'admin', or 'moderator'.

***Effect:*** Prevents invalid user roles from being inserted.

---

**`chk_valid_email`**

***Table:*** user_data

***Description:*** Ensures that the `email` column contains a valid email address format using a regular expression.

***Effect:*** Prevents invalid email formats from being inserted into the table. This means that only emails that conform to the pattern `something@something.something` will be accepted.

---

**`chk_location_coordinates`**

***Table:*** location_data

***Description:*** Ensures that both `latitude` and `longitude` are either provided together as valid coordinates or left NULL together.

***Effect:*** Prevents inconsistent location data (e.g., having a latitude without a longitude).

---

## FOREIGN KEY Constraints Summary  

**`fk_category_parent`**  

***Table:*** category  

***Description:*** Establishes a self-referencing relationship, linking a category to its parent category.  

***Effect:*** Allows hierarchical categorization by enabling subcategories. If the parent category is deleted, its reference is set to `NULL`.  

---  

**`fk_products_to_category`**  

***Table:*** products  

***Description:*** Links each product to a category in the `category` table.  

***Effect:*** Maintains referential integrity between products and categories. If a category is deleted, the product's category reference is set to `NULL`.  

---  

**`fk_product_instance_to_products`**  

***Table:*** product_instance  

***Description:*** Associates a specific product instance with a product in the `products` table.  

***Effect:*** Ensures that every product instance corresponds to an existing product. If a product is deleted, all its instances are also deleted.  

---  

**`fk_product_instance_to_user_data`**  

***Table:*** product_instance  

***Description:*** Associates a product instance with a user in the `user_data` table.  

***Effect:*** Ensures that each product instance is owned by a valid user. If a user is deleted, their product instances are also deleted.  

---  

**`fk_location_data_to_product_instance`**  

***Table:*** location_data  

***Description:*** Links a location entry to a product instance in the `product_instance` table.  

***Effect:*** Ensures that location data is always tied to an existing product instance. If a product instance is deleted, its location data is also deleted.  

---  

**`fk_esp32_data_to_product_instance`**  

***Table:*** esp32_data  

***Description:*** Associates ESP32 sensor data with a specific product instance in the `product_instance` table.  

***Effect:*** Ensures that ESP32 data belongs to a valid product instance. If a product instance is deleted, its ESP32 data is also deleted.  

---  

**`fk_user_products_to_user`**  

***Table:*** user_products  

***Description:*** Establishes a many-to-many relationship between users and products by linking a user to a product.  

***Effect:*** Ensures that every user-product association belongs to an existing user. If a user is deleted, their product associations are also deleted.  

---  

**`fk_user_products_to_products`**  

***Table:*** user_products  

***Description:*** Establishes a many-to-many relationship between users and products by linking a product to a user.  

***Effect:*** Ensures that every user-product association belongs to an existing product. If a product is deleted, its user associations are also deleted.  

---