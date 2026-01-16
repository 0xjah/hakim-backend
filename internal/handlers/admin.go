package handlers

import (
	"log/slog"

	"github.com/gofiber/fiber/v2"
	"github.com/hakim/backend/internal/utils"
	"github.com/hakim/backend/pkg/supabase"
)

type AdminHandler struct {
	client *supabase.Client
}

func NewAdminHandler(client *supabase.Client) *AdminHandler {
	return &AdminHandler{client: client}
}

func (h *AdminHandler) ListComplaints(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	status := c.Query("status")
	departmentID := c.Query("department_id")
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 20)

	complaints, err := h.client.GetAllComplaints(token, status, departmentID, page, limit)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(fiber.Map{
		"data":  complaints,
		"page":  page,
		"limit": limit,
	})
}

func (h *AdminHandler) GetComplaint(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	complaint, err := h.client.GetComplaintAdmin(token, id)
	if err != nil {
		slog.Warn("Complaint not found (admin)", "id", id, "error", err)
		return utils.JSONError(c, fiber.StatusNotFound, "Complaint not found")
	}

	return c.JSON(complaint)
}

func (h *AdminHandler) AssignComplaint(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	var req struct {
		AssigneeID string `json:"assignee_id"`
	}
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	complaint, err := h.client.AssignComplaint(token, id, req.AssigneeID, user.ID.String())
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(complaint)
}

func (h *AdminHandler) UpdateStatus(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	user, err := utils.GetUser(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	id := c.Params("id")

	var req struct {
		Status string `json:"status"`
		Note   string `json:"note"`
	}
	if err := c.BodyParser(&req); err != nil {
		slog.Warn("Invalid request body", "error", err)
		return utils.JSONError(c, fiber.StatusBadRequest, "Invalid request body")
	}

	complaint, err := h.client.UpdateComplaintStatus(token, id, req.Status, req.Note, user.ID.String())
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(complaint)
}

func (h *AdminHandler) GetAnalytics(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	departmentID := c.Query("department_id")

	analytics, err := h.client.GetAnalytics(token, departmentID)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(analytics)
}

func (h *AdminHandler) ListEmployees(c *fiber.Ctx) error {
	token, err := utils.GetToken(c)
	if err != nil {
		return utils.JSONError(c, fiber.StatusUnauthorized, "Unauthorized")
	}

	departmentID := c.Query("department_id")

	employees, err := h.client.GetEmployees(token, departmentID)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(employees)
}

func (h *AdminHandler) ListDepartments(c *fiber.Ctx) error {
	departments, err := h.client.GetDepartments()
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(departments)
}

func (h *AdminHandler) ListCategories(c *fiber.Ctx) error {
	departmentID := c.Query("department_id")

	categories, err := h.client.GetCategoriesByDepartment(departmentID)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(categories)
}
