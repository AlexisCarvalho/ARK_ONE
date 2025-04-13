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

## /Users

### **GET** `Users/get_all`

#### Description
This endpoint is used to get all the users on the system, used mostly for debug, for using it you will need to get an administrator token and have it set on the authorization header.

#### Responses

##### ✅ `200` - Successfully retrieved all users from database
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

##### 🔒 `401` - Unauthorized, user trying to use the endpoint is not an admin
```json
{
  "status": "unauthorized",
  "message": "To retrieve all user info, you must be an administrator",
  "data": {
    "users": {}
  }
}
```

##### 🔍 `404` - There are no users in the database
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

### **GET** `Users/get_role`

#### Description
This endpoint is used to get the role of the current user sending the request.

#### Responses

##### ✅ `200` - Successfully retrieved all users from database
```json
{
  "status": "success",
  "message": "User role successfully retrieved",
  "data": {
    "user_role": "analyst"
  }
}
```

##### 🔍 `404` - There are no users in the database
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

### **GET** `Users/<id_user>`

#### Description
This endpoint is used to get information of a specific user on the system, used mostly for debug, for using it you will need to get an administrator token and have it set on the authorization header.

#### Responses

##### ✅ `200` - Successfully retrieved the user from database
```json
{
  "status": "success",
  "message": "User successfully retrieved",
  "data": {
    "user": [
      {
        "name": "User_Name",
        "email": "user@example.com",
        "password": "Hashed_Password",
        "user_role": "analyst",
        "registration_date": "0000-00-00 00:00:00"
      }
    ]
  }
}
```

##### 🚫 `400` - Required Inputs missing or invalid
```json
{
  "status": "bad_request",
  "message": "Missing or Invalid user ID",
  "data": {
    "user": {}
  }
}
```

##### 🔒 `401` - Unauthorized, user trying to use the endpoint is not an admin
```json
{
  "status": "unauthorized",
  "message": "Retrieving user information that does not belong to you requires administrative privileges. To access your own data, use a different endpoint",
  "data": {
    "user": {}
  }
}
```

##### 🔍 `404` - UUID Not found on the database
```json
{
  "status": "not_found",
  "message": "There are no user with this id in the database",
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