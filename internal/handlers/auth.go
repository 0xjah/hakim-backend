package handlers

import (
	"log/slog"

	"github.com/gofiber/fiber/v2"
	"github.com/hakim/backend/internal/models"
	"github.com/hakim/backend/internal/utils"
	"github.com/hakim/backend/pkg/supabase"
)

type AuthHandler struct {
	client *supabase.Client
}

func NewAuthHandler(client *supabase.Client) *AuthHandler {
	return &AuthHandler{client: client}
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req models.AuthRequest
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	if req.Email == "" || req.Password == "" {
		return utils.JSONError(c, fiber.StatusBadRequest, "Email and password are required")
	}

	result, err := h.client.SignUp(req.Email, req.Password, req.FullName, req.Phone)
	if err != nil {
		return utils.JSONError(c, fiber.StatusBadRequest, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(result)
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req models.AuthRequest
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	if req.Email == "" || req.Password == "" {
		return utils.JSONError(c, fiber.StatusBadRequest, "Email and password are required")
	}

	result, err := h.client.SignIn(req.Email, req.Password)
	if err != nil {
		slog.Warn("Login failed", "email", req.Email, "error", err)
		return utils.JSONError(c, fiber.StatusUnauthorized, "Invalid credentials")
	}

	return c.JSON(result)
}

func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	result, err := h.client.RefreshToken(req.RefreshToken)
	if err != nil {
		slog.Warn("Refresh token failed", "error", err)
		return utils.JSONError(c, fiber.StatusUnauthorized, "Invalid refresh token")
	}

	return c.JSON(result)
}

func (h *AuthHandler) GetProfile(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}
	return c.JSON(user)
}

func (h *AuthHandler) UpdateProfile(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	var req models.UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	updated, err := h.client.UpdateProfile(token, user.ID.String(), req)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(updated)
}
