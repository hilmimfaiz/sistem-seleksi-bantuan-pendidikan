import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from typing import List, Tuple
from app.models.data_finansial import DataFinansial


class Preprocessor:
    """Preprocessor untuk data finansial mahasiswa."""
    
    FEATURES = [
        "pendapatan_orang_tua",
        "jumlah_tanggungan",
        "pengeluaran_bulanan",
        "uang_saku",
        "literasi_keuangan",
        "gaya_hidup",
    ]

    def __init__(self):
        self.scaler = StandardScaler()
        self.is_fitted = False

    def extract_features(self, data_list: List[DataFinansial]) -> Tuple[np.ndarray, List[str]]:
        """
        Ekstrak fitur dari list DataFinansial.
        Returns: (feature_matrix, list_of_ids)
        """
        records = []
        ids = []
        for df in data_list:
            records.append({
                "pendapatan_orang_tua": df.pendapatan_orang_tua,
                "jumlah_tanggungan": df.jumlah_tanggungan,
                "pengeluaran_bulanan": df.pengeluaran_bulanan,
                "uang_saku": df.uang_saku,
                "literasi_keuangan": df.literasi_keuangan,
                "gaya_hidup": df.gaya_hidup,
            })
            ids.append(df.id)

        df_features = pd.DataFrame(records, columns=self.FEATURES)
        return df_features.values, ids

    def fit_transform(self, X: np.ndarray) -> np.ndarray:
        """Fit scaler dan transform data."""
        X_scaled = self.scaler.fit_transform(X)
        self.is_fitted = True
        return X_scaled

    def transform(self, X: np.ndarray) -> np.ndarray:
        """Transform data menggunakan fitted scaler."""
        if not self.is_fitted:
            raise ValueError("Scaler belum di-fit. Panggil fit_transform terlebih dahulu.")
        return self.scaler.transform(X)

    def inverse_transform(self, X: np.ndarray) -> np.ndarray:
        """Kembalikan data ke skala asli."""
        return self.scaler.inverse_transform(X)
