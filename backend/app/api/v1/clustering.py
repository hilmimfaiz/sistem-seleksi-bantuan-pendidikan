from fastapi import APIRouter, Depends
from sqlmodel import Session
from app.database import get_session
from app.schemas.clustering import ClusteringRunRequest
from app.schemas.common import BaseResponse
from app.core.dependencies import require_admin
from app.models.user import User
from app.services.clustering_service import ClusteringService

router = APIRouter(prefix="/clustering", tags=["Clustering"])


@router.post("/run", response_model=BaseResponse)
def run_clustering(
    body: ClusteringRunRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """
    [Admin] Jalankan clustering K-Means dan DBSCAN.
    
    Pipeline:
    1. Ambil data terverifikasi
    2. Preprocessing + StandardScaler
    3. K-Means clustering
    4. DBSCAN clustering
    5. Hitung Silhouette Score dan Davies-Bouldin Index
    6. Simpan hasil ke database
    """
    service = ClusteringService(db)
    result = service.run_clustering(
        n_clusters=body.n_clusters,
        eps=body.eps,
        min_samples=body.min_samples,
    )

    # Send Notification
    from app.services.notification_service import NotificationService
    from app.models.notification import NotificationType
    
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Clustering Selesai",
        body=f"Proses clustering {body.n_clusters} kelompok berhasil dijalankan untuk {result['total_processed']} mahasiswa.",
        notif_type=NotificationType.CLUSTERING,
        reference_id=current_user.id,
    )

    return BaseResponse(
        success=True,
        message=f"Clustering selesai. {result['total_processed']} data diproses.",
        data=result,
    )


@router.get("/results", response_model=BaseResponse)
def get_results(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Ambil hasil clustering terbaru."""
    service = ClusteringService(db)
    result = service.get_clustering_results()

    # Serialize datetime objects
    def serialize(obj):
        if hasattr(obj, "model_dump"):
            return obj.model_dump()
        if hasattr(obj, "__dict__"):
            d = {k: v for k, v in obj.__dict__.items() if not k.startswith("_")}
            for k, v in d.items():
                if hasattr(v, "isoformat"):
                    d[k] = v.isoformat()
            return d
        return obj

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "kmeans_evaluasi": serialize(result["kmeans_evaluasi"]) if result["kmeans_evaluasi"] else None,
            "dbscan_evaluasi": serialize(result["dbscan_evaluasi"]) if result["dbscan_evaluasi"] else None,
            "kmeans_stats": result["kmeans_stats"],
            "dbscan_stats": result["dbscan_stats"],
            "members": result["members"],
            "outliers": result.get("outliers", []),
        },
    )


@router.get("/statistics", response_model=BaseResponse)
def get_statistics(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Statistik cluster untuk dashboard."""
    from sqlmodel import select, func
    from app.models.hasil_clustering import HasilClustering, AlgoritmaKlustering
    from app.models.evaluasi_model import EvaluasiModel

    # Ambil evaluasi terbaru K-Means
    latest_kmeans = db.exec(
        select(EvaluasiModel)
        .where(EvaluasiModel.algoritma == "KMEANS")
        .order_by(EvaluasiModel.created_at.desc())
    ).first()

    stats = {"total_clustered": 0, "by_category": {}, "kmeans": None, "dbscan": None}

    if latest_kmeans:
        members = db.exec(
            select(HasilClustering).where(
                HasilClustering.evaluasi_model_id == latest_kmeans.id
            )
        ).all()
        stats["total_clustered"] = len(members)
        category_count = {}
        for m in members:
            key = m.kategori.value if hasattr(m.kategori, "value") else str(m.kategori)
            category_count[key] = category_count.get(key, 0) + 1
        stats["by_category"] = category_count
        stats["kmeans"] = {
            "silhouette_score": latest_kmeans.silhouette_score,
            "davies_bouldin_index": latest_kmeans.davies_bouldin_index,
            "n_clusters": latest_kmeans.n_clusters,
        }

    latest_dbscan = db.exec(
        select(EvaluasiModel)
        .where(EvaluasiModel.algoritma == "DBSCAN")
        .order_by(EvaluasiModel.created_at.desc())
    ).first()

    if latest_dbscan:
        stats["dbscan"] = {
            "silhouette_score": latest_dbscan.silhouette_score,
            "davies_bouldin_index": latest_dbscan.davies_bouldin_index,
            "n_clusters": latest_dbscan.n_clusters,
            "total_outlier": latest_dbscan.total_outlier,
        }

    return BaseResponse(success=True, message="Berhasil", data=stats)

@router.get("/history", response_model=BaseResponse)
def get_history(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Ambil riwayat hasil clustering."""
    service = ClusteringService(db)
    history = service.get_clustering_history()
    
    return BaseResponse(
        success=True, 
        message="Berhasil mengambil riwayat clustering", 
        data={"items": history}
    )
