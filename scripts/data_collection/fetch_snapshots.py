"""
Fetch current channel statistics from YouTube API and save to database.

This script:
- Connects to YouTube Data API v3
- Fetches subscriber count, view count, and video count
- Saves snapshot to PostgreSQL database
- Designed to run every 6 hours via cron job
"""

import psycopg2
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from datetime import datetime
import sys
import os

# Add parent directory to path so we can import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from scripts.data_collection.config import (
    DB_CONFIG,
    YOUTUBE_API_KEY,
    YUURA_CHANNEL_ID
)


def fetch_channel_stats(youtube, channel_id):
    """
    Fetch statistics for a YouTube channel.

    Args:
        youtube: YouTube API service object
        channel_id: YouTube channel ID

    Returns:
        dict: Channel statistics or None if error
    """
    try:
        request = youtube.channels().list(
            part='statistics',
            id=channel_id
        )
        response = request.execute()

        if not response.get('items'):
            print(f"❌ Channel not found: {channel_id}")
            return None

        stats = response['items'][0]['statistics']

        return {
            'subscriber_count': int(stats.get('subscriberCount', 0)),
            'view_count': int(stats.get('viewCount', 0)),
            'video_count': int(stats.get('videoCount', 0))
        }

    except HttpError as e:
        print(f"❌ YouTube API error: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error fetching stats: {e}")
        return None


def get_talent_id(conn, channel_id):
    """
    Get talent UUID from database by YouTube channel ID.

    Args:
        conn: PostgreSQL connection object
        channel_id: YouTube channel ID

    Returns:
        str: Talent UUID or None if not found
    """
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM talents WHERE youtube_id = %s",
            (channel_id,)
        )
        result = cursor.fetchone()
        cursor.close()

        if result:
            return result[0]
        else:
            print(f"❌ No talent found with YouTube ID: {channel_id}")
            print("   Make sure you've run seed_data.sql to insert Yuura's info!")
            return None

    except psycopg2.Error as e:
        print(f"❌ Database error getting talent ID: {e}")
        return None


def save_snapshot(conn, talent_id, stats):
    """
    Save channel statistics snapshot to database.

    Args:
        conn: PostgreSQL connection object
        talent_id: UUID of the talent
        stats: Dictionary with subscriber_count, view_count, video_count

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        cursor = conn.cursor()

        # Insert snapshot
        cursor.execute(
            """
            INSERT INTO snapshots (talent_id, sub_count, view_count, video_count, recorded_at)
            VALUES (%s, %s, %s, %s, NOW())
            """,
            (
                talent_id,
                stats['subscriber_count'],
                stats['view_count'],
                stats['video_count']
            )
        )

        conn.commit()
        cursor.close()

        return True

    except psycopg2.Error as e:
        print(f"❌ Database error saving snapshot: {e}")
        conn.rollback()
        return False


def main():
    """Main execution function."""

    print("=" * 60)
    print("Yuura Intelligence Hub - Snapshot Fetcher")
    print("=" * 60)
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Channel ID: {YUURA_CHANNEL_ID}")
    print()

    # Initialize connections
    youtube = None
    conn = None

    try:
        # Connect to YouTube API
        print("📡 Connecting to YouTube API...")
        youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
        print("✓ Connected to YouTube API")

        # Fetch channel stats
        print(f"📊 Fetching stats for channel {YUURA_CHANNEL_ID}...")
        stats = fetch_channel_stats(youtube, YUURA_CHANNEL_ID)

        if not stats:
            print("❌ Failed to fetch channel statistics")
            return 1

        print("✓ Statistics fetched successfully:")
        print(f"  • Subscribers: {stats['subscriber_count']:,}")
        print(f"  • Views: {stats['view_count']:,}")
        print(f"  • Videos: {stats['video_count']:,}")
        print()

        # Connect to database
        print("🗄️  Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        print("✓ Connected to database")

        # Get talent ID
        print("🔍 Looking up talent in database...")
        talent_id = get_talent_id(conn, YUURA_CHANNEL_ID)

        if not talent_id:
            print("❌ Talent not found in database")
            return 1

        print(f"✓ Found talent ID: {talent_id}")

        # Save snapshot
        print("💾 Saving snapshot to database...")
        if save_snapshot(conn, talent_id, stats):
            print("✓ Snapshot saved successfully!")
            print()
            print("=" * 60)
            print("✅ Snapshot collection completed successfully")
            print("=" * 60)
            return 0
        else:
            print("❌ Failed to save snapshot")
            return 1

    except psycopg2.Error as e:
        print(f"❌ Database connection error: {e}")
        print("   Check your .env file database credentials")
        return 1

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return 1

    finally:
        # Clean up connections
        if conn:
            conn.close()
            print("🔌 Database connection closed")


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
