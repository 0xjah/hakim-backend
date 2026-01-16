package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/hakim/backend/internal/config"
	"github.com/hakim/backend/pkg/supabase"
)

type Classifier struct {
	client     *supabase.Client
	httpClient *http.Client
}

// OpenAI request/response structures
type OpenAIRequest struct {
	Model       string          `json:"model"`
	Messages    []OpenAIMessage `json:"messages"`
	Temperature float64         `json:"temperature"`
	MaxTokens   int             `json:"max_tokens"`
}

type OpenAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

type AIClassification struct {
	CategoryName string  `json:"category_name"`
	Priority     string  `json:"priority"`
	Confidence   float64 `json:"confidence"`
	Summary      string  `json:"summary_ar"`
	Sentiment    string  `json:"sentiment"`
}

func NewClassifier(client *supabase.Client) *Classifier {
	return &Classifier{
		client:     client,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
}

func (c *Classifier) Classify(title, description string) (*supabase.ClassificationResult, error) {
	// Check if OpenAI key is configured
	if config.AppConfig.OpenAIKey != "" {
		result, err := c.classifyWithAI(title, description)
		if err == nil {
			return result, nil
		}
		// Fall back to keyword matching if AI fails
		fmt.Printf("AI classification failed, falling back to keywords: %v\n", err)
	}

	// Fallback: Simple keyword-based classification
	return c.classifyWithKeywords(title, description)
}

func (c *Classifier) classifyWithAI(title, description string) (*supabase.ClassificationResult, error) {
	// Get available categories for context
	categories, err := c.client.GetCategories()
	if err != nil {
		return nil, fmt.Errorf("failed to get categories: %w", err)
	}

	// Build category list for prompt
	var categoryList strings.Builder
	categoryMap := make(map[string]supabase.Category)
	for _, cat := range categories {
		categoryList.WriteString(fmt.Sprintf("- %s (%s)\n", cat.NameAr, cat.Name))
		categoryMap[strings.ToLower(cat.Name)] = cat
		categoryMap[strings.ToLower(cat.NameAr)] = cat
	}

	// Create the prompt for GPT
	systemPrompt := `أنت مساعد ذكي لنظام حكيم لإدارة شكاوى المواطنين في المملكة العربية السعودية.
مهمتك تحليل الشكاوى وتصنيفها.

التصنيفات المتاحة:
` + categoryList.String() + `

قم بالرد بصيغة JSON فقط بالشكل التالي:
{
  "category_name": "اسم التصنيف بالإنجليزية",
  "priority": "low/medium/high/critical",
  "confidence": 0.0-1.0,
  "summary_ar": "ملخص قصير بالعربية (30 كلمة كحد أقصى)",
  "sentiment": "neutral/frustrated/angry/satisfied"
}

معايير تحديد الأولوية:
- critical: خطر على الحياة، طوارئ، انقطاع خدمات حيوية
- high: مشاكل تؤثر على عدد كبير، أضرار مادية كبيرة
- medium: مشاكل عادية تحتاج معالجة
- low: استفسارات، اقتراحات، مشاكل بسيطة`

	userPrompt := fmt.Sprintf("عنوان الشكوى: %s\n\nتفاصيل الشكوى: %s", title, description)

	// Call OpenAI API
	reqBody := OpenAIRequest{
		Model: "gpt-4o-mini",
		Messages: []OpenAIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.3,
		MaxTokens:   500,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+config.AppConfig.OpenAIKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("API request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var openAIResp OpenAIResponse
	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if openAIResp.Error != nil {
		return nil, fmt.Errorf("OpenAI error: %s", openAIResp.Error.Message)
	}

	if len(openAIResp.Choices) == 0 {
		return nil, fmt.Errorf("no response from AI")
	}

	// Parse AI response
	content := openAIResp.Choices[0].Message.Content
	// Clean up the response (remove markdown code blocks if present)
	content = strings.TrimPrefix(content, "```json")
	content = strings.TrimPrefix(content, "```")
	content = strings.TrimSuffix(content, "```")
	content = strings.TrimSpace(content)

	var aiResult AIClassification
	if err := json.Unmarshal([]byte(content), &aiResult); err != nil {
		return nil, fmt.Errorf("failed to parse AI classification: %w", err)
	}

	// Map category name to ID
	result := &supabase.ClassificationResult{
		Priority:   aiResult.Priority,
		Confidence: aiResult.Confidence,
		Summary:    aiResult.Summary,
	}

	// Find matching category
	if cat, ok := categoryMap[strings.ToLower(aiResult.CategoryName)]; ok {
		result.CategoryID = cat.ID
		result.DepartmentID = cat.DepartmentID
	} else {
		// Try partial match
		for name, cat := range categoryMap {
			if strings.Contains(strings.ToLower(aiResult.CategoryName), name) ||
				strings.Contains(name, strings.ToLower(aiResult.CategoryName)) {
				result.CategoryID = cat.ID
				result.DepartmentID = cat.DepartmentID
				break
			}
		}
	}

	// If still no match, use first category
	if result.CategoryID == uuid.Nil && len(categories) > 0 {
		result.CategoryID = categories[0].ID
		result.DepartmentID = categories[0].DepartmentID
		result.Confidence = result.Confidence * 0.5 // Reduce confidence
	}

	return result, nil
}

func (c *Classifier) classifyWithKeywords(title, description string) (*supabase.ClassificationResult, error) {
	text := strings.ToLower(title + " " + description)

	result := &supabase.ClassificationResult{
		Priority:   "medium",
		Confidence: 0.7,
		Summary:    title,
	}

	// Priority detection
	if containsAny(text, []string{"urgent", "emergency", "critical", "danger", "طوارئ", "عاجل", "خطر", "حريق", "انفجار"}) {
		result.Priority = "critical"
		result.Confidence = 0.85
	} else if containsAny(text, []string{"important", "serious", "مهم", "خطير", "انقطاع"}) {
		result.Priority = "high"
		result.Confidence = 0.8
	} else if containsAny(text, []string{"minor", "small", "بسيط", "صغير", "استفسار"}) {
		result.Priority = "low"
		result.Confidence = 0.75
	}

	// Category matching
	categories, err := c.client.GetCategories()
	if err == nil && len(categories) > 0 {
		for _, cat := range categories {
			catName := strings.ToLower(cat.Name + " " + cat.NameAr)
			if strings.Contains(text, strings.ToLower(cat.Name)) ||
				strings.Contains(text, strings.ToLower(cat.NameAr)) {
				result.CategoryID = cat.ID
				result.DepartmentID = cat.DepartmentID
				result.Confidence = 0.8
				break
			}
			words := strings.Fields(catName)
			for _, word := range words {
				if len(word) > 3 && strings.Contains(text, word) {
					result.CategoryID = cat.ID
					result.DepartmentID = cat.DepartmentID
					result.Confidence = 0.6
				}
			}
		}

		if result.CategoryID == uuid.Nil && len(categories) > 0 {
			result.CategoryID = categories[0].ID
			result.DepartmentID = categories[0].DepartmentID
			result.Confidence = 0.5
		}
	}

	// Generate summary
	if len(description) > 100 {
		result.Summary = description[:100] + "..."
	} else {
		result.Summary = description
	}

	return result, nil
}

func containsAny(text string, keywords []string) bool {
	for _, keyword := range keywords {
		if strings.Contains(text, keyword) {
			return true
		}
	}
	return false
}
