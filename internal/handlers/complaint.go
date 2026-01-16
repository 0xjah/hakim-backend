package handlers

import (
	"log/slog"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/hakim/backend/internal/ai"
	"github.com/hakim/backend/internal/models"
	"github.com/hakim/backend/internal/utils"
	"github.com/hakim/backend/pkg/supabase"
)

type ComplaintHandler struct {
	client     *supabase.Client
	classifier *ai.Classifier
}

func NewComplaintHandler(client *supabase.Client, classifier *ai.Classifier) *ComplaintHandler {
	return &ComplaintHandler{
		client:     client,
		classifier: classifier,
	}
}

func (h *ComplaintHandler) Create(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	var req models.CreateComplaintRequest
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	if req.Title == "" || req.Description == "" {
		return utils.JSONError(c, fiber.StatusBadRequest, "Title and description are required")
	}

	// AI classification
	classification, err := h.classifier.Classify(req.Title, req.Description)
	if err != nil {
		slog.Warn("AI classification failed", "error", err)
		// Continue without classification
	}

	// If no category provided, use AI suggestion
	if req.CategoryID == uuid.Nil && classification != nil {
		req.CategoryID = classification.CategoryID
	}

	complaint, err := h.client.CreateComplaint(token, user.ID.String(), &req, classification)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(complaint)
}

func (h *ComplaintHandler) List(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	status := c.Query("status")
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 10)

	complaints, err := h.client.GetUserComplaints(token, user.ID.String(), status, page, limit)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(fiber.Map{
		"data":  complaints,
		"page":  page,
		"limit": limit,
	})
}

func (h *ComplaintHandler) Get(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	complaint, err := h.client.GetComplaint(token, id, user.ID.String())
	if err != nil {
		slog.Warn("Complaint not found", "id", id, "error", err)
		return utils.JSONError(c, fiber.StatusNotFound, "Complaint not found")
	}

	return c.JSON(complaint)
}

func (h *ComplaintHandler) Update(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	var req models.UpdateComplaintRequest
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	complaint, err := h.client.UpdateComplaint(token, id, user.ID.String(), &req)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(complaint)
}

func (h *ComplaintHandler) SubmitFeedback(c *fiber.Ctx) error {
	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	var req struct {
		Rating  int    `json:"rating"`
		Comment string `json:"comment"`
	}
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	if req.Rating < 1 || req.Rating > 5 {
		return utils.JSONError(c, fiber.StatusBadRequest, "Rating must be between 1 and 5")
	}

	feedback, err := h.client.CreateFeedback(token, id, user.ID.String(), req.Rating, req.Comment)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(feedback)
}

func (h *ComplaintHandler) GetStatusHistory(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	history, err := h.client.GetStatusHistory(token, id)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(history)
}
