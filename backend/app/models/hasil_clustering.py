import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.data_finansial import DataFinansial
    from app.models.evaluasi_model import EvaluasiModel


class AlgoritmaKlustering(str, Enum):
    KMEANS = "KMEANS"
    DBSCAN = "DBSCAN"


class KategoriFinansial(str, Enum):
    SANGAT_MEMBUTUHKAN = "SANGAT_MEMBUTUHKAN"
    MEMBUTUHKAN = "MEMBUTUHKAN"
    CUKUP_MAMPU = "CUKUP_MAMPU"
    MAMPU = "MAMPU"
    OUTLIER = "OUTLIER"


class HasilClustering(SQLModel, table=True):
    __tablename__ = "hasil_clustering"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    data_finansial_id: str = Field(
        foreign_key="data_finansial.id", index=True, max_length=36
    )
    evaluasi_model_id: Optional[str] = Field(
        default=None, foreign_key="evaluasi_model.id", max_length=36
    )
    algoritma: AlgoritmaKlustering
    cluster_id: int = Field(description="-1 berarti outlier (DBSCAN)")
    kategori: KategoriFinansial
    is_outlier: bool = Field(default=False)
    score: Optional[float] = Field(default=None, description="Individual silhouette score")
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    data_finansial: Optional["DataFinansial"] = Relationship(back_populates="hasil_clustering")
    evaluasi_model: Optional["EvaluasiModel"] = Relationship(back_populates="hasil_clustering")
