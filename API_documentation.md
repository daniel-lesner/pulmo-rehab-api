
# Pulmo Rehab API Documentation (v1)

**Version:** 1.0  
**Base URL:** `/api/v1`  
**Format:** JSON:API v1.0 (`Content-Type: application/vnd.api+json`)

---

## Authentication

Most endpoints require authentication via a Bearer Token passed in the `Authorization` header.

```
Authorization: Bearer <your_password_token>
```

The `<your_password_token>` is obtained from the `password_token` attribute returned upon successful User/Doctor creation or Session creation (login).

Endpoints that do not require authentication are explicitly marked.

---

## JSON:API Format Basics

**All requests and responses adhere to the JSON:API specification.**

- **Requests:** Data sent to the server (e.g., for POST, PATCH) must be nested under a top-level `data` key, containing `type` (resource type, usually plural) and `attributes`. Relationships are nested under `relationships`.
- **Responses:** Data returned from the server will be under a top-level `data` key (or an array for collections). Each resource object includes `id`, `type`, `attributes`, and potentially `relationships` and `links`.

---

## Error Responses

The API uses standard HTTP status codes for errors. Error details are provided in the response body following the JSON:API error object format.

### 401 Unauthorized

Authentication token is missing or invalid.

```json
{
  "errors": [
    {
      "status": "401",
      "code": "401",
      "title": "Unauthorized",
      "detail": "You need to be authenticated to perform this operation"
    }
  ]
}
```

### 403 Forbidden

Authenticated user does not have permission for the action (handled by Pundit).

```json
{
  "errors": [
    {
      "status": "403",
      "code": "403",
      "title": "Forbidden",
      "detail": "You don't have appropriate permissions to perform this operation"
    }
  ]
}
```

### 404 Not Found

The requested resource could not be found.

```json
{
  "errors": [
    {
      "status": "404",
      "code": "404",
      "title": "Record not found",
      "details": "The record identified by {id} could not be found."
    }
  ]
}
```

### 422 Unprocessable Entity

The request was well-formed but contained semantic errors.

```json
{
  "errors": [
    {
      "title": "Invalid details",
      "detail": "password does not match email",
      "code": "422",
      "status": "422"
    }
  ]
}
```

---

## Health Check Endpoint

**GET /up**  
**Description:** Returns 200 if the application is healthy.  
**Authentication:** Not required.  
**Success (200 OK):** No body.  
**Error (500 Internal Server Error):** Application boot issue.

---

## API Endpoints

### Sessions

**POST /api/v1/sessions**  
Logs in a User or Doctor.

**Authentication:** Not required.

**Request Body:**

```json
{
  "data": {
    "type": "sessions",
    "attributes": {
      "email": "user@example.com",
      "password": "your_password"
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "generated_session_id",
    "type": "sessions",
    "attributes": {
      "user_id": "user_or_doctor_id",
      "email": "user@example.com",
      "password_token": "generated_auth_token_for_bearer_auth",
      "is_doctor": true
    }
  }
}
```

---

### Users

**POST /api/v1/users**  
Creates a new user (patient).  

**Authentication:** Not required.

**Request Body:**

```json
{
  "data": {
    "type": "users",
    "attributes": {
      "name": "John Doe",
      "email": "patient@example.com",
      "password": "secure_password"
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "new_user_id",
    "type": "users",
    "attributes": {
      "name": "John Doe",
      "email": "patient@example.com",
      "password_token": "generated_auth_token",
      "password_token_expires_at": "iso8601_timestamp",
      "doctor_id": "associated_doctor_id"
    },
    "relationships": {
      "bracelets": {},
      "doctor": {}
    },
    "links": {
      "self": "/api/v1/users/new_user_id"
    }
  }
}
```

---

**GET /api/v1/users**  
Retrieves list of users (filtered by doctor if needed).  

**Authentication:** Required.

**Query Params:**

- `filter[doctor_id]={doctor_id}`
- `filter[doctor_id]=null`

**Response (200 OK):**

```json
{
  "data": [
    {
      "id": "user_id_1",
      "type": "users",
      "attributes": {
        "name": "John Doe",
        "email": "patient1@example.com",
        "password_token": "token1",
        "password_token_expires_at": "iso8601_timestamp",
        "doctor_id": "doctor_id_1"
      },
      "relationships": {},
      "links": {}
    }
  ]
}
```

---

**GET /api/v1/users/{id}**  
Retrieves a specific user.  

**Authentication:** Required.

**Response (200 OK):**

```json
{
  "data": {
    "id": "user_id_1",
    "type": "users",
    "attributes": {},
    "relationships": {},
    "links": {}
  }
}
```

---

**PATCH /api/v1/users/{id}**  
Updates a specific user.  

**Authentication:** Required.

**Request Body:**

```json
{
  "data": {
    "id": "user_id_to_update",
    "type": "users",
    "attributes": {
      "name": "Johnathan Doe"
    }
  }
}
```

---

**DELETE /api/v1/users/{id}**  
Deletes a specific user.  

**Authentication:** Required.  
**Response (204 No Content):** No body.

---

---

### Doctors

### POST /api/v1/doctors

Creates a new Doctor. Requires a valid `registration_key`.  
**Authentication:** Not required.

**Request Body:**

```json
{
  "data": {
    "type": "doctors",
    "attributes": {
      "name": "Dr. Alice Smith",
      "email": "dr.alice@example.com",
      "password": "doctor_password",
      "registration_key": "the_valid_registration_key"
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "new_doctor_id",
    "type": "doctors",
    "attributes": {
      "name": "Dr. Alice Smith",
      "email": "dr.alice@example.com",
      "password_token": "generated_auth_token",
      "password_token_expires_at": "iso8601_timestamp"
    },
    "relationships": {
      "users": {}
    },
    "links": {
      "self": "/api/v1/doctors/new_doctor_id"
    }
  }
}
```

---

### GET /api/v1/doctors/{id}

Retrieves details for a specific doctor.  
**Authentication:** Required.

---

### Bracelets

### POST /api/v1/bracelets

Creates/registers a new bracelet for the current user.  
**Authentication:** Required.

**Request Body:**

```json
{
  "data": {
    "type": "bracelets",
    "attributes": {
      "name": "My Fitbit Sense",
      "brand": "Fitbit",
      "model": "Sense",
      "token": "authorization_code_or_access_token",
      "token_secret": "token_secret_if_applicable"
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "new_bracelet_id",
    "type": "bracelets",
    "attributes": {
      "name": "My Fitbit Sense",
      "brand": "Fitbit",
      "model": "Sense",
      "token": "exchanged_access_token",
      "token_secret": "exchanged_refresh_token"
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "authenticated_user_id" },
        "links": {}
      }
    },
    "links": {
      "self": "/api/v1/bracelets/new_bracelet_id"
    }
  }
}
```

---

### GET /api/v1/bracelets

Returns a list of bracelets for the current user.  
**Authentication:** Required.

---

### GET /api/v1/bracelets/{id}

Retrieves details for a specific bracelet.  
**Authentication:** Required.

---

### DELETE /api/v1/bracelets/{id}

Deletes a bracelet owned by the user.  
**Authentication:** Required.  
**Response (204 No Content):** No body.

---

### Dashboards

### POST /api/v1/dashboards

Fetches data from the external service (Fitbit/Garmin).  
**Authentication:** Required.

**Request Body:**

```json
{
  "data": {
    "type": "dashboards",
    "attributes": {
      "bracelet_id": "target_bracelet_id",
      "date": "YYYY-MM-DD",
      "data_type": "heartrate",
      "time_interval_in_minutes": 15
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "generated_dashboard_id",
    "type": "dashboards",
    "attributes": {
      "bracelet_id": "target_bracelet_id",
      "bracelet_type": "Fitbit",
      "date": "YYYY-MM-DD",
      "data_type": "heartrate",
      "data": {},
      "time_interval_in_minutes": 15
    }
  }
}
```

---

### Air Pollutions

### POST /api/v1/air_pollutions

Fetches air pollution data from OpenWeatherMap for given coordinates.  
**Authentication:** Required (check controller logic).

**Request Body:**

```json
{
  "data": {
    "type": "air_pollutions",
    "attributes": {
      "lat": 47.15,
      "lon": 27.58
    }
  }
}
```

**Response (201 Created):**

```json
{
  "data": {
    "id": "generated_airpollution_id",
    "type": "air_pollutions",
    "attributes": {
      "lat": 47.15,
      "lon": 27.58,
      "co": 200.1,
      "no": 0.2,
      "no2": 1.5,
      "o3": 70.8,
      "so2": 1.2,
      "pm2_5": 5.5,
      "pm10": 8.9,
      "nh3": 0.8,
      "dt": 1618400000
    }
  }
}
```
