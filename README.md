# Hakim Backend (حكيم)

Backend API for the Hakim complaints management platform.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/yourusername/hakim-backend.git
cd hakim-backend
cp .env.example .env

# Configure your .env file, then run
go mod download
go run cmd/server/main.go
```

Server runs on `http://localhost:8080`

## API

Base URL: `/api/v1`

| Method | Endpoint         | Description      |
| ------ | ---------------- | ---------------- |
| GET    | `/health`        | Health check     |
| POST   | `/auth/register` | Register user    |
| POST   | `/auth/login`    | Login            |
| GET    | `/complaints`    | List complaints  |
| POST   | `/complaints`    | Create complaint |

## Tech Stack

- Go 1.21+ / Fiber
- Supabase (PostgreSQL + Auth)
- OpenAI (Classification)
