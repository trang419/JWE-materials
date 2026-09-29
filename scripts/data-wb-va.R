# Install wbstats if not already installed
if (!require(wbstats)) install.packages("wbstats")

library(wbstats)
library(data.table)
library(countrycode)

# Define indicators
indicators <- c(
  "NY.GDP.PCAP.CD",  # GDP per capita (current US$)
  "NY.GDP.PCAP.KD",   # GDP per capita (constant 2015 US$)
  "NV.IND.MANF.ZS",    #Manufacturing, value added (% of GDP)
  "NV.SRV.TOTL.ZS",   #Services, value added (% of GDP)
  "SP.POP.DPND.OL"
)

# Download data
gdp_data <- wb_data(
  indicator   = indicators,
  start_date  = 1960,
  end_date    = 2023,
  return_wide = FALSE
)

# Country meta
countries_meta <- wb_countries() 
setDT(countries_meta)
eur = codelist$iso3c[codelist$unhcr.region=="Europe"]
MENA = codelist$iso3c[codelist$unhcr.region=="Middle East and North Africa"]

countries_meta[,Region:=region]
countries_meta[iso3c%in%eur,Region:="Europe"]
countries_meta[iso3c%in%MENA,Region:="Middle East & North Africa"]
countries_meta[!iso3c%in%eur&region=="Europe & Central Asia",Region:="Central Asia"]
countries_meta[!iso3c%in%MENA&region=="Middle East, North Africa, Afghanistan & Pakistan",Region:="Central Asia"]
countries_meta[Region%in%c("Central Asia","South Asia"),
        Region:="South & Central Asia"]
countries_meta[,.N,by=Region]

# Process data
setDT(gdp_data)

dt = merge(gdp_data[!is.na(value),
                    .(indicator,iso3c,date,value)],
           countries_meta[,.(iso3c,income_level,Region)],
           by="iso3c")

dt[,.N,by=Region]

dt[,Nc:=.N,by=.(indicator,iso3c)]
dt[,Nc.max:=max(Nc),by=.(indicator,Region)]
dt[Nc!=Nc.max,.N,by=iso3c]
dt = dt[Nc==Nc.max|iso3c=="JPN",!"Nc.max"]
dt[,.N,by=Region]

dt[grepl("USA|CHN|JPN",iso3c),.N,by=.(indicator,iso3c)]

# Write
fwrite(dt,"./data/temp/wbgdppc.csv")
fwrite(countries_meta[,.(iso3c,Region)],"./data/temp/countries_meta.csv")
