package utils

import (
	"errors"
	"log/slog"

	"github.com/gofiber/fiber/v2"
	"github.com/hakim/backend/pkg/supabase"
)

var (
	ErrUserNotFound  = errors.New("user not found in context")
	ErrTokenNotFound = errors.New("token not found in context")
)

// GetUser retrieves the user profile from the fiber context
func GetUser(c *fiber.Ctx) (*supabase.UserProfile, error) {
	user, ok := c.Locals("user").(*supabase.UserProfile)
	if !ok || user == nil {
		slog.Error("User not found in context")
		return nil, ErrUserNotFound
	}
	return user, nil
}

// GetToken retrieves the auth token from the fiber context
func GetToken(c *fiber.Ctx) (string, error) {
	token, ok := c.Locals("token").(string)
	if !ok || token == "" {
		slog.Error("Token not found in context")
		return "", ErrTokenNotFound
	}
	return token, nil
}

// JSONError sends a JSON error response with the specified status code and message
func JSONError(c *fiber.Ctx, status int, message string) error {
	return c.Status(status).JSON(fiber.Map{
		"error": message,
	})
}

// JSONInternalError logs the error and sends a generic internal server error response
func JSONInternalError(c *fiber.Ctx, err error) error {
	slog.Error("Internal server error", "error", err)
	return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
		"error": err.Error(),
	})
}
