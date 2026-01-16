package supabase

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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

	// Use provided token if available, otherwise use the anon key
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

// Auth methods
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
	// First get the user info from auth
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

	// Then get the profile
	profileResp, err := c.doRequest("GET", "/rest/v1/profiles?id=eq."+authUser.ID, nil, token)
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
	resp, err := c.doRequest("PATCH", "/rest/v1/profiles?id=eq."+userID, req, token)
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

// Public data methods
func (c *Client) GetDepartments() ([]models.Department, error) {
	resp, err := c.doRequest("GET", "/rest/v1/departments?select=*&is_active=eq.true", nil, "")
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
	resp, err := c.doRequest("GET", "/rest/v1/categories?select=*&is_active=eq.true", nil, "")
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
	query := "/rest/v1/categories?select=*&is_active=eq.true"
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

// Placeholder methods - implement as needed
func (c *Client) CreateComplaint(token, userID string, req *models.CreateComplaintRequest, classification *ClassificationResult) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetUserComplaints(token, userID, status string, page, limit int) ([]models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetComplaint(token, id, userID string) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) UpdateComplaint(token, id, userID string, req *models.UpdateComplaintRequest) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) CreateFeedback(token, complaintID, userID string, rating int, comment string) (*models.Feedback, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetStatusHistory(token, complaintID string) ([]models.StatusHistory, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetAllComplaints(token, status, departmentID string, page, limit int) ([]models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetComplaintAdmin(token, id string) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) AssignComplaint(token, id, assigneeID, changedBy string) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) UpdateComplaintStatus(token, id, status, note, changedBy string) (*models.Complaint, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetAnalytics(token, departmentID string) (*models.DashboardAnalytics, error) {
	return nil, fmt.Errorf("not implemented")
}

func (c *Client) GetEmployees(token, departmentID string) ([]UserProfile, error) {
	return nil, fmt.Errorf("not implemented")
}
