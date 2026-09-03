"""
# 9amHealth Data Analyst Case Study — exploration scaffold.
# Setup only: imports + read the four CSVs. No cleaning, no analysis.
# Run:
#    cd ~/projects/internal/case-study-9amhealth
#    .venv/bin/python python-prog/explore.py
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import scipy
import statsmodels.api as sm

modules = pd.read_csv("data/Data Analyst Case Study Doc 1 - 12 Weeks Weight Loss Modules Completion.csv", sep='/t')
demographics = pd.read_csv("data/Data Analyst Case Study Doc 2 - Demographics.csv", sep='/t')
engagement = pd.read_csv("data/Data Analyst Case Study Doc 3 - Engagement Data.csv", sep='/t')
bw_detail = pd.read_csv("data/Data Analyst Case Study Doc 4 - BW_Detail.csv", sep='/t')

print(modules.head)

"""
for name, df in [
    ("modules", modules),
    ("demographics", demographics),
    ("engagement", engagement),
    ("bw_detail", bw_detail),
]:
    print(f"\n===== {name} =====")
    print("shape:", df.shape)
    print(df.dtypes)
    print(df.head())
"""