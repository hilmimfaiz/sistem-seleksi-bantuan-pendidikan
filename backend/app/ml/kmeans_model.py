import numpy as np
from sklearn.cluster import KMeans
from typing import List, Tuple, Optional


class KMeansModel:
    """K-Means clustering model untuk pengelompokan kemampuan finansial."""

    def __init__(self, n_clusters: int = 4, random_state: int = 42, max_iter: int = 300):
        self.n_clusters = n_clusters
        self.random_state = random_state
        self.max_iter = max_iter
        self.model: Optional[KMeans] = None
        self.labels_: Optional[np.ndarray] = None
        self.cluster_centers_: Optional[np.ndarray] = None
        self.inertia_: Optional[float] = None

    def fit(self, X: np.ndarray) -> "KMeansModel":
        """Fit K-Means model."""
        if len(X) < self.n_clusters:
            raise ValueError(
                f"Jumlah data ({len(X)}) lebih sedikit dari jumlah cluster ({self.n_clusters}). "
                f"Kurangi jumlah cluster atau tambah data."
            )

        self.model = KMeans(
            n_clusters=self.n_clusters,
            random_state=self.random_state,
            max_iter=self.max_iter,
            n_init=10,
        )
        self.model.fit(X)
        self.labels_ = self.model.labels_
        self.cluster_centers_ = self.model.cluster_centers_
        self.inertia_ = self.model.inertia_
        return self

    def predict(self, X: np.ndarray) -> np.ndarray:
        """Prediksi cluster untuk data baru."""
        if self.model is None:
            raise ValueError("Model belum di-fit.")
        return self.model.predict(X)

    def get_labels(self) -> np.ndarray:
        """Ambil label cluster."""
        if self.labels_ is None:
            raise ValueError("Model belum di-fit.")
        return self.labels_

    def find_optimal_k(self, X: np.ndarray, k_range: range = range(2, 8)) -> int:
        """Cari jumlah cluster optimal menggunakan elbow method."""
        from sklearn.metrics import silhouette_score
        best_k = 4
        best_score = -1

        for k in k_range:
            if len(X) <= k:
                continue
            km = KMeans(n_clusters=k, random_state=42, n_init=10)
            labels = km.fit_predict(X)
            if len(set(labels)) < 2:
                continue
            score = silhouette_score(X, labels)
            if score > best_score:
                best_score = score
                best_k = k

        return best_k
