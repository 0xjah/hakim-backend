package models

import (
	"time"

	"github.com/google/uuid"
)

type Department struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	NameAr      string    `json:"name_ar"`
	Description string    `json:"description,omitempty"`
	Email       string    `json:"email,omitempty"`
	Phone       string    `json:"phone,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Category struct {
	ID           uuid.UUID `json:"id"`
	DepartmentID uuid.UUID `json:"department_id"`
	Name         string    `json:"name"`
	NameAr       string    `json:"name_ar"`
	Description  string    `json:"description,omitempty"`
	Icon         string    `json:"icon,omitempty"`
	IsActive     bool      `json:"is_active"`
	SLADays      int       `json:"sla_days"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Notification struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	Type      string    `json:"type"`
	Data      string    `json:"data,omitempty"`
	IsRead    bool      `json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}
