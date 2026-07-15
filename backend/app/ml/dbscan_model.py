import numpy as np
from sklearn.cluster import DBSCAN
from typing import Optional


class DBSCANModel:
    """DBSCAN clustering model untuk deteksi outlier dan pengelompokan."""

    def __init__(self, eps: float = 0.5, min_samples: int = 3):
        self.eps = eps
        self.min_samples = min_samples
        self.model: Optional[DBSCAN] = None
        self.labels_: Optional[np.ndarray] = None

    def fit(self, X: np.ndarray) -> "DBSCANModel":
        """Fit DBSCAN model."""
        self.model = DBSCAN(
            eps=self.eps,
            min_samples=self.min_samples,
            metric="euclidean",
            n_jobs=-1,
        )
        self.model.fit(X)
        self.labels_ = self.model.labels_
        return self

    def get_labels(self) -> np.ndarray:
        """Ambil label cluster. -1 = outlier/noise."""
        if self.labels_ is None:
            raise ValueError("Model belum di-fit.")
        return self.labels_

    def get_cluster_count(self) -> int:
        """Hitung jumlah cluster (tidak termasuk outlier)."""
        if self.labels_ is None:
            return 0
        unique_labels = set(self.labels_)
        return len(unique_labels - {-1})

    def get_outlier_count(self) -> int:
        """Hitung jumlah outlier."""
        if self.labels_ is None:
            return 0
        return int(np.sum(self.labels_ == -1))

    def get_outlier_indices(self) -> np.ndarray:
        """Ambil indeks data yang merupakan outlier."""
        if self.labels_ is None:
            return np.array([])
        return np.where(self.labels_ == -1)[0]

    def auto_tune_eps(self, X: np.ndarray) -> float:
        """Auto tune eps menggunakan k-distance graph."""
        from sklearn.neighbors import NearestNeighbors
        import numpy as np

        k = max(2, self.min_samples)
        nbrs = NearestNeighbors(n_neighbors=k).fit(X)
        distances, _ = nbrs.kneighbors(X)
        distances = np.sort(distances[:, -1])

        # Gunakan elbow point
        n = len(distances)
        diffs = np.diff(distances)
        elbow_idx = np.argmax(diffs) if len(diffs) > 0 else n // 2
        return float(distances[elbow_idx])
