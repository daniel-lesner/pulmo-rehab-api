
# Pulmo Rehab API

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://shields.io/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Backend API for the Pulmo Rehab application. This API manages users (patients and doctors), wearable device integrations (Fitbit, Garmin), session management, and retrieves related data like air pollution information. It follows the JSON:API v1.0 specification.

> *(Note: The specific high-level purpose of "Pulmo Rehab" is inferred; please update this description if necessary.)*

---

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone Repository](#1-clone-repository)
  - [2. Environment Variables (.env)](#2-environment-variables-env)
  - [3. Build Docker Images](#3-build-docker-images)
  - [4. Start Services](#4-start-services)
- [Running the Application](#running-the-application)
- [Database Migrations](#database-migrations)
- [API Documentation](#api-documentation)
- [Running Tests](#running-tests)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- User Management (Patients) - CRUD operations.
- Doctor Management - Creation and retrieval.
- Wearable Device (Bracelet) Management - CRUD for Fitbit/Garmin devices linked to users.
- Session Management - Login for Users and Doctors via email/password, providing authentication tokens.
- Dashboard Data Retrieval - Fetches time-series data (e.g., heart rate, steps) from linked Fitbit/Garmin accounts.
- Air Pollution Data Retrieval - Fetches air quality data from OpenWeatherMap based on coordinates.
- JSON:API v1.0 Compliant.
- Token-based Authentication.
- Authorization via Pundit.
- Dockerized Development Environment.

---

## Technology Stack

- **Backend:** Ruby on Rails 7.2.x
- **Ruby Version:** 3.3.5
- **Database:** PostgreSQL 15.x
- **API Specification:** JSON:API v1.0 (via `jsonapi-resources` gem)
- **Authorization:** Pundit
- **Web Server:** Puma
- **Containerization:** Docker, Docker Compose

---

## Prerequisites

Ensure you have the following installed on your system:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

---

## Getting Started

Follow these steps to set up and run the application locally for development.

### 1. Clone Repository

```bash
git clone <your-repository-url>
cd pulmo-rehab-api
```

### 2. Environment Variables (.env)

Create a `.env` file by copying the example below:

```env
# .env - Environment variables for Docker Compose

DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=pulmo_rehab_dev
DATABASE_HOST=db

POSTGRES_USER=${DATABASE_USER}
POSTGRES_PASSWORD=${DATABASE_PASSWORD}
POSTGRES_DB=${DATABASE_NAME}

RAILS_MASTER_KEY=
RAILS_ENV=development

REGISTRATION_KEY=YOUR_DOCTOR_REGISTRATION_KEY

OPENWEATHERMAP_API_KEY=YOUR_OPENWEATHERMAP_API_KEY

# FITBIT_CLIENT_ID=YOUR_FITBIT_CLIENT_ID
# FITBIT_CLIENT_SECRET=YOUR_FITBIT_CLIENT_SECRET
# FITBIT_REDIRECT_URI=YOUR_FITBIT_REDIRECT_URI

# GARMIN_CONSUMER_KEY=YOUR_GARMIN_CONSUMER_KEY
# GARMIN_CONSUMER_SECRET=YOUR_GARMIN_CONSUMER_SECRET
```

---

### 3. Build Docker Images

```bash
docker-compose build
```

---

### 4. Start Services

```bash
docker-compose up
```

The first time you run this, the entrypoint script will:

- Wait for the database to be ready.
- Run database migrations.
- Start the Puma web server.

The application will be available at `http://localhost:3000`.

---

## Running the Application

- **Start:** `docker-compose up`
- **Stop:** `docker-compose down`
- **Stop & Clean:** `docker-compose down -v`

---

## Database Migrations

Migrations are run on startup, but you can also run manually:

```bash
docker-compose exec app bundle exec rails db:migrate
```

Check status:

```bash
docker-compose exec app bundle exec rails db:migrate:status
```

---

## API Documentation

API docs are found in `API_DOCUMENTATION.md`.

- **Base URL:** `/api/v1`
- **Authentication:** Bearer Token
- **Format:** `application/vnd.api+json`

---

## Running Tests

To run tests (e.g., RSpec):

```bash
docker-compose exec app bundle exec rspec
```

---

## Deployment

Typical deployment steps:

1. Build production Docker image.
2. Push to registry.
3. Configure server or orchestrator with env vars.
4. Deploy containers.
5. Run production database migrations.

---

## Contributing

Please refer to `CONTRIBUTING.md` for guidelines.

---

## License

This project is licensed under the MIT License. See `LICENSE.md` for details.
