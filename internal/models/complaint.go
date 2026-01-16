package models

import (
	"time"

	"github.com/google/uuid"
)

type ComplaintStatus string

const (
	StatusSubmitted   ComplaintStatus = "submitted"
	StatusUnderReview ComplaintStatus = "under_review"
	StatusAssigned    ComplaintStatus = "assigned"
	StatusInProgress  ComplaintStatus = "in_progress"
	StatusResolved    ComplaintStatus = "resolved"
	StatusClosed      ComplaintStatus = "closed"
	StatusRejected    ComplaintStatus = "rejected"
)

type ComplaintPriority string

const (
	PriorityLow      ComplaintPriority = "low"
	PriorityMedium   ComplaintPriority = "medium"
	PriorityHigh     ComplaintPriority = "high"
	PriorityCritical ComplaintPriority = "critical"
)

type Complaint struct {
	ID                 uuid.UUID         `json:"id"`
	TrackingNumber     string            `json:"tracking_number"`
	UserID             uuid.UUID         `json:"user_id"`
	CategoryID         uuid.UUID         `json:"category_id"`
	DepartmentID       uuid.UUID         `json:"department_id"`
	AssignedTo         *uuid.UUID        `json:"assigned_to,omitempty"`
	Title              string            `json:"title"`
	Description        string            `json:"description"`
	Status             ComplaintStatus   `json:"status"`
	Priority           ComplaintPriority `json:"priority"`
	Latitude           *float64          `json:"latitude,omitempty"`
	Longitude          *float64          `json:"longitude,omitempty"`
	Address            string            `json:"address,omitempty"`
	AISummary          string            `json:"ai_summary,omitempty"`
	AIClassification   string            `json:"ai_classification,omitempty"`
	AIConfidence       float64           `json:"ai_confidence"`
	ExpectedResolution *time.Time        `json:"expected_resolution,omitempty"`
	ResolvedAt         *time.Time        `json:"resolved_at,omitempty"`
	CreatedAt          time.Time         `json:"created_at"`
	UpdatedAt          time.Time         `json:"updated_at"`

	// Relations
	Category   *Category   `json:"category,omitempty"`
	Department *Department `json:"department,omitempty"`
	User       *Profile    `json:"user,omitempty"`
	Assignee   *Profile    `json:"assignee,omitempty"`
}

type CreateComplaintRequest struct {
	Title       string    `json:"title" validate:"required,min=10,max=200"`
	Description string    `json:"description" validate:"required,min=20"`
	CategoryID  uuid.UUID `json:"category_id" validate:"required"`
	Latitude    *float64  `json:"latitude,omitempty"`
	Longitude   *float64  `json:"longitude,omitempty"`
	Address     string    `json:"address,omitempty"`
	Attachments []string  `json:"attachments,omitempty"`
}

type UpdateComplaintRequest struct {
	Title       *string            `json:"title,omitempty"`
	Description *string            `json:"description,omitempty"`
	Status      *ComplaintStatus   `json:"status,omitempty"`
	Priority    *ComplaintPriority `json:"priority,omitempty"`
}

type StatusHistory struct {
	ID          uuid.UUID       `json:"id"`
	ComplaintID uuid.UUID       `json:"complaint_id"`
	OldStatus   ComplaintStatus `json:"old_status"`
	NewStatus   ComplaintStatus `json:"new_status"`
	ChangedBy   uuid.UUID       `json:"changed_by"`
	Note        string          `json:"note,omitempty"`
	CreatedAt   time.Time       `json:"created_at"`
}

type ComplaintAttachment struct {
	ID          uuid.UUID `json:"id"`
	ComplaintID uuid.UUID `json:"complaint_id"`
	FileName    string    `json:"file_name"`
	FileURL     string    `json:"file_url"`
	FileType    string    `json:"file_type"`
	FileSize    int64     `json:"file_size"`
	CreatedAt   time.Time `json:"created_at"`
}

type Feedback struct {
	ID          uuid.UUID `json:"id"`
	ComplaintID uuid.UUID `json:"complaint_id"`
	UserID      uuid.UUID `json:"user_id"`
	Rating      int       `json:"rating" validate:"required,min=1,max=5"`
	Comment     string    `json:"comment,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}
