library(data.table)

imf = "data/raw/dataset_imf_cofer_20250921.csv"

countries_meta = fread("data/countries_meta.csv")
madision_regions = fread("data/madison_regions.csv")

imfd = fread(imf,header = T)
imfd[,Currency:=trimws(gsub("^.*in\\b","",FXR_CURRENCY))]
imfd[,.N,by=.(FXR_CURRENCY,Currency)]
imfdl = melt(imfd[!grepl("All",Currency)],
             id.vars = "Currency",
             measure.vars = patterns("\\d{4}"),
             drop = T,
             variable.name = "year",
             variable.factor = FALSE)
imfdl[,.N,by=Currency]             

ggbarplot(imfdl,
          x="year",
          y="value",
          fill = "Currency")

fwrite(imfdl,"data/temp/imf.csv")
