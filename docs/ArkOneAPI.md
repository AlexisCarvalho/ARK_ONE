# Possible Returns
## Success Indicators:

- **`success:`** Indicates that the operation was completed successfully. REF 200, 204 ✅
- **`created:`** Used when a new resource (e.g., user) has been successfully created. REF 201 🆕
- **`updated:`** Indicates that an existing resource has been successfully updated. REF 200, 204 🔄

## Client Error Indicators:

- **`bad_request:`** The request was invalid or malformed. REF 400 🚫
- **`unauthorized:`** Authentication is required and has failed or has not been provided. REF 401 🔒
- **`forbidden:`** The server understands the request but refuses to authorize it. REF 403 🚷
- **`not_found:`** The requested resource could not be found. REF 404 🔍
- **`conflict`** The request could not be completed due to a conflict with the current state of the target resource. REF 409 ⚠️

## Server Error Indicators:

- **`internal_server_error:`** An unexpected condition was encountered on the server. REF 500 💥
- **`service_unavailable:`** The server is currently unable to handle the request due to temporary overloading or maintenance. REF 503 🛠️

### Possible responses that may appear (only in development) due to logical errors in all endpoints
##### 💥 `500` - Status not correctly mapped, may return incorrect http code, so it returns an error as a reminder to check it
```json
{
  "status": "service_unavailable",
  "message": "Error, status: (misspelled status of response) not mapped"
}
```

##### 🛠️ `503` - Service Unavailable or under development
```json
{
  "status": "service_unavailable",
  "message": "Service Temporary Unavailable due to Maintenance"
}
```

# More Information
## Token duration and roles "user_roles" in the system
|  JWT_Token  | Expiration Time |
|-------------|-----------------|
|  `analyst`  |    24 Hours     |
| `moderator` |     1 Hour      |
|   `admin`   |   30 Minutes    |


# Endpoints

## /Account

### **POST** `Account/login`

#### Description
This endpoint is designated for user login where the user receives a token that authorizes access to the system for a limited time.

#### Parameters
| Parameter  | Type   | Required | Description                                       |
|------------|--------|----------|---------------------------------------------------|
| `email`    | String | TRUE     | The email of the registered user                  |
| `password` | String | TRUE     | The password associated with the registered email |

#### Responses

##### ✅ `200` - Logged successfully, token returned
```json
{
  "status": "success",
  "message": "Valid Credentials",
  "data": {
    "token": "JWT_Token"
  }
}
```

##### 🚫 `400` - Required Inputs missing or invalid
```json
{
  "status": "bad_request",
  "message": "Invalid Input Type",
  "data": {
    "token": {}
  }
}

{
  "status": "bad_request",
  "message": "Email and Password are Required",
  "data": {
    "token": {}
  }
}

{
  "status": "bad_request",
  "message": "Invalid Email Pattern",
  "data": {
    "token": {}
  }
}

{
  "status": "bad_request",
  "message": "Invalid Password: Must be ASCII",
  "data": {
    "token": {}
  }
}
```

##### 🔍 `404` - User Not Found
```json
{
  "status": "not_found",
  "message": "Invalid Credentials",
  "data": {
    "token": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "token": {}
  }
}
```

---
### **POST** `Account/register`

#### Description
This endpoint is used to create a new user account. The user must provide a name, email, password, and optionally a user role.

#### Parameters
| Parameter   | Type   | Required | Description                                    |
|-------------|--------|----------|------------------------------------------------|
| `name`      | String | TRUE     | The name of the user                           |
| `email`     | String | TRUE     | The email of the user                          |
| `password`  | String | TRUE     | The password of the user                       |
| `user_role` | String | FALSE    | The type of user access (default: `moderator`) |

#### Responses

##### 🆕 `201` - User successfully registered
```json
{
  "status": "created",
  "message": "User Registered Successfully",
}
```

##### 🚫 `400` - Required Inputs missing or invalid 
```json
{
  "status": "bad_request",
  "message": "Invalid Input Type"
}

{
  "status": "bad_request",
  "message": "All Required Fields must be completed"
}

{
  "status": "bad_request",
  "message": "Email can't exceed 100 characters"
}

{
  "status": "bad_request",
  "message": "Email must be in a valid format (e.g., user@example.com)"
}

{
  "status": "bad_request",
  "message": "Invalid Password: Must be ASCII and below 72 characters"
}

{
  "status": "bad_request",
  "message": "User role must be 'analyst', 'moderator', or 'admin'"
}
```

##### ⚠️ `409` - Email already registered
```json
{
  "status": "conflict",
  "message": "Email must be unique. This email is already in use"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

## /Status

### **GET** `Status/ping`

#### Description
This endpoint is simply to verify in a fast way if the api is running on the called address and port, if not any response will come.

#### Responses

##### ✅ `200` - API Running
```json
{
  "status": "success",
  "message": "The API is Running"
}
```

---

## /Users

### **GET** `Users/all`

#### Description
This endpoint retrieves all users in the system. It is primarily used for debugging purposes. To use this endpoint, an administrator token must be provided in the authorization header.

#### Responses

##### ✅ `200` - Successfully retrieved all users from the database
```json
{
  "status": "success",
  "message": "All users successfully retrieved",
  "data": {
    "users": [
      {
        "id_user": "UUID",
        "name": "User_Name",
        "email": "user@example.com",
        "password": "Hashed_Password",
        "user_role": "analyst",
        "registration_date": "0000-00-00 00:00:00"
      },
      {
        "id_user": "UUID",
        "name": "User_Name",
        "email": "user@example.com",
        "password": "Hashed_Password",
        "user_role": "moderator",
        "registration_date": "0000-00-00 00:00:00"
      }
    ]
  }
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To retrieve all user info, you must be an administrator",
  "data": {
    "users": {}
  }
}
```

##### 🔍 `404` - No users found in the database
```json
{
  "status": "not_found",
  "message": "There are no users in the database",
  "data": {
    "users": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "users": {}
  }
}
```

---

### **GET** `Users/role`

#### Description
This endpoint retrieves the role of the user making the request.

#### Responses

##### ✅ `200` - Successfully retrieved the user's role
```json
{
  "status": "success",
  "message": "User role successfully retrieved",
  "data": {
    "user_role": "analyst"
  }
}
```

##### 🔍 `404` - No user associated with the provided token
```json
{
  "status": "not_found",
  "message": "There are no users in the database that own this token",
  "data": {
    "user_role": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "user_role": {}
  }
}
```

---

### **GET** `Users/<id_user>`

#### Description
This endpoint retrieves information about a specific user in the system. It is primarily used for debugging purposes. To use this endpoint, an administrator token must be provided in the authorization header.

#### Parameters
| Parameter  | Type   | Required | Description                     |
|------------|--------|----------|---------------------------------|
| `id_user`  | String | TRUE     | The UUID of the user to retrieve |

#### Responses

##### ✅ `200` - Successfully retrieved the user from the database
```json
{
  "status": "success",
  "message": "User successfully retrieved",
  "data": {
    "user": {
      "name": "User_Name",
      "email": "user@example.com",
      "password": "Hashed_Password",
      "user_role": "analyst",
      "registration_date": "0000-00-00 00:00:00"
    }
  }
}
```

##### 🚫 `400` - Missing or invalid user ID
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid user ID",
  "data": {
    "user": {}
  }
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "Retrieving user information that does not belong to you requires administrative privileges. To access your own data, use a different endpoint",
  "data": {
    "user": {}
  }
}
```

##### 🔍 `404` - User ID not found in the database
```json
{
  "status": "not_found",
  "message": "There are no users with this ID in the database",
  "data": {
    "user": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "user": {}
  }
}
```

---

## /Products

### **GET** `Products/get_all`

#### Description
This endpoint retrieves all products available in the system.

#### Responses

##### ✅ `200` - Successfully retrieved all products
```json
{
  "status": "success",
  "message": "All products successfully retrieved",
  "data": {
    "products": [
      {
        "id_product": "UUID",
        "product_name": "Product_Name",
        "product_description": "Description",
        "location_dependent": true,
        "product_price": 100.0,
        "id_category": "UUID"
      }
    ]
  }
}
```

##### 🔍 `404` - No products found in the database
```json
{
  "status": "not_found",
  "message": "There aren't any products in the database",
  "data": {
    "products": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "products": {}
  }
}
```

---

### **GET** `Products/owned`

#### Description
This endpoint retrieves all products owned by the user making the request.

#### Responses

##### ✅ `200` - Successfully retrieved owned products
```json
{
  "status": "success",
  "message": "Products owned successfully retrieved",
  "data": {
    "products_owned": [
      {
        "id_product": "UUID",
        "product_name": "Product_Name",
        "esp32_unique_id": "ESP32_ID"
      }
    ]
  }
}
```

##### 🔍 `404` - No products owned by the user
```json
{
  "status": "not_found",
  "message": "There are no products owned by this user",
  "data": {
    "products_owned": {}
  }
}
```

##### 🔒 `401` - Unauthorized, invalid or missing token
```json
{
  "status": "unauthorized",
  "message": "Failed to identify user, malformed or invalid token",
  "data": {
    "products_owned": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "products_owned": {}
  }
}
```

---

### **GET** `Products/owned/all_users`

#### Description
This endpoint retrieves all products owned by all users. Requires administrator privileges.

#### Responses

##### ✅ `200` - Successfully retrieved all owned products
```json
{
  "status": "success",
  "message": "All products owned successfully retrieved",
  "data": {
    "products_owned": [
      {
        "id_product": "UUID",
        "product_name": "Product_Name",
        "id_user": "UUID",
        "user_name": "User_Name",
        "esp32_unique_id": "ESP32_ID"
      }
    ]
  }
}
```

##### 🔍 `404` - No products owned in the database
```json
{
  "status": "not_found",
  "message": "There are no products owned in the database",
  "data": {
    "products_owned": {}
  }
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To retrieve all products owned info, you must be an administrator",
  "data": {
    "products_owned": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "products_owned": {}
  }
}
```

---

### **GET** `Products/<id_product>`

#### Description
This endpoint retrieves information about a specific product.

#### Parameters
| Parameter     | Type   | Required | Description                     |
|---------------|--------|----------|---------------------------------|
| `id_product`  | String | TRUE     | The UUID of the product to retrieve |

#### Responses

##### ✅ `200` - Successfully retrieved the product
```json
{
  "status": "success",
  "message": "Product successfully retrieved",
  "data": {
    "product": {
      "id_product": "UUID",
      "product_name": "Product_Name",
      "product_description": "Description",
      "location_dependent": true,
      "product_price": 100.0,
      "id_category": "UUID"
    }
  }
}
```

##### 🚫 `400` - Missing or invalid product ID
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid product ID",
  "data": {
    "product": {}
  }
}
```

##### 🔍 `404` - Product not found
```json
{
  "status": "not_found",
  "message": "There isn't any product with this id in the database",
  "data": {
    "product": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "product": {}
  }
}
```

---

### **GET** `Products/search`

#### Description
This endpoint searches for products by name, returning products with similar names.

#### Parameters
| Parameter | Type   | Required | Description                      |
|-----------|--------|----------|----------------------------------|
| `name`    | String | TRUE     | The name of the product to search |

#### Responses

##### ✅ `200` - Products with similar names found
```json
{
  "status": "success",
  "message": "Products with Similar Names Successfully Retrieved",
  "data": {
    "products": [
      {
        "id_product": "UUID",
        "product_name": "Product_Name",
        "product_description": "Description",
        "location_dependent": true,
        "product_price": 100.0,
        "id_category": "UUID"
      }
    ]
  }
}
```

##### 🔍 `404` - No products found with a similar name
```json
{
  "status": "not_found",
  "message": "There are no products with similar names",
  "data": {
    "products": {}
  }
}
```

##### 🚫 `400` - Invalid or missing product name
```json
{
  "status": "bad_request",
  "message": "Invalid Product Name",
  "data": {
    "products": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "products": {}
  }
}
```

---

### **GET** `Products/owned/<id_product>`

#### Description
This endpoint retrieves all instances of a specific product owned by the user making the request.

#### Parameters
| Parameter     | Type   | Required | Description                     |
|---------------|--------|----------|---------------------------------|
| `id_product`  | String | TRUE     | The UUID of the product to retrieve |

#### Responses

##### ✅ `200` - Successfully retrieved the product instances
```json
{
  "status": "success",
  "message": "Products owned successfully retrieved",
  "data": {
    "products_owned": [
      {
        "id_product_instance": "UUID",
        "product_name": "Product_Name",
        "product_description": "Description",
        "esp32_unique_id": "ESP32_ID"
      }
    ]
  }
}
```

##### 🚫 `400` - Missing or invalid product ID
```json
{
  "status": "bad_request",
  "message": "Invalid Product ID",
  "data": {
    "products_owned": {}
  }
}
```

##### 🔒 `401` - Unauthorized, invalid or missing token
```json
{
  "status": "unauthorized",
  "message": "Failed to identify user, malformed or invalid token",
  "data": {
    "products_owned": {}
  }
}
```

##### 🔍 `404` - No product instances found for the user
```json
{
  "status": "not_found",
  "message": "There are no products owned by this user",
  "data": {
    "products_owned": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "products_owned": {}
  }
}
```

---

### **POST** `Products/register`

#### Description
This endpoint is used to create a new product. Requires administrator privileges.

#### Parameters
| Parameter            | Type    | Required | Description                                    |
|----------------------|---------|----------|------------------------------------------------|
| `product_name`       | String  | TRUE     | The name of the product                       |
| `product_description`| String  | TRUE     | The description of the product                |
| `location_dependent` | Boolean | TRUE     | Whether the product is location dependent     |
| `product_price`      | Number  | TRUE     | The price of the product                      |
| `id_category`        | String  | FALSE    | The ID of the category (optional)             |

#### Responses

##### 🆕 `201` - Product successfully registered
```json
{
  "status": "created",
  "message": "Product Registered Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Product Name and Description must be valid, non-empty and UTF-8 strings"
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To register a product, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **POST** `Products/owned`

#### Description
This endpoint registers a product instance under the user's ownership.

#### Parameters
| Parameter          | Type   | Required | Description                                    |
|--------------------|--------|----------|------------------------------------------------|
| `id_product`       | String | TRUE     | The ID of the product                         |
| `esp32_unique_id`  | String | TRUE     | The unique ESP32 identifier for this instance |

#### Responses

##### 🆕 `201` - Product instance successfully registered
```json
{
  "status": "created",
  "message": "Product Owned Registered Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Product ID and ESP32 ID must be valid, non-empty and UTF-8 strings"
}
```

##### 🔒 `401` - Unauthorized, user is not allowed to register
```json
{
  "status": "unauthorized",
  "message": "To register a product on your name, you must be a moderator or higher"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **DELETE** `Products/owned/<esp32_unique_id>`

#### Description
This endpoint deletes a specific product instance owned by the user, identified by the ESP32 unique ID.

#### Parameters
| Parameter          | Type   | Required | Description                     |
|--------------------|--------|----------|---------------------------------|
| `esp32_unique_id`  | String | TRUE     | The unique ESP32 identifier for the product instance |

#### Responses

##### ✅ `200` - Product instance successfully deleted
```json
{
  "status": "success",
  "message": "Product Deleted Successfully"
}
```

##### 🚫 `400` - Missing or invalid ESP32 ID
```json
{
  "status": "bad_request",
  "message": "Invalid ESP32 ID"
}
```

##### 🔒 `401` - Unauthorized, user is not allowed to delete
```json
{
  "status": "unauthorized",
  "message": "To delete a product on your name, you must be a moderator or higher"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

## /Categories

### **GET** `Categories/get_all`

#### Description
This endpoint retrieves all categories available in the system.

#### Responses

##### ✅ `200` - Successfully retrieved all categories
```json
{
  "status": "success",
  "message": "All categories successfully retrieved",
  "data": {
    "categories": [
      {
        "id_category": "UUID",
        "category_name": "Category_Name",
        "category_description": "Description",
        "id_father_category": "UUID"
      }
    ]
  }
}
```

##### 🔍 `404` - No categories found in the database
```json
{
  "status": "not_found",
  "message": "There aren't any categories in the database",
  "data": {
    "categories": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "categories": {}
  }
}
```

---

### **GET** `Categories/<id_category>`

#### Description
This endpoint retrieves information about a specific category.

#### Parameters
| Parameter     | Type   | Required | Description                     |
|---------------|--------|----------|---------------------------------|
| `id_category` | String | TRUE     | The UUID of the category to retrieve |

#### Responses

##### ✅ `200` - Successfully retrieved the category
```json
{
  "status": "success",
  "message": "Category successfully retrieved",
  "data": {
    "category": {
      "id_category": "UUID",
      "category_name": "Category_Name",
      "category_description": "Description",
      "id_father_category": "UUID"
    }
  }
}
```

##### 🚫 `400` - Missing or invalid category ID
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid category ID",
  "data": {
    "category": {}
  }
}
```

##### 🔍 `404` - Category not found
```json
{
  "status": "not_found",
  "message": "There isn't any category with this id in the database",
  "data": {
    "category": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "category": {}
  }
}
```

---

### **POST** `Categories/create`

#### Description
This endpoint is used to create a new category. Requires administrator privileges.

#### Parameters
| Parameter             | Type   | Required | Description                                    |
|-----------------------|--------|----------|------------------------------------------------|
| `category_name`       | String | TRUE     | The name of the category                      |
| `category_description`| String | TRUE     | The description of the category               |
| `id_father_category`  | String | FALSE    | The ID of the parent category (optional)      |

#### Responses

##### 🆕 `201` - Category successfully registered
```json
{
  "status": "created",
  "message": "Category Registered Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Category Name and Description must be valid, non-empty and UTF-8 strings"
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To register a category, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **PUT** `Categories/<id_category>`

#### Description
This endpoint updates a specific category. Requires administrator privileges.

#### Parameters
| Parameter             | Type   | Required | Description                                    |
|-----------------------|--------|----------|------------------------------------------------|
| `id_category`         | String | TRUE     | The UUID of the category to update            |
| `category_name`       | String | FALSE    | The new name of the category                  |
| `category_description`| String | FALSE    | The new description of the category           |
| `id_father_category`  | String | FALSE    | The new ID of the parent category (optional)  |

#### Responses

##### ✅ `200` - Category successfully updated
```json
{
  "status": "success",
  "message": "Category Updated Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Category Name and Description must be valid, non-empty and UTF-8 strings"
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To update a category, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **DELETE** `Categories/<id_category>`

#### Description
This endpoint deletes a specific category. Requires administrator privileges.

#### Parameters
| Parameter     | Type   | Required | Description                     |
|---------------|--------|----------|---------------------------------|
| `id_category` | String | TRUE     | The UUID of the category to delete |

#### Responses

##### ✅ `200` - Category successfully deleted
```json
{
  "status": "success",
  "message": "Category Deleted Successfully"
}
```

##### 🚫 `400` - Missing or invalid category ID
```json
{
  "status": "bad_request",
  "message": "Invalid Category ID, can't be null"
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To delete a category, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

## /Locations

### **GET** `Locations/get_all`

#### Description
This endpoint retrieves all locations available in the system. Requires administrator privileges.

#### Responses

##### ✅ `200` - Successfully retrieved all locations
```json
{
  "status": "success",
  "message": "All locations successfully retrieved",
  "data": {
    "locations": [
      {
        "id_product_instance": "UUID",
        "latitude": 12.345678,
        "longitude": 98.765432
      }
    ]
  }
}
```

##### 🔍 `404` - No locations found in the database
```json
{
  "status": "not_found",
  "message": "No locations found in the database",
  "data": {
    "locations": {}
  }
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To retrieve all locations, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "locations": {}
  }
}
```

---

### **GET** `Locations/<id_product_instance>`

#### Description
This endpoint retrieves the location of a specific product instance.

#### Parameters
| Parameter             | Type   | Required | Description                     |
|-----------------------|--------|----------|---------------------------------|
| `id_product_instance` | String | TRUE     | The UUID of the product instance |

#### Responses

##### ✅ `200` - Successfully retrieved the location
```json
{
  "status": "success",
  "message": "Location successfully retrieved",
  "data": {
    "location": {
      "id_product_instance": "UUID",
      "latitude": 12.345678,
      "longitude": 98.765432
    }
  }
}
```

##### 🚫 `400` - Missing or invalid product instance ID
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid location ID",
  "data": {
    "location": {}
  }
}
```

##### 🔍 `404` - Location not found
```json
{
  "status": "not_found",
  "message": "Location not found with this ID",
  "data": {
    "location": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "location": {}
  }
}
```

---

### **GET** `Locations/solar_tracker`

#### Description
This endpoint retrieves location data by the ESP32 unique identifier, primarily used for solar tracker devices.

#### Parameters
| Parameter          | Type   | Required | Description                     |
|--------------------|--------|----------|---------------------------------|
| `esp32_unique_id`  | String | TRUE     | The unique identifier of the ESP32 device |

#### Responses

##### ✅ `200` - Successfully retrieved the location
```json
{
  "status": "success",
  "message": "Location successfully retrieved",
  "data": {
    "location": {
      "latitude": 12.345678,
      "longitude": 98.765432
    }
  }
}
```

##### 🚫 `400` - Missing or invalid ESP32 ID
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid ESP32 ID",
  "data": {
    "location": {}
  }
}
```

##### 🔍 `404` - Location not found
```json
{
  "status": "not_found",
  "message": "Location not found with this ESP32 ID",
  "data": {
    "location": {}
  }
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "location": {}
  }
}
```

---

### **POST** `Locations/register`

#### Description
This endpoint registers a new location for a product instance.

#### Parameters
| Parameter             | Type    | Required | Description                                    |
|-----------------------|---------|----------|------------------------------------------------|
| `id_product_instance` | String  | TRUE     | The UUID of the product instance              |
| `latitude`            | Number  | TRUE     | The latitude of the location                  |
| `longitude`           | Number  | TRUE     | The longitude of the location                 |

#### Responses

##### 🆕 `201` - Location successfully registered
```json
{
  "status": "created",
  "message": "Location Registered Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Invalid Product Instance ID"
}
```

##### 🔒 `401` - Unauthorized, user is not allowed to register
```json
{
  "status": "unauthorized",
  "message": "To register a location, you must be a moderator or higher"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **POST** `Locations/set`

#### Description
This endpoint creates or updates location data for a product instance. If the location exists, it will be updated; otherwise, a new location will be created.

#### Parameters
| Parameter             | Type    | Required | Description                                    |
|-----------------------|---------|----------|------------------------------------------------|
| `id_product_instance` | String  | TRUE     | The UUID of the product instance              |
| `latitude`            | Number  | TRUE     | The latitude of the location                  |
| `longitude`           | Number  | TRUE     | The longitude of the location                 |

#### Responses

##### ✅ `200` - Location successfully updated
```json
{
  "status": "success",
  "message": "Location Updated Successfully"
}
```

##### 🆕 `201` - Location successfully created
```json
{
  "status": "created",
  "message": "Location Registered Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Invalid Product Instance ID"
}
```

##### 🔒 `401` - Unauthorized, user is not allowed to create or update
```json
{
  "status": "unauthorized",
  "message": "To set a location, you must be a moderator or higher"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **PUT** `Locations/<id_product_instance>`

#### Description
This endpoint updates the location of a specific product instance.

#### Parameters
| Parameter             | Type    | Required | Description                                    |
|-----------------------|---------|----------|------------------------------------------------|
| `id_product_instance` | String  | TRUE     | The UUID of the product instance              |
| `latitude`            | Number  | TRUE     | The new latitude of the location              |
| `longitude`           | Number  | TRUE     | The new longitude of the location             |

#### Responses

##### ✅ `200` - Location successfully updated
```json
{
  "status": "success",
  "message": "Location Updated Successfully"
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "Invalid Product Instance ID"
}
```

##### 🔒 `401` - Unauthorized, user is not allowed to update
```json
{
  "status": "unauthorized",
  "message": "To update a location, you must be a moderator or higher"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

### **DELETE** `Locations/<id_product_instance>`

#### Description
This endpoint deletes the location of a specific product instance. Requires administrator privileges.

#### Parameters
| Parameter             | Type   | Required | Description                     |
|-----------------------|--------|----------|---------------------------------|
| `id_product_instance` | String | TRUE     | The UUID of the product instance |

#### Responses

##### ✅ `200` - Location successfully deleted
```json
{
  "status": "success",
  "message": "Location Deleted Successfully"
}
```

##### 🚫 `400` - Missing or invalid product instance ID
```json
{
  "status": "bad_request",
  "message": "Invalid Location ID, can't be null"
}
```

##### 🔒 `401` - Unauthorized, user is not an admin
```json
{
  "status": "unauthorized",
  "message": "To delete a location, you must be an administrator"
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error"
}
```

---

## /ESP32_DataEntry

### **POST** `ESP32_DataEntry/solar_tracker/send_data`

#### Description
This endpoint is dedicated to receiving data from ESP32 devices, specifically voltage, current, and other telemetry data. The data is processed and stored in memory or sent to the database.

#### Parameters
| Parameter                | Type    | Required | Description                                      |
|--------------------------|---------|----------|--------------------------------------------------|
| `esp32_unique_id`        | String  | TRUE     | The unique identifier of the ESP32 device       |
| `max_elevation`          | Number  | TRUE     | The maximum elevation angle                     |
| `min_elevation`          | Number  | TRUE     | The minimum elevation angle                     |
| `servo_tower_angle`      | Number  | TRUE     | The angle of the servo tower                    |
| `solar_panel_temperature`| Number  | TRUE     | The temperature of the solar panel              |
| `esp32_core_temperature` | Number  | TRUE     | The core temperature of the ESP32 device        |
| `voltage`                | Number  | TRUE     | The voltage measured by the ESP32               |
| `current`                | Number  | TRUE     | The current measured by the ESP32               |

#### Responses

##### ✅ `202` - Data saved in memory
```json
{
  "status": "accepted",
  "message": "Saving ESP32 Data on Memory",
  "data": {
    "step": 50,
    "total_steps": 100
  }
}
```

##### 🆕 `201` - Data successfully sent to the database
```json
{
  "status": "created",
  "message": "Sending ESP32 Data to Database",
  "data": {
    "step": 100,
    "total_steps": 100
  }
}
```

##### 🚫 `400` - Invalid or missing parameters
```json
{
  "status": "bad_request",
  "message": "ESP32 ID must be valid, non-empty and UTF-8 string",
  "data": null
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": {
    "step": 50,
    "total_steps": 100
  }
}
```

---

### **GET** `ESP32_DataEntry/solar_tracker/receive_data`

#### Description
This endpoint retrieves location and time data for a specific ESP32 device.

#### Parameters
| Parameter         | Type   | Required | Description                              |
|-------------------|--------|----------|------------------------------------------|
| `esp32_unique_id` | String | TRUE     | The unique identifier of the ESP32 device |

#### Responses

##### ✅ `200` - Successfully retrieved location and time data
```json
{
  "status": "success",
  "message": "Location and time data successfully retrieved",
  "data": {
    "year": 2023,
    "month": 10,
    "day": 5,
    "hour": 14,
    "minute": 30,
    "second": 45,
    "latitude": 12.345678,
    "longitude": 98.765432
  }
}
```

##### ✅ `200` - No location data found for the ESP32
```json
{
  "status": "success",
  "message": "No location data found for the ESP32",
  "data": {
    "year": 2023,
    "month": 10,
    "day": 5,
    "hour": 14,
    "minute": 30,
    "second": 45,
    "latitude": 0,
    "longitude": 0
  }
}
```

##### 🚫 `400` - Invalid or missing ESP32 ID
```json
{
  "status": "bad_request",
  "message": "ESP32 ID must be valid, non-empty and UTF-8 string",
  "data": null
}
```

##### 💥 `500` - Unexpected Error on Server-Side
```json
{
  "status": "internal_server_error",
  "message": "Unexpected Error: depends_on_the_error",
  "data": null
}
```