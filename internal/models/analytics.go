package models

type DashboardAnalytics struct {
	TotalComplaints       int             `json:"total_complaints"`
	PendingComplaints     int             `json:"pending_complaints"`
	ResolvedComplaints    int             `json:"resolved_complaints"`
	AverageResolutionTime float64         `json:"average_resolution_time_hours"`
	SatisfactionRate      float64         `json:"satisfaction_rate"`
	ComplaintsByStatus    []StatusCount   `json:"complaints_by_status"`
	ComplaintsByCategory  []CategoryCount `json:"complaints_by_category"`
	ComplaintsTrend       []DailyCount    `json:"complaints_trend"`
}

type StatusCount struct {
	Status string `json:"status"`
	Count  int    `json:"count"`
}

type CategoryCount struct {
	CategoryID   string `json:"category_id"`
	CategoryName string `json:"category_name"`
	Count        int    `json:"count"`
}

type DailyCount struct {
	Date  string `json:"date"`
	Count int    `json:"count"`
}
