import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship, Column
from sqlalchemy import JSON

if TYPE_CHECKING:
    from app.models.user import User


class ActivityLog(SQLModel, table=True):
    __tablename__ = "activity_logs"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    user_id: Optional[str] = Field(default=None, foreign_key="users.id", index=True, max_length=36)
    action: str = Field(max_length=100, index=True)
    entity_type: Optional[str] = Field(default=None, max_length=50)
    entity_id: Optional[str] = Field(default=None, max_length=36)
    detail: Optional[dict] = Field(default=None, sa_column=Column(JSON))
    ip_address: Optional[str] = Field(default=None, max_length=45)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    user: Optional["User"] = Relationship(back_populates="activity_logs")
