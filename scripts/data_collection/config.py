"""
Configuration module for Yuura Intelligence Hub.
Loads environment variables for database and API connections.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# PostgreSQL Database Configuration (for psycopg2)
DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'port': int(os.getenv('DB_PORT', 5432))
}

# API Configuration
YOUTUBE_API_KEY = os.getenv('YOUTUBE_API_KEY')
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

# Channel Configuration
YUURA_CHANNEL_ID = os.getenv('YUURA_CHANNEL_ID', 'UCrmtSeYObZJNG6OIC7Pw-_A')

# Validation (optional but good practice)
def validate_config():
    """Check if all required environment variables are set."""
    required = [
        ('YOUTUBE_API_KEY', YOUTUBE_API_KEY),
        ('DB_HOST', DB_CONFIG['host']),
        ('DB_PASSWORD', DB_CONFIG['password']),
        ('SUPABASE_URL', SUPABASE_URL),
    ]

    missing = [name for name, value in required if not value]

    if missing:
        raise EnvironmentError(
            f"Missing required environment variables: {', '.join(missing)}\n"
            "Please check your .env file."
        )

    return True

# Auto-validate on import (comment out if you don't want this)
validate_config()
