import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.hasil_clustering import HasilClustering


class EvaluasiModel(SQLModel, table=True):
    __tablename__ = "evaluasi_model"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    algoritma: str = Field(max_length=20, description="KMEANS or DBSCAN")
    n_clusters: int = Field(description="Jumlah cluster yang terbentuk")
    silhouette_score: float = Field(description="Silhouette score (-1 to 1)")
    davies_bouldin_index: float = Field(description="Davies-Bouldin index (lower is better)")
    total_data: int = Field(description="Total data yang diproses")
    total_outlier: int = Field(default=0, description="Total data outlier (DBSCAN)")
    params: Optional[str] = Field(default=None, max_length=500, description="JSON params")
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    hasil_clustering: List["HasilClustering"] = Relationship(back_populates="evaluasi_model")
