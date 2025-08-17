from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
import psycopg2
from typing import List, Optional
from datetime import datetime
import os
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Cheetah Backend API",
    description="A sample backend API built with FastAPI",
    version="1.0.0"
)

# Database configuration - build from individual components for flexibility
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_NAME = os.getenv("DB_NAME", "appdb")
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"

logger.info(f"Database connection: postgresql://{DB_USER}:***@{DB_HOST}:5432/{DB_NAME}")

class Idea(BaseModel):
    id: Optional[int] = None
    content: str
    created_at: Optional[datetime] = None

class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str = "1.0.0"

def get_db_connection():
    """Get database connection with retry logic"""
    max_retries = 5
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            conn = psycopg2.connect(DATABASE_URL)
            return conn
        except psycopg2.OperationalError as e:
            retry_count += 1
            if retry_count >= max_retries:
                logger.error(f"Failed to connect to database after {max_retries} attempts: {e}")
                raise e
            logger.warning(f"Database connection attempt {retry_count} failed. Retrying in 2 seconds...")
            time.sleep(2)

@app.get("/health", response_model=HealthResponse)
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        conn = get_db_connection()
        conn.close()
        db_status = "connected"
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        db_status = "disconnected"
        # For now, still return healthy even if DB is down to prevent pod restarts
        # In production, you might want to return 503 if DB is critical
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow()
    )

@app.get("/api/ideas", response_model=List[Idea])
def list_ideas():
    """Get all ideas"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, content, created_at FROM ideas ORDER BY created_at DESC;")
        ideas = [Idea(id=r[0], content=r[1], created_at=r[2]) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return ideas
    except Exception as e:
        logger.error(f"Failed to fetch ideas: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch ideas")

@app.post("/api/ideas", response_model=Idea)
def add_idea(idea: Idea):
    """Add a new idea"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO ideas (content, created_at) VALUES (%s, %s) RETURNING id, created_at;",
            (idea.content, datetime.utcnow())
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return Idea(id=row[0], content=idea.content, created_at=row[1])
    except Exception as e:
        logger.error(f"Failed to add idea: {e}")
        raise HTTPException(status_code=500, detail="Failed to add idea")

@app.get("/api/ideas/{idea_id}", response_model=Idea)
def get_idea(idea_id: int):
    """Get a specific idea by ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, content, created_at FROM ideas WHERE id = %s;", (idea_id,))
        row = cur.fetchone()
        cur.close()
        conn.close()
        
        if not row:
            raise HTTPException(status_code=404, detail="Idea not found")
            
        return Idea(id=row[0], content=row[1], created_at=row[2])
    except psycopg2.Error as e:
        logger.error(f"Database error: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# Add CORS middleware for frontend communication
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
