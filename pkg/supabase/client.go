package supabase

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/hakim/backend/internal/config"
	"github.com/hakim/backend/internal/models"
)

// ClassificationResult holds AI classification data
type ClassificationResult struct {
	CategoryID   uuid.UUID `json:"category_id"`
	DepartmentID uuid.UUID `json:"department_id"`
	Priority     string    `json:"priority"`
	Confidence   float64   `json:"confidence"`
	Summary      string    `json:"summary"`
}

type Client struct {
	httpClient *http.Client
	baseURL    string
	apiKey     string
}

type UserProfile struct {
	ID                   uuid.UUID  `json:"id"`
	Email                string     `json:"email"`
	FullName             string     `json:"full_name"`
	Phone                string     `json:"phone"`
	NationalID           string     `json:"national_id"`
	AvatarURL            string     `json:"avatar_url"`
	Role                 string     `json:"role"`
	DepartmentID         *uuid.UUID `json:"department_id"`
	Language             string     `json:"language"`
	NotificationsEnabled bool       `json:"notifications_enabled"`
	IsActive             bool       `json:"is_active"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}

type Category struct {
	ID           uuid.UUID `json:"id"`
	DepartmentID uuid.UUID `json:"department_id"`
	Name         string    `json:"name"`
	NameAr       string    `json:"name_ar"`
	Description  string    `json:"description"`
	Icon         string    `json:"icon"`
	IsActive     bool      `json:"is_active"`
	SLADays      int       `json:"sla_days"`
}

func New() *Client {
	return &Client{
		httpClient: &http.Client{Timeout: 30 * time.Second},
		baseURL:    config.AppConfig.SupabaseURL,
		apiKey:     config.AppConfig.SupabaseKey,
	}
}

func (c *Client) doRequest(method, path string, body interface{}, token string) ([]byte, error) {
	var bodyReader io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		bodyReader = bytes.NewReader(jsonBody)
	}

	req, err := http.NewRequest(method, c.baseURL+path, bodyReader)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", c.apiKey)
	req.Header.Set("Prefer", "return=representation")

	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	} else {
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}

// ============================================
// AUTH METHODS
// ============================================

func (c *Client) SignUp(email, password, fullName, phone string) (*models.AuthResponse, error) {
	body := map[string]interface{}{
		"email":    email,
		"password": password,
		"data": map[string]string{
			"full_name": fullName,
			"phone":     phone,
		},
	}

	resp, err := c.doRequest("POST", "/auth/v1/signup", body, "")
	if err != nil {
		return nil, err
	}

	var result struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresIn    int    `json:"expires_in"`
		User         struct {
			ID    string `json:"id"`
			Email string `json:"email"`
		} `json:"user"`
	}

	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &models.AuthResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		ExpiresIn:    result.ExpiresIn,
	}, nil
}

func (c *Client) SignIn(email, password string) (*models.AuthResponse, error) {
	body := map[string]string{
		"email":    email,
		"password": password,
	}

	resp, err := c.doRequest("POST", "/auth/v1/token?grant_type=password", body, "")
	if err != nil {
		return nil, err
	}

	var result struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresIn    int    `json:"expires_in"`
	}

	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &models.AuthResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		ExpiresIn:    result.ExpiresIn,
	}, nil
}

func (c *Client) RefreshToken(refreshToken string) (*models.AuthResponse, error) {
	body := map[string]string{
		"refresh_token": refreshToken,
	}

	resp, err := c.doRequest("POST", "/auth/v1/token?grant_type=refresh_token", body, "")
	if err != nil {
		return nil, err
	}

	var result models.AuthResponse
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, err
	}

	return &result, nil
}

func (c *Client) GetUser(token string) (*UserProfile, error) {
	resp, err := c.doRequest("GET", "/auth/v1/user", nil, token)
	if err != nil {
		return nil, err
	}

	var authUser struct {
		ID    string `json:"id"`
		Email string `json:"email"`
	}
	if err := json.Unmarshal(resp, &authUser); err != nil {
		return nil, err
	}

	profileResp, err := c.doRequest("GET", "/rest/v1/profiles?id=eq."+authUser.ID+"&select=*", nil, token)
	if err != nil {
		return nil, err
	}

	var profiles []UserProfile
	if err := json.Unmarshal(profileResp, &profiles); err != nil {
		return nil, err
	}

	if len(profiles) == 0 {
		return nil, fmt.Errorf("user profile not found")
	}

	return &profiles[0], nil
}

func (c *Client) UpdateProfile(token, userID string, req models.UpdateProfileRequest) (*UserProfile, error) {
	resp, err := c.doRequest("PATCH", "/rest/v1/profiles?id=eq."+userID+"&select=*", req, token)
	if err != nil {
		return nil, err
	}

	var profiles []UserProfile
	if err := json.Unmarshal(resp, &profiles); err != nil {
		return nil, err
	}

	if len(profiles) == 0 {
		return nil, fmt.Errorf("profile not updated")
	}

	return &profiles[0], nil
}

// ============================================
// PUBLIC DATA METHODS
// ============================================

func (c *Client) GetDepartments() ([]models.Department, error) {
	resp, err := c.doRequest("GET", "/rest/v1/departments?select=*&is_active=eq.true&order=name_ar.asc", nil, "")
	if err != nil {
		return nil, err
	}

	var departments []models.Department
	if err := json.Unmarshal(resp, &departments); err != nil {
		return nil, err
	}

	return departments, nil
}

func (c *Client) GetCategories() ([]Category, error) {
	resp, err := c.doRequest("GET", "/rest/v1/categories?select=*&is_active=eq.true&order=name_ar.asc", nil, "")
	if err != nil {
		return nil, err
	}

	var categories []Category
	if err := json.Unmarshal(resp, &categories); err != nil {
		return nil, err
	}

	return categories, nil
}

func (c *Client) GetCategoriesByDepartment(departmentID string) ([]models.Category, error) {
	query := "/rest/v1/categories?select=*&is_active=eq.true&order=name_ar.asc"
	if departmentID != "" {
		query += "&department_id=eq." + departmentID
	}

	resp, err := c.doRequest("GET", query, nil, "")
	if err != nil {
		return nil, err
	}

	var categories []models.Category
	if err := json.Unmarshal(resp, &categories); err != nil {
		return nil, err
	}

	return categories, nil
}

// ============================================
// COMPLAINT METHODS
// ============================================

// complaintInsert is the structure for inserting a complaint into Supabase
type complaintInsert struct {
	UserID               string   `json:"user_id"`
	Title                string   `json:"title"`
	Description          string   `json:"description"`
	CategoryID           string   `json:"category_id,omitempty"`
	DepartmentID         string   `json:"department_id,omitempty"`
	Status               string   `json:"status"`
	Priority             string   `json:"priority"`
	Latitude             *float64 `json:"latitude,omitempty"`
	Longitude            *float64 `json:"longitude,omitempty"`
	Address              string   `json:"address,omitempty"`
	AICategoryConfidence float64  `json:"ai_category_confidence,omitempty"`
}

// complaintRow matches the database row structure
type complaintRow struct {
	ID                   string    `json:"id"`
	TrackingNumber       string    `json:"tracking_number"`
	UserID               string    `json:"user_id"`
	CategoryID           *string   `json:"category_id"`
	DepartmentID         *string   `json:"department_id"`
	AssignedTo           *string   `json:"assigned_to"`
	Title                string    `json:"title"`
	Description          string    `json:"description"`
	Status               string    `json:"status"`
	Priority             string    `json:"priority"`
	Latitude             *float64  `json:"latitude"`
	Longitude            *float64  `json:"longitude"`
	Address              *string   `json:"address"`
	AICategoryConfidence *float64  `json:"ai_category_confidence"`
	SLADeadline          *string   `json:"sla_deadline"`
	EscalationLevel      int       `json:"escalation_level"`
	IsEscalated          bool      `json:"is_escalated"`
	ResolvedAt           *string   `json:"resolved_at"`
	ClosedAt             *string   `json:"closed_at"`
	CreatedAt            string    `json:"created_at"`
	UpdatedAt            string    `json:"updated_at"`
	Categories           *Category `json:"categories,omitempty"`
	Departments          *struct {
		ID     string `json:"id"`
		Name   string `json:"name"`
		NameAr string `json:"name_ar"`
	} `json:"departments,omitempty"`
}

func rowToComplaint(row *complaintRow) *models.Complaint {
	complaint := &models.Complaint{
		ID:             uuid.MustParse(row.ID),
		TrackingNumber: row.TrackingNumber,
		UserID:         uuid.MustParse(row.UserID),
		Title:          row.Title,
		Description:    row.Description,
		Status:         models.ComplaintStatus(row.Status),
		Priority:       models.ComplaintPriority(row.Priority),
		Latitude:       row.Latitude,
		Longitude:      row.Longitude,
	}

	if row.CategoryID != nil {
		complaint.CategoryID = uuid.MustParse(*row.CategoryID)
	}
	if row.DepartmentID != nil {
		complaint.DepartmentID = uuid.MustParse(*row.DepartmentID)
	}
	if row.AssignedTo != nil {
		assignedID := uuid.MustParse(*row.AssignedTo)
		complaint.AssignedTo = &assignedID
	}
	if row.Address != nil {
		complaint.Address = *row.Address
	}
	if row.AICategoryConfidence != nil {
		complaint.AIConfidence = *row.AICategoryConfidence
	}
	if row.ResolvedAt != nil {
		if t, err := time.Parse(time.RFC3339, *row.ResolvedAt); err == nil {
			complaint.ResolvedAt = &t
		}
	}
	if t, err := time.Parse(time.RFC3339, row.CreatedAt); err == nil {
		complaint.CreatedAt = t
	}
	if t, err := time.Parse(time.RFC3339, row.UpdatedAt); err == nil {
		complaint.UpdatedAt = t
	}

	if row.Categories != nil {
		complaint.Category = &models.Category{
			ID:           row.Categories.ID,
			DepartmentID: row.Categories.DepartmentID,
			Name:         row.Categories.Name,
			NameAr:       row.Categories.NameAr,
			Icon:         row.Categories.Icon,
		}
	}
	if row.Departments != nil {
		complaint.Department = &models.Department{
			ID:     uuid.MustParse(row.Departments.ID),
			Name:   row.Departments.Name,
			NameAr: row.Departments.NameAr,
		}
	}

	return complaint
}

func (c *Client) CreateComplaint(token, userID string, req *models.CreateComplaintRequest, classification *ClassificationResult) (*models.Complaint, error) {
	insert := complaintInsert{
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
		Status:      string(models.StatusSubmitted),
		Priority:    string(models.PriorityMedium),
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
		Address:     req.Address,
	}

	// AI classification takes precedence
	if classification != nil {
		if classification.CategoryID != uuid.Nil {
			insert.CategoryID = classification.CategoryID.String()
		}
		if classification.DepartmentID != uuid.Nil {
			insert.DepartmentID = classification.DepartmentID.String()
		}
		if classification.Priority != "" {
			insert.Priority = classification.Priority
		}
		insert.AICategoryConfidence = classification.Confidence
	} else if req.CategoryID != uuid.Nil {
		// Fallback to user-provided category only if no AI classification
		insert.CategoryID = req.CategoryID.String()
	}

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	resp, err := c.doRequest("POST", "/rest/v1/complaints?select="+url.QueryEscape(selectFields), insert, token)
	if err != nil {
		return nil, fmt.Errorf("failed to create complaint: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint response: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint was not created")
	}

	complaint := rowToComplaint(&rows[0])

	// Insert attachments if provided
	if len(req.Attachments) > 0 {
		for _, fileURL := range req.Attachments {
			attachmentInsert := map[string]interface{}{
				"complaint_id": complaint.ID.String(),
				"file_url":     fileURL,
				"file_type":    "image",
			}
			_, _ = c.doRequest("POST", "/rest/v1/attachments", attachmentInsert, token)
		}
	}

	return complaint, nil
}

func (c *Client) GetUserComplaints(token, userID, status string, page, limit int) ([]models.Complaint, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	offset := (page - 1) * limit

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) +
		"&user_id=eq." + userID +
		"&order=created_at.desc" +
		"&limit=" + strconv.Itoa(limit) +
		"&offset=" + strconv.Itoa(offset)

	if status != "" {
		query += "&status=eq." + status
	}

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get complaints: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaints: %w", err)
	}

	complaints := make([]models.Complaint, 0, len(rows))
	for i := range rows {
		complaints = append(complaints, *rowToComplaint(&rows[i]))
	}

	return complaints, nil
}

func (c *Client) GetComplaint(token, id, userID string) (*models.Complaint, error) {
	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) +
		"&id=eq." + id +
		"&user_id=eq." + userID

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get complaint: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint not found")
	}

	return rowToComplaint(&rows[0]), nil
}

func (c *Client) UpdateComplaint(token, id, userID string, req *models.UpdateComplaintRequest) (*models.Complaint, error) {
	update := make(map[string]interface{})

	if req.Title != nil {
		update["title"] = *req.Title
	}
	if req.Description != nil {
		update["description"] = *req.Description
	}
	if req.Status != nil {
		update["status"] = string(*req.Status)
	}
	if req.Priority != nil {
		update["priority"] = string(*req.Priority)
	}

	if len(update) == 0 {
		return c.GetComplaint(token, id, userID)
	}

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) +
		"&id=eq." + id +
		"&user_id=eq." + userID

	resp, err := c.doRequest("PATCH", query, update, token)
	if err != nil {
		return nil, fmt.Errorf("failed to update complaint: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint not found or not authorized")
	}

	return rowToComplaint(&rows[0]), nil
}

// ============================================
// FEEDBACK METHODS
// ============================================

type feedbackRow struct {
	ID          string  `json:"id"`
	ComplaintID string  `json:"complaint_id"`
	UserID      string  `json:"user_id"`
	Rating      int     `json:"rating"`
	Comment     *string `json:"comment"`
	CreatedAt   string  `json:"created_at"`
}

func (c *Client) CreateFeedback(token, complaintID, userID string, rating int, comment string) (*models.Feedback, error) {
	insert := map[string]interface{}{
		"complaint_id": complaintID,
		"user_id":      userID,
		"rating":       rating,
	}
	if comment != "" {
		insert["comment"] = comment
	}

	resp, err := c.doRequest("POST", "/rest/v1/feedback?select=*", insert, token)
	if err != nil {
		return nil, fmt.Errorf("failed to create feedback: %w", err)
	}

	var rows []feedbackRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse feedback: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("feedback was not created")
	}

	row := rows[0]
	feedback := &models.Feedback{
		ID:          uuid.MustParse(row.ID),
		ComplaintID: uuid.MustParse(row.ComplaintID),
		UserID:      uuid.MustParse(row.UserID),
		Rating:      row.Rating,
	}
	if row.Comment != nil {
		feedback.Comment = *row.Comment
	}
	if t, err := time.Parse(time.RFC3339, row.CreatedAt); err == nil {
		feedback.CreatedAt = t
	}

	return feedback, nil
}

// ============================================
// STATUS HISTORY METHODS
// ============================================

type statusHistoryRow struct {
	ID          string  `json:"id"`
	ComplaintID string  `json:"complaint_id"`
	OldStatus   *string `json:"old_status"`
	NewStatus   string  `json:"new_status"`
	ChangedBy   *string `json:"changed_by"`
	Notes       *string `json:"notes"`
	CreatedAt   string  `json:"created_at"`
}

func (c *Client) GetStatusHistory(token, complaintID string) ([]models.StatusHistory, error) {
	query := "/rest/v1/status_history?select=*&complaint_id=eq." + complaintID + "&order=created_at.desc"

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get status history: %w", err)
	}

	var rows []statusHistoryRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse status history: %w", err)
	}

	history := make([]models.StatusHistory, 0, len(rows))
	for _, row := range rows {
		h := models.StatusHistory{
			ID:          uuid.MustParse(row.ID),
			ComplaintID: uuid.MustParse(row.ComplaintID),
			NewStatus:   models.ComplaintStatus(row.NewStatus),
		}
		if row.OldStatus != nil {
			h.OldStatus = models.ComplaintStatus(*row.OldStatus)
		}
		if row.ChangedBy != nil {
			h.ChangedBy = uuid.MustParse(*row.ChangedBy)
		}
		if row.Notes != nil {
			h.Note = *row.Notes
		}
		if t, err := time.Parse(time.RFC3339, row.CreatedAt); err == nil {
			h.CreatedAt = t
		}
		history = append(history, h)
	}

	return history, nil
}

// ============================================
// ADMIN METHODS
// ============================================

func (c *Client) GetAllComplaints(token, status, departmentID string, page, limit int) ([]models.Complaint, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) +
		"&order=created_at.desc" +
		"&limit=" + strconv.Itoa(limit) +
		"&offset=" + strconv.Itoa(offset)

	if status != "" {
		query += "&status=eq." + status
	}
	if departmentID != "" {
		query += "&department_id=eq." + departmentID
	}

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get complaints: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaints: %w", err)
	}

	complaints := make([]models.Complaint, 0, len(rows))
	for i := range rows {
		complaints = append(complaints, *rowToComplaint(&rows[i]))
	}

	return complaints, nil
}

func (c *Client) GetComplaintAdmin(token, id string) (*models.Complaint, error) {
	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) + "&id=eq." + id

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get complaint: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint not found")
	}

	return rowToComplaint(&rows[0]), nil
}

func (c *Client) AssignComplaint(token, id, assigneeID, changedBy string) (*models.Complaint, error) {
	update := map[string]interface{}{
		"assigned_to": assigneeID,
		"status":      string(models.StatusAssigned),
	}

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) + "&id=eq." + id

	resp, err := c.doRequest("PATCH", query, update, token)
	if err != nil {
		return nil, fmt.Errorf("failed to assign complaint: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint not found")
	}

	// Log the status change manually
	historyInsert := map[string]interface{}{
		"complaint_id": id,
		"new_status":   string(models.StatusAssigned),
		"changed_by":   changedBy,
		"notes":        "تم تعيين الشكوى إلى موظف",
	}
	_, _ = c.doRequest("POST", "/rest/v1/status_history", historyInsert, token)

	return rowToComplaint(&rows[0]), nil
}

func (c *Client) UpdateComplaintStatus(token, id, status, note, changedBy string) (*models.Complaint, error) {
	update := map[string]interface{}{
		"status": status,
	}

	// Set resolved_at timestamp when resolving
	if status == string(models.StatusResolved) {
		update["resolved_at"] = time.Now().UTC().Format(time.RFC3339)
	}

	selectFields := "id,tracking_number,user_id,category_id,department_id,assigned_to,title,description,status,priority,latitude,longitude,address,ai_category_confidence,resolved_at,created_at,updated_at,categories(id,department_id,name,name_ar,icon),departments(id,name,name_ar)"

	query := "/rest/v1/complaints?select=" + url.QueryEscape(selectFields) + "&id=eq." + id

	resp, err := c.doRequest("PATCH", query, update, token)
	if err != nil {
		return nil, fmt.Errorf("failed to update complaint status: %w", err)
	}

	var rows []complaintRow
	if err := json.Unmarshal(resp, &rows); err != nil {
		return nil, fmt.Errorf("failed to parse complaint: %w", err)
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf("complaint not found")
	}

	// Log the status change manually with note
	historyInsert := map[string]interface{}{
		"complaint_id": id,
		"new_status":   status,
		"changed_by":   changedBy,
	}
	if note != "" {
		historyInsert["notes"] = note
	}
	_, _ = c.doRequest("POST", "/rest/v1/status_history", historyInsert, token)

	return rowToComplaint(&rows[0]), nil
}

// ============================================
// ANALYTICS METHODS
// ============================================

func (c *Client) GetAnalytics(token, departmentID string) (*models.DashboardAnalytics, error) {
	analytics := &models.DashboardAnalytics{
		ComplaintsByStatus:   make([]models.StatusCount, 0),
		ComplaintsByCategory: make([]models.CategoryCount, 0),
		ComplaintsTrend:      make([]models.DailyCount, 0),
	}

	// Build base query
	baseQuery := "/rest/v1/complaints?select=id,status,category_id,created_at,resolved_at"
	if departmentID != "" {
		baseQuery += "&department_id=eq." + departmentID
	}

	resp, err := c.doRequest("GET", baseQuery, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get complaints for analytics: %w", err)
	}

	var complaints []struct {
		ID         string  `json:"id"`
		Status     string  `json:"status"`
		CategoryID *string `json:"category_id"`
		CreatedAt  string  `json:"created_at"`
		ResolvedAt *string `json:"resolved_at"`
	}
	if err := json.Unmarshal(resp, &complaints); err != nil {
		return nil, fmt.Errorf("failed to parse complaints: %w", err)
	}

	// Calculate metrics
	statusCounts := make(map[string]int)
	categoryCounts := make(map[string]int)
	dailyCounts := make(map[string]int)
	var totalResolutionHours float64
	resolvedCount := 0

	for _, comp := range complaints {
		analytics.TotalComplaints++

		statusCounts[comp.Status]++

		if comp.Status != string(models.StatusResolved) && comp.Status != string(models.StatusClosed) && comp.Status != string(models.StatusRejected) {
			analytics.PendingComplaints++
		}

		if comp.Status == string(models.StatusResolved) || comp.Status == string(models.StatusClosed) {
			analytics.ResolvedComplaints++
		}

		if comp.CategoryID != nil {
			categoryCounts[*comp.CategoryID]++
		}

		if createdAt, err := time.Parse(time.RFC3339, comp.CreatedAt); err == nil {
			dateKey := createdAt.Format("2006-01-02")
			dailyCounts[dateKey]++

			if comp.ResolvedAt != nil {
				if resolvedAt, err := time.Parse(time.RFC3339, *comp.ResolvedAt); err == nil {
					hours := resolvedAt.Sub(createdAt).Hours()
					totalResolutionHours += hours
					resolvedCount++
				}
			}
		}
	}

	// Calculate average resolution time
	if resolvedCount > 0 {
		analytics.AverageResolutionTime = totalResolutionHours / float64(resolvedCount)
	}

	// Convert status counts to slice
	for status, count := range statusCounts {
		analytics.ComplaintsByStatus = append(analytics.ComplaintsByStatus, models.StatusCount{
			Status: status,
			Count:  count,
		})
	}

	// Get category names and convert to slice
	categories, _ := c.GetCategories()
	categoryNameMap := make(map[string]string)
	for _, cat := range categories {
		categoryNameMap[cat.ID.String()] = cat.NameAr
	}

	for catID, count := range categoryCounts {
		name := categoryNameMap[catID]
		if name == "" {
			name = "غير محدد"
		}
		analytics.ComplaintsByCategory = append(analytics.ComplaintsByCategory, models.CategoryCount{
			CategoryID:   catID,
			CategoryName: name,
			Count:        count,
		})
	}

	// Convert daily counts to slice (last 30 days)
	now := time.Now()
	for i := 29; i >= 0; i-- {
		date := now.AddDate(0, 0, -i).Format("2006-01-02")
		analytics.ComplaintsTrend = append(analytics.ComplaintsTrend, models.DailyCount{
			Date:  date,
			Count: dailyCounts[date],
		})
	}

	// Get satisfaction rate from feedback
	feedbackResp, err := c.doRequest("GET", "/rest/v1/feedback?select=rating", nil, token)
	if err == nil {
		var feedbacks []struct {
			Rating int `json:"rating"`
		}
		if json.Unmarshal(feedbackResp, &feedbacks) == nil && len(feedbacks) > 0 {
			var totalRating int
			for _, f := range feedbacks {
				totalRating += f.Rating
			}
			analytics.SatisfactionRate = float64(totalRating) / float64(len(feedbacks)) / 5.0 * 100
		}
	}

	return analytics, nil
}

func (c *Client) GetEmployees(token, departmentID string) ([]UserProfile, error) {
	query := "/rest/v1/profiles?select=*&role=in.(employee,admin)&is_active=eq.true&order=full_name.asc"

	if departmentID != "" {
		query += "&department_id=eq." + departmentID
	}

	resp, err := c.doRequest("GET", query, nil, token)
	if err != nil {
		return nil, fmt.Errorf("failed to get employees: %w", err)
	}

	var employees []UserProfile
	if err := json.Unmarshal(resp, &employees); err != nil {
		return nil, fmt.Errorf("failed to parse employees: %w", err)
	}

	return employees, nil
}

// ============================================
// PUBLIC MAP DATA METHODS
// ============================================

// PublicMapPoint represents an aggregated location on the public map
type PublicMapPoint struct {
	Lat          float64 `json:"lat"`
	Lng          float64 `json:"lng"`
	Area         string  `json:"area"`
	Category     string  `json:"category"`
	CategoryAr   string  `json:"category_ar"`
	CategoryIcon string  `json:"category_icon"`
	Status       string  `json:"status"`
	Priority     string  `json:"priority"`
	Count        int     `json:"count"`
}

// PublicMapStats represents category statistics for the public map
type PublicMapStats struct {
	Category   string `json:"category"`
	CategoryAr string `json:"category_ar"`
	Icon       string `json:"icon"`
	Total      int    `json:"total"`
	Active     int    `json:"active"`
	Resolved   int    `json:"resolved"`
	Critical   int    `json:"critical"`
	High       int    `json:"high"`
}

// GetPublicMapData returns aggregated complaint data for the public community map
// This returns anonymized location data grouped by area
func (c *Client) GetPublicMapData(category, timeRange string) ([]PublicMapPoint, error) {
	query := "/rest/v1/complaints?select=latitude,longitude,address,status,priority,category:categories(id,name,name_ar,icon)&latitude=not.is.null&longitude=not.is.null&order=created_at.desc"

	// Apply time filter
	if timeRange != "" && timeRange != "all" {
		var days int
		switch timeRange {
		case "7d":
			days = 7
		case "30d":
			days = 30
		case "90d":
			days = 90
		default:
			days = 30
		}
		fromDate := time.Now().AddDate(0, 0, -days).Format(time.RFC3339)
		query += "&created_at=gte." + fromDate
	}

	// Apply category filter - support both UUID and category name
	if category != "" && category != "all" {
		// Check if it's a valid UUID
		if _, err := uuid.Parse(category); err == nil {
			// It's a valid UUID, use directly
			query += "&category_id=eq." + category
		} else {
			// It's a category name, look up the ID first
			categories, err := c.GetCategories()
			if err == nil {
				for _, cat := range categories {
					if strings.EqualFold(cat.Name, category) || strings.EqualFold(cat.NameAr, category) {
						query += "&category_id=eq." + cat.ID.String()
						break
					}
				}
			}
			// If category name not found, skip the filter (return all)
		}
	}

	resp, err := c.doRequest("GET", query, nil, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get map data: %w", err)
	}

	var complaints []struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
		Address   string  `json:"address"`
		Status    string  `json:"status"`
		Priority  string  `json:"priority"`
		Category  *struct {
			Name   string `json:"name"`
			NameAr string `json:"name_ar"`
			Icon   string `json:"icon"`
		} `json:"category"`
	}

	if err := json.Unmarshal(resp, &complaints); err != nil {
		return nil, fmt.Errorf("failed to parse map data: %w", err)
	}

	// Aggregate by location (round to 3 decimal places)
	points := make(map[string]*PublicMapPoint)

	for _, complaint := range complaints {
		// Create location key by rounding coordinates
		lat := math.Round(complaint.Latitude*1000) / 1000
		lng := math.Round(complaint.Longitude*1000) / 1000
		key := fmt.Sprintf("%.3f_%.3f", lat, lng)

		if existing, ok := points[key]; ok {
			existing.Count++
			// Update to highest priority
			if priorityValue(complaint.Priority) > priorityValue(existing.Priority) {
				existing.Priority = complaint.Priority
			}
		} else {
			categoryName := "general"
			categoryAr := "عام"
			categoryIcon := "general"
			if complaint.Category != nil {
				categoryName = complaint.Category.Name
				categoryAr = complaint.Category.NameAr
				categoryIcon = complaint.Category.Icon
			}

			address := complaint.Address
			if address == "" {
				address = "موقع غير محدد"
			}

			points[key] = &PublicMapPoint{
				Lat:          lat,
				Lng:          lng,
				Area:         address,
				Category:     categoryName,
				CategoryAr:   categoryAr,
				CategoryIcon: categoryIcon,
				Status:       complaint.Status,
				Priority:     complaint.Priority,
				Count:        1,
			}
		}
	}

	// Convert map to slice
	result := make([]PublicMapPoint, 0, len(points))
	for _, point := range points {
		result = append(result, *point)
	}

	return result, nil
}

// GetPublicMapStats returns category statistics for the public map
func (c *Client) GetPublicMapStats() ([]PublicMapStats, error) {
	query := "/rest/v1/complaints?select=status,priority,category:categories(name,name_ar,icon)&latitude=not.is.null"

	resp, err := c.doRequest("GET", query, nil, "")
	if err != nil {
		return nil, fmt.Errorf("failed to get map stats: %w", err)
	}

	var complaints []struct {
		Status   string `json:"status"`
		Priority string `json:"priority"`
		Category *struct {
			Name   string `json:"name"`
			NameAr string `json:"name_ar"`
			Icon   string `json:"icon"`
		} `json:"category"`
	}

	if err := json.Unmarshal(resp, &complaints); err != nil {
		return nil, fmt.Errorf("failed to parse map stats: %w", err)
	}

	// Aggregate by category
	stats := make(map[string]*PublicMapStats)

	for _, complaint := range complaints {
		categoryName := "general"
		categoryAr := "عام"
		icon := "general"
		if complaint.Category != nil {
			categoryName = complaint.Category.Name
			categoryAr = complaint.Category.NameAr
			icon = complaint.Category.Icon
		}

		if _, ok := stats[categoryName]; !ok {
			stats[categoryName] = &PublicMapStats{
				Category:   categoryName,
				CategoryAr: categoryAr,
				Icon:       icon,
			}
		}

		s := stats[categoryName]
		s.Total++

		if complaint.Status == "resolved" || complaint.Status == "closed" {
			s.Resolved++
		} else {
			s.Active++
		}

		if complaint.Priority == "critical" {
			s.Critical++
		} else if complaint.Priority == "high" {
			s.High++
		}
	}

	// Convert map to slice and sort by total
	result := make([]PublicMapStats, 0, len(stats))
	for _, stat := range stats {
		result = append(result, *stat)
	}

	// Sort by total descending
	sort.Slice(result, func(i, j int) bool {
		return result[i].Total > result[j].Total
	})

	return result, nil
}

// priorityValue returns a numeric value for priority comparison
func priorityValue(priority string) int {
	switch priority {
	case "critical":
		return 4
	case "high":
		return 3
	case "medium":
		return 2
	case "low":
		return 1
	default:
		return 0
	}
}
