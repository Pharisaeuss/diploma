from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager
from typing import List
import time
import logging

from database import engine, get_db, Base
import models
import schemas
import crud

logger = logging.getLogger(__name__)

# ─── Startup: wait for RDS then create tables ─────────────────────────────────

def _wait_for_db(retries: int = 20, delay: int = 10) -> None:
    """Block until the DB accepts a connection or raise after retries."""
    from sqlalchemy import text
    from sqlalchemy.exc import OperationalError
    import time as _time

    for attempt in range(1, retries + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("DB ready after %d attempt(s)", attempt)
            return
        except OperationalError as exc:
            logger.warning(
                "DB not ready (attempt %d/%d): %s — retrying in %ds",
                attempt, retries, exc.args[0], delay
            )
            _time.sleep(delay)

    raise RuntimeError(
        f"Database did not become ready after {retries} attempts. "
        "Check RDS status and security group rules."
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── startup ───────────────────────────────────────────────────────
    logger.info("Waiting for database...")
    _wait_for_db(retries=20, delay=10)   # waits up to ~3 min total
    logger.info("Running create_all()")
    Base.metadata.create_all(bind=engine)
    logger.info("Application startup complete")
    yield
    # ── shutdown ──────────────────────────────────────────────────────
    engine.dispose()
    logger.info("Application shutdown complete")


app = FastAPI(
    title="FastAPI CRUD with PostgreSQL",
    description="Simple CRUD API with SQLAlchemy and RDS PostgreSQL",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def root():
    return FileResponse("static/index.html")

# ─── Health Check ─────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"])
def health_check(db: Session = Depends(get_db)):
    start = time.time()
    try:
        db.execute(__import__("sqlalchemy").text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    latency_ms = round((time.time() - start) * 1000, 2)
    return {
        "status": "ok" if db_status == "healthy" else "degraded",
        "database": db_status,
        "db_latency_ms": latency_ms,
        "version": "1.0.0"
    }

# ─── Items CRUD ───────────────────────────────────────────────────────────────

@app.post("/items", response_model=schemas.Item, status_code=status.HTTP_201_CREATED, tags=["Items"])
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    return crud.create_item(db, item)

@app.get("/items", response_model=List[schemas.Item], tags=["Items"])
def list_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_items(db, skip=skip, limit=limit)

@app.get("/items/{item_id}", response_model=schemas.Item, tags=["Items"])
def get_item(item_id: int, db: Session = Depends(get_db)):
    item = crud.get_item(db, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@app.put("/items/{item_id}", response_model=schemas.Item, tags=["Items"])
def update_item(item_id: int, item: schemas.ItemCreate, db: Session = Depends(get_db)):
    updated = crud.update_item(db, item_id, item)
    if not updated:
        raise HTTPException(status_code=404, detail="Item not found")
    return updated

@app.delete("/items/{item_id}", tags=["Items"])
def delete_item(item_id: int, db: Session = Depends(get_db)):
    deleted = crud.delete_item(db, item_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Item not found")
    return {"message": f"Item {item_id} deleted successfully"}
