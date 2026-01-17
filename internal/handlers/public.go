package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/hakim/backend/internal/utils"
	"github.com/hakim/backend/pkg/supabase"
)

type PublicHandler struct {
	client *supabase.Client
}

func NewPublicHandler(client *supabase.Client) *PublicHandler {
	return &PublicHandler{
		client: client,
	}
}

// GetPublicMapData returns aggregated complaint data for the community map
// This is anonymous data that doesn't expose individual complaint details
func (h *PublicHandler) GetPublicMapData(c *fiber.Ctx) error {
	category := c.Query("category")
	timeRange := c.Query("time_range", "30d")

	data, err := h.client.GetPublicMapData(category, timeRange)
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(data)
}

// GetPublicMapStats returns category statistics for the map
func (h *PublicHandler) GetPublicMapStats(c *fiber.Ctx) error {
	stats, err := h.client.GetPublicMapStats()
	if err != nil {
		return utils.JSONInternalError(c, err)
	}

	return c.JSON(stats)
}
