"""Plot the published-series reconstruction of Vietnam's FDI/ODA figure."""

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, MultipleLocator, PercentFormatter


root = Path(__file__).resolve().parents[1]
data_file = root / "data/08 fdi/vietnam_fdi_oda_1991_2019.csv"
with data_file.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))

years = [int(row["year"]) for row in rows]
fdi = [float(row["fdi_implemented_usd_million"]) for row in rows]
oda = [float(row["net_oda_received_usd_million"]) for row in rows]
share_rows = [row for row in rows if row["gfcf_usd_million"]]
share_years = [int(row["year"]) for row in share_rows]
fdi_share = [float(row["fdi_share_gfcf_pct"]) for row in share_rows]
oda_share = [float(row["oda_share_gfcf_pct"]) for row in share_rows]

plt.rcParams.update({"font.size": 14, "font.family": "DejaVu Sans"})
fig, left = plt.subplots(figsize=(15, 8))
fig.subplots_adjust(left=0.085, right=0.915, bottom=0.23, top=0.77)
right = left.twinx()

width = 0.34
bars_fdi = left.bar([year - width / 2 for year in years], fdi, width,
                    color="#3D3052", label="FDI")
bars_oda = left.bar([year + width / 2 for year in years], oda, width,
                    color="#E96A00", label="ODA")
line_fdi, = right.plot(share_years, fdi_share, color="#FF8B3D", linewidth=2.8,
                       label="FDI / GFCF")
line_oda, = right.plot(share_years, oda_share, color="#8060A6", linewidth=2.8,
                       label="ODA / GFCF")

left.set(xlim=(1990.4, 2019.6), ylim=(0, 25000),
         ylabel="Million current US$", xticks=years)
left.tick_params(axis="x", rotation=50, labelsize=11)
left.yaxis.set_major_locator(MultipleLocator(5000))
left.yaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:,.0f}"))
left.set_axisbelow(True)
left.grid(axis="y", color="#DDDDDD", linewidth=0.7)
right.set(ylim=(0, 60), ylabel="Share of gross fixed capital formation")
right.yaxis.set_major_locator(MultipleLocator(10))
right.yaxis.set_major_formatter(PercentFormatter(xmax=100, decimals=0))
for axis in (left, right):
    axis.spines["top"].set_visible(False)
left.spines["right"].set_visible(False)
right.spines["left"].set_visible(False)

fig.suptitle("Vietnam: FDI, ODA and their shares of GFCF, 1991-2019",
             x=0.085, y=0.96, ha="left", fontsize=23, fontweight="bold")
fig.text(0.085, 0.90, "Reconstruction using published historical series",
         fontsize=16, color="#555555")
fig.legend([bars_fdi, bars_oda, line_fdi, line_oda],
           ["FDI", "ODA", "FDI / GFCF", "ODA / GFCF"],
           loc="upper center", bbox_to_anchor=(0.5, 0.865), ncol=4,
           frameon=False, fontsize=14)
fig.text(0.085, 0.075,
         "Sources: Vietnam NSO series reproduced by JP-VN; archived World Bank/OECD series reproduced by IndexMundi.",
         fontsize=11)
fig.text(0.085, 0.035,
         "FDI = implemented capital; ODA = net aid from all donors. Shares start in 1994 because earlier GFCF values are unavailable.",
         fontsize=11)

output = root / "slides/image/vietnam_fdi_oda_reconstructed.png"
fig.savefig(output, dpi=200, facecolor="white")
plt.close(fig)
print(output)
