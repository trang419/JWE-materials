# Vietnam FDI, ODA and gross fixed capital formation, 1991-2019

Compiled on 2026-11-18 to investigate `slides/image/vietnam_fdi_oda.png`.
The CSV is transcribed from the published numeric tables below, not digitized
from the image. It is a candidate reconstruction dataset, not a verified copy
of the image author's original workbook.

All amount columns are in millions of current US dollars. Percentage columns
are calculated as 100 times the amount divided by GFCF. Blank values mean
unavailable, not zero. GFCF is missing for 1991-1993 in the archived table, so
the corresponding shares are left blank, consistent with the image's lines
starting in 1994.

## FDI

- Column: `fdi_implemented_usd_million`.
- Measure: implemented/realized FDI capital in Vietnam, not registered capital
  and not the World Bank balance-of-payments net inflow series.
- Transcription source: https://www.jpvn.org/statst-j/VN-fdi-statistics-1988-2024.html
- That table cites Vietnam's Statistical Yearbook 2022, Table 131 and NSO PXWeb.
- Official corroboration of 2019's USD 20.38 billion:
  https://www.mpi.gov.vn/en/Pages/2020/Brief-on-foreign-direct-investment-of-2019-176349.aspx
- Another official yearbook source:
  https://www.nso.gov.vn/wp-content/uploads/2024/07/NG-TCTK-2023_Final.pdf

## ODA

- Column: `net_oda_received_usd_million`.
- Measure: net ODA received by Vietnam from all donors, not Japan alone.
- Indicator: `DT.ODA.ODAT.CD`.
- Transcription source (archived World Bank/OECD series reproduced by IndexMundi):
  https://www.indexmundi.com/facts/vietnam/indicator/DT.ODA.ODAT.CD
- Primary indicator page: https://data.worldbank.org/indicator/DT.ODA.ODAT.CD

## GFCF

- Column: `gfcf_usd_million`.
- Measure: gross fixed capital formation, current US dollars.
- Indicator: `NE.GDI.FTOT.CD`.
- Transcription source (archived World Bank series reproduced by IndexMundi):
  https://www.indexmundi.com/facts/vietnam/indicator/NE.GDI.FTOT.CD
- Primary indicator page: https://data.worldbank.org/indicator/NE.GDI.FTOT.CD

## Vintage and interpretation

The archived values are used deliberately because they appear consistent with
the graph. Current releases differ in some years. For example, the archived
2019 GFCF is USD 63,469.790 million, giving FDI/GFCF of 32.1098% and ODA/GFCF
of 1.7247%. The image visually shows approximately 32% and 2%, respectively.
The archived 1994 values give approximately 56.69% and 22.66%, also consistent
with the start of the image's lines. These checks support the reconstruction
but do not establish the original data vintage or source for every point.

The underlying flows have different statistical definitions; the calculated
ratios compare their magnitudes and are not additive national-accounts shares.
