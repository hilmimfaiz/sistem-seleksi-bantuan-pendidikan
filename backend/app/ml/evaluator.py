import numpy as np
from sklearn.metrics import silhouette_score, davies_bouldin_score
from typing import Optional, Tuple


class ClusterEvaluator:
    """Evaluator untuk mengukur kualitas clustering."""

    @staticmethod
    def silhouette(X: np.ndarray, labels: np.ndarray) -> float:
        """
        Hitung Silhouette Score.
        Range: -1 (buruk) hingga 1 (sempurna).
        """
        unique_labels = set(labels) - {-1}  # Exclude outlier DBSCAN
        valid_mask = labels != -1
        X_valid = X[valid_mask]
        labels_valid = labels[valid_mask]

        if len(unique_labels) < 2:
            return 0.0
        if len(X_valid) < 2:
            return 0.0

        try:
            return float(silhouette_score(X_valid, labels_valid))
        except Exception:
            return 0.0

    @staticmethod
    def silhouette_samples(X: np.ndarray, labels: np.ndarray) -> np.ndarray:
        """Hitung silhouette score per sample."""
        from sklearn.metrics import silhouette_samples
        try:
            valid_mask = labels != -1
            X_valid = X[valid_mask]
            labels_valid = labels[valid_mask]
            if len(set(labels_valid)) < 2:
                return np.zeros(len(X))
            scores = silhouette_samples(X_valid, labels_valid)
            # Map back ke full array
            full_scores = np.full(len(X), 0.0)
            valid_indices = np.where(valid_mask)[0]
            for i, idx in enumerate(valid_indices):
                full_scores[idx] = scores[i]
            return full_scores
        except Exception:
            return np.zeros(len(X))

    @staticmethod
    def davies_bouldin(X: np.ndarray, labels: np.ndarray) -> float:
        """
        Hitung Davies-Bouldin Index.
        Range: >= 0. Nilai lebih rendah = cluster lebih baik.
        """
        unique_labels = set(labels) - {-1}
        valid_mask = labels != -1
        X_valid = X[valid_mask]
        labels_valid = labels[valid_mask]

        if len(unique_labels) < 2:
            return 0.0
        if len(X_valid) < 2:
            return 0.0

        try:
            return float(davies_bouldin_score(X_valid, labels_valid))
        except Exception:
            return 0.0

    @staticmethod
    def evaluate(X: np.ndarray, labels: np.ndarray) -> Tuple[float, float]:
        """
        Evaluasi clustering dengan Silhouette Score dan Davies-Bouldin Index.
        Returns: (silhouette_score, davies_bouldin_index)
        """
        sil = ClusterEvaluator.silhouette(X, labels)
        db = ClusterEvaluator.davies_bouldin(X, labels)
        return sil, db
