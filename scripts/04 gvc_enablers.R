# install.packages(c("WDI", "data.table", "ggplot2"))
library(wbstats)
library(data.table)
library(ggplot2)

YEARS <- c(1960, 1990, 2020)

# Indicators (named so WDI returns these column names)
inds <- c(
  exports = "NE.EXP.GNFS.CD",  # Exports of goods & services (current US$)
  imports = "NE.IMP.GNFS.CD",  # Imports of goods & services (current US$)
  gdp     = "NY.GDP.MKTP.CD"   # GDP (current US$)
)

# ---- 2) Download data ----
dt <- wb_data(
  indicator   = inds,
  start_date  = 1960,
  end_date    = 2023,
  return_wide = FALSE
)

# Keep only our years and attach metadata
setDT(dt)
dt[,var:=gsub("\\s.*$","",indicator)]
dtw = dcast(dt,iso3c+country+date~var,measure.var="value")
dtw[,trade:=ifelse(is.na(Exports),0,Exports)+
      ifelse(is.na(Imports),0,Imports)]

dtw[,global_trade:=sum(trade),by=date]
dtw[,global_trade_share:=trade/global_trade]
dtw[,gdp_share:=trade/GDP]
dtw[,year:=as.character(date)]


dtww = dtw[date%in%c(1970,1990,2020)&
             !is.na(gdp_share)&
             !is.na(global_trade_share)]
fwrite(dtww[,.(year,gdp_share,global_trade_share,iso3c)],
       "data/wto_power.csv")

### tariff eqiv of ntm
dt = fread("data/raw/ave_gtapsect_0.csv")

# ----------------------------
# World average by sector
# ----------------------------
world <- dt[
  ,
  .(
    World = mean(ave2C, na.rm = TRUE)
  ),
  by = .(gtap_code, gtap_desc)
]

# ----------------------------
# Japan average by sector
# Japan as importer
# ----------------------------
japan <- dt[
  importer == "JPN",
  .(
    Japan = mean(ave2C, na.rm = TRUE)
  ),
  by = .(gtap_code, gtap_desc)
]

usa <- dt[
  importer == "USA",
  .(
    USA = mean(ave2C, na.rm = TRUE)
  ),
  by = .(gtap_code, gtap_desc)
]


# ----------------------------
# Combine
# ----------------------------
dt_small <- merge(
  world,
  japan,
  by = c("gtap_code", "gtap_desc"),
  all = FALSE
)

dt_small <- merge(
  dt_small,
  usa,
  by = c("gtap_code", "gtap_desc"),
  all = FALSE
)

# Sort by GTAP sector
setorder(dt_small, gtap_code)

# Check
dt_small[]

# Save small dataset
fwrite(dt_small, "data/04_gvc_enablers/ntm_japan_world_by_sector.csv")

