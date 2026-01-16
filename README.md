# Hakim Backend (حكيم)

## Smart Government Complaints Management Platform - API Server

> "Hakim" means "Wise" in Arabic, reflecting the platform's intelligent approach to handling citizen complaints efficiently and wisely.

---

## Overview

This is the backend API server for the Hakim platform, built with Go and the Fiber framework. It provides RESTful APIs for the mobile application to manage citizen complaints.

## Tech Stack

| Component             | Technology            |
| --------------------- | --------------------- |
| **Language**          | Go 1.21+              |
| **Framework**         | Fiber                 |
| **Database**          | Supabase (PostgreSQL) |
| **Authentication**    | Supabase Auth + JWT   |
| **AI Classification** | OpenAI / Google Cloud |

---

## Project Structure

```
hakim-backend/
├── cmd/
│   └── server/          # Application entry point
│       └── main.go
├── internal/
│   ├── ai/              # AI classification service
│   ├── config/          # Configuration management
│   ├── handlers/        # HTTP handlers
│   ├── middleware/      # Auth & logging middleware
│   ├── models/          # Data models
│   └── utils/           # Utility functions
├── pkg/
│   └── supabase/        # Supabase client
├── .env.example         # Environment template
├── go.mod
└── go.sum
```

---

## Getting Started

### Prerequisites

- Go 1.21+
- Supabase account (free tier works)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/hakim-backend.git
   cd hakim-backend
   ```

2. **Set up environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your Supabase credentials:

   ```env
   PORT=8080
   ENV=development
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_KEY=your-service-role-key
   JWT_SECRET=your-jwt-secret-key
   ```

3. **Install dependencies**

   ```bash
   go mod download
   ```

4. **Run the server**
   ```bash
   go run cmd/server/main.go
   ```

The server will start on `http://localhost:8080`

---

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Complaints

- `GET /api/complaints` - List user's complaints
- `POST /api/complaints` - Submit new complaint
- `GET /api/complaints/:id` - Get complaint details
- `PUT /api/complaints/:id` - Update complaint
- `POST /api/complaints/:id/feedback` - Submit feedback

### Admin

- `GET /api/admin/complaints` - List all complaints (admin)
- `PUT /api/admin/complaints/:id/status` - Update complaint status
- `GET /api/admin/analytics` - Get analytics dashboard data

---

## Deployment

### Using Docker

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### Environment Variables for Production

```env
PORT=8080
ENV=production
SUPABASE_URL=your-production-supabase-url
SUPABASE_ANON_KEY=your-production-anon-key
SUPABASE_SERVICE_KEY=your-production-service-key
JWT_SECRET=your-secure-production-jwt-secret
```

---

## Related Repositories

- **Frontend Mobile App**: [hakim](https://github.com/yourusername/hakim) - Flutter mobile application

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
