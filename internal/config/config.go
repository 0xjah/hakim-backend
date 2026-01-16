package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Env               string
	Port              string
	SupabaseURL       string
	SupabaseKey       string
	SupabaseJWTSecret string
	OpenAIKey         string
}

var AppConfig *Config

func Load() error {
	// Load .env file if exists
	_ = godotenv.Load()

	AppConfig = &Config{
		Env:               getEnv("ENV", "development"),
		Port:              getEnv("PORT", "8080"),
		SupabaseURL:       getEnv("SUPABASE_URL", ""),
		SupabaseKey:       getEnv("SUPABASE_KEY", ""),
		SupabaseJWTSecret: getEnv("SUPABASE_JWT_SECRET", ""),
		OpenAIKey:         getEnv("OPENAI_API_KEY", ""),
	}

	return nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
