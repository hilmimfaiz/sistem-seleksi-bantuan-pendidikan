from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy import event
from app.config import settings
import logging

logger = logging.getLogger(__name__)

connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}
engine_kwargs = {
    "echo": settings.DEBUG,
    "pool_pre_ping": True,
    "pool_recycle": 300,
}

if not settings.DATABASE_URL.startswith("sqlite"):
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    **engine_kwargs
)


def create_db_and_tables():
    """Create all tables in the database."""
    SQLModel.metadata.create_all(engine)
    logger.info("Database tables created successfully.")


def get_session():
    """Dependency to get database session."""
    with Session(engine) as session:
        try:
            yield session
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()
