from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel


class ClusteringRunRequest(BaseModel):
    n_clusters: int = 4  # default K-Means clusters
    eps: float = 0.5    # DBSCAN epsilon
    min_samples: int = 3  # DBSCAN min samples


class ClusterMember(BaseModel):
    mahasiswa_id: str
    mahasiswa_nama: str
    mahasiswa_nim: str
    cluster_id: int
    kategori: str
    is_outlier: bool
    pengajuan_id: Optional[str] = None
    score: Optional[float] = None
    ukt_awal: Optional[float] = None
    pendapatan_orang_tua: Optional[float] = None


class ClusterStats(BaseModel):
    cluster_id: int
    kategori: str
    total: int
    percentage: float


class EvaluasiModelResponse(BaseModel):
    id: str
    algoritma: str
    n_clusters: int
    silhouette_score: float
    davies_bouldin_index: float
    total_data: int
    total_outlier: int
    created_at: datetime

    class Config:
        from_attributes = True


class ClusteringResultResponse(BaseModel):
    kmeans_evaluasi: Optional[EvaluasiModelResponse] = None
    dbscan_evaluasi: Optional[EvaluasiModelResponse] = None
    kmeans_stats: List[ClusterStats] = []
    dbscan_stats: List[ClusterStats] = []
    members: List[ClusterMember] = []
    total_processed: int = 0
    kmeans_plot_url: Optional[str] = None
    dbscan_plot_url: Optional[str] = None
