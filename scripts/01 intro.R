library(data.table)
library(ggpubr)

### gppdc madison
gdppc = fread("./data/temp/madison.csv")
gdppc2 = gdppc[variable=="GDPpc"&date>1900&region!="World"]

fwrite(gdppc2,"../data/01 intro/gdppc.csv")

### growth pwt
pwt = fread("./data/temp/pwt.csv")
pwt2 = merge(pwt[Variablecode=="labsh",.(ISOcode,date,labsh=value)],
             pwt[Variablecode!="labsh",.(ISOcode,date,gyoy,Variablename2)],
             by=c("ISOcode","date"))

pwt3 = pwt2[!is.na(gyoy) &ISOcode%in%c("JPN","USA","CHN")
           &grepl("TFP|service|share|index|persons|hours|GDP",Variablename2)]

fwrite(pwt3,"./data/01 intro/growth.csv")

### trade pwt
# 1: beverage
# 2: industrial supplies
# 3: fuels and lubricants
# 4: capital goods
# 5: transport equipment
# 6: consumer goods
# price: USA GPDo in 2017 = 1
# share in GDP at current PPP

pwt_trade = fread("../data/temp/pwt_trade.csv")
pwt_trade2 = pwt_trade[countrycode%in%c("JPN","USA","CHN")]

fwrite(pwt_trade2,"../data/01 intro/trade.csv")

### share of value added in GDP
wbdt = fread("../data/temp/wbgdppc.csv")
wbdt2 = rbind(wbdt[iso3c!="JPN",.(value=median(value)),
                      by =.(Region,indicator,date)],
              wbdt[iso3c=="JPN",
                      .(Region="JPN",indicator,date,value)])

regs = unique(wbdt[,.(V1=median(value)),
                    by=Region][order(-V1),Region])
regs = c("JPN",regs[regs!="JPN"])
regs_col = c("black",get_palette(palette = "npg",length(regs)-1))
wbdt2[,Region:=factor(Region,levels = regs)]

wbdt3 = wbdt2[grepl("value added",indicator)]
setorder(wbdt3,Region)

fwrite(wbdt3,"../data/01 intro/va.csv")

### population 
unpopd = fread("../data/temp/unpop.csv")
unpop = rbind(unpopd[iso3c!="JPN",
                     .(MedianAgePop=median(MedianAgePop),
                       NatChangeRT=median(NatChangeRT),
                       CNMR=median(CNMR),
                       NetMigrations=sum(NetMigrations)),
                     by =.(Region,date)],
              unpopd[iso3c=="JPN",
                     .(Region=iso3c,
                       date,MedianAgePop,NatChangeRT,CNMR,NetMigrations)])
# MedianAgePop, #Median Age, as of 1 July (years)
# NatChangeRT, #Rate of Natural Change (per 1,000 population)
unpop[,Region:=factor(Region,levels = regs)]
setorder(unpop,Region)

fwrite(unpop,"../data/01 intro/pop.csv")


### value added
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

