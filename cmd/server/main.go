package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/hakim/backend/internal/ai"
	"github.com/hakim/backend/internal/config"
	"github.com/hakim/backend/internal/handlers"
	"github.com/hakim/backend/internal/middleware"
	"github.com/hakim/backend/pkg/supabase"
)

func main() {
	// Load configuration
	if err := config.Load(); err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize Supabase client
	supabaseClient := supabase.New()

	// Initialize AI classifier
	classifier := ai.NewClassifier(supabaseClient)

	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName:      "Hakim API",
		ErrorHandler: errorHandler,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${method} ${path} ${latency}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, PATCH, DELETE, OPTIONS",
	}))

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(supabaseClient)
	complaintHandler := handlers.NewComplaintHandler(supabaseClient, classifier)
	adminHandler := handlers.NewAdminHandler(supabaseClient)

	// Routes
	api := app.Group("/api/v1")

	// Health check
	api.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"service": "hakim-api",
			"version": "1.0.0",
		})
	})

	// Test Supabase connection
	api.Get("/test-auth", func(c *fiber.Ctx) error {
		token := c.Get("Authorization")
		if token == "" {
			return c.JSON(fiber.Map{
				"error": "No Authorization header provided",
				"hint":  "Send: Authorization: Bearer <your_token>",
			})
		}

		// Strip "Bearer " prefix if present
		if len(token) > 7 && token[:7] == "Bearer " {
			token = token[7:]
		}

		user, err := supabaseClient.GetUser(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":         "Token validation failed",
				"details":       err.Error(),
				"token_preview": token[:min(30, len(token))],
			})
		}

		return c.JSON(fiber.Map{
			"success": true,
			"user":    user,
		})
	})

	// Auth routes (public)
	auth := api.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)
	auth.Post("/refresh", authHandler.RefreshToken)

	// Public data routes (must be before protected routes)
	api.Get("/departments", adminHandler.ListDepartments)
	api.Get("/categories", adminHandler.ListCategories)

	// Protected routes
	protected := api.Group("", middleware.AuthMiddleware(supabaseClient))

	// Profile routes
	protected.Get("/profile", authHandler.GetProfile)
	protected.Put("/profile", authHandler.UpdateProfile)

	// Complaint routes
	complaints := protected.Group("/complaints")
	complaints.Get("/", complaintHandler.List)
	complaints.Post("/", complaintHandler.Create)
	complaints.Get("/:id", complaintHandler.Get)
	complaints.Put("/:id", complaintHandler.Update)
	complaints.Post("/:id/feedback", complaintHandler.SubmitFeedback)
	complaints.Get("/:id/history", complaintHandler.GetStatusHistory)

	// Admin routes (requires admin role)
	admin := protected.Group("/admin", middleware.AdminMiddleware(supabaseClient))
	admin.Get("/complaints", adminHandler.ListComplaints)
	admin.Get("/complaints/:id", adminHandler.GetComplaint)
	admin.Put("/complaints/:id/assign", adminHandler.AssignComplaint)
	admin.Put("/complaints/:id/status", adminHandler.UpdateStatus)
	admin.Get("/analytics", adminHandler.GetAnalytics)
	admin.Get("/employees", adminHandler.ListEmployees)

	// Graceful shutdown
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		log.Println("Gracefully shutting down...")
		_ = app.Shutdown()
	}()

	// Start server
	port := config.AppConfig.Port
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Hakim API server starting on port %s", port)
	log.Printf("📝 Environment: %s", config.AppConfig.Env)

	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// errorHandler handles global errors
func errorHandler(c *fiber.Ctx, err error) error {
	// Default 500 status code
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error": err.Error(),
	})
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
