package models

import (
	"time"

	"github.com/google/uuid"
)

type UserRole string

const (
	RoleCitizen    UserRole = "citizen"
	RoleEmployee   UserRole = "employee"
	RoleAdmin      UserRole = "admin"
	RoleSuperAdmin UserRole = "super_admin"
)

type Profile struct {
	ID                   uuid.UUID  `json:"id"`
	Email                string     `json:"email"`
	FullName             string     `json:"full_name,omitempty"`
	Phone                string     `json:"phone,omitempty"`
	NationalID           string     `json:"national_id,omitempty"`
	AvatarURL            string     `json:"avatar_url,omitempty"`
	Role                 UserRole   `json:"role"`
	DepartmentID         *uuid.UUID `json:"department_id,omitempty"`
	Language             string     `json:"language"`
	NotificationsEnabled bool       `json:"notifications_enabled"`
	IsActive             bool       `json:"is_active"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}

type AuthRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
	FullName string `json:"full_name,omitempty"`
	Phone    string `json:"phone,omitempty"`
}

type AuthResponse struct {
	AccessToken  string   `json:"access_token"`
	RefreshToken string   `json:"refresh_token"`
	ExpiresIn    int      `json:"expires_in"`
	User         *Profile `json:"user"`
}

type UpdateProfileRequest struct {
	FullName             *string `json:"full_name,omitempty"`
	Phone                *string `json:"phone,omitempty"`
	NationalID           *string `json:"national_id,omitempty"`
	Language             *string `json:"language,omitempty"`
	NotificationsEnabled *bool   `json:"notifications_enabled,omitempty"`
}
