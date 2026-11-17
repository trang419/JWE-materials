# Japanese inward and outward FDI, 2024

Source: Japan Ministry of Finance, annual direct investment flows by region and
industry, directional principle. Workbook downloaded 18 November 2026:
https://www.mof.go.jp/policy/international_policy/reference/balance_of_payments/revised/fdi2024.xlsx

Index: https://www.mof.go.jp/english/policy/international_policy/reference/balance_of_payments/ebpfdii.htm

Run `Rscript "scripts/08 japan_fdi_2024.R"` from the repository root to extract
`japan_fdi_by_country_industry_2024.csv` from the saved workbook `mof_fdi2024.xlsx`.
This revised workbook supersedes the older PDF transcription for the charts in
`slides/08_fdi.qmd`. Do not combine values from the two vintages.

Values are annual net flows in 100 million yen; divide by 10 for billion yen or
10,000 for trillion yen. Source sheet, cell, original value and reporting status
are retained. Confidential cells and no-report cells remain missing, not zero.

ASEAN excluding Singapore is calculated as the reported ASEAN aggregate minus
Singapore, separately for inward/outward flows and manufacturing,
non-manufacturing and total. Its source-cell field records both inputs. It is
mutually exclusive with the separate Singapore bar. The source's 2024 ASEAN
membership coverage is retained.

Counterpart countries represent immediate investment relationships, not ultimate
beneficial ownership. Negative flows represent net withdrawals. Non-manufacturing
includes services and other industries. The narrow source category `Services`
is not the aggregate of all service industries. Charts show selected countries
and industries rather than exhaustive rankings.
