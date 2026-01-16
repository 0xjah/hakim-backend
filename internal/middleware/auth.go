package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/hakim/backend/pkg/supabase"
)

func AuthMiddleware(client *supabase.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing authorization header",
			})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid authorization header format",
			})
		}

		token := parts[1]

		// Verify token with Supabase
		user, err := client.GetUser(token)
		if err != nil {
			// Log the actual error for debugging
			println("Auth Error:", err.Error())
			println("Token (first 20 chars):", token[:min(20, len(token))])
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Invalid or expired token",
				"details": err.Error(),
			})
		}

		// Store user in context
		c.Locals("user", user)
		c.Locals("token", token)

		return c.Next()
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func AdminMiddleware(client *supabase.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		user := c.Locals("user")
		if user == nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "User not authenticated",
			})
		}

		profile, ok := user.(*supabase.UserProfile)
		if !ok {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Invalid user data",
			})
		}

		if profile.Role != "admin" && profile.Role != "super_admin" && profile.Role != "employee" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Insufficient permissions",
			})
		}

		return c.Next()
	}
}
