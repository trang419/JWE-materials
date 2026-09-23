library(data.table)
library(ggpubr)

### gppdc madison
gdppc = fread("./data/temp/madison.csv")
gdppc2 = gdppc[variable=="GDPpc"&date>1900&region!="World"]

fwrite(gdppc2,"../data/01 intro/gdppc.csv")

### growth pwt
pwt = fread("./data/temp/pwt.csv")
pwt2 = pwt[!is.na(gyoy) &ISOcode%in%c("JPN","USA","CHN")
           &grepl("TFP|service|share|index|persons|hours",Variablename2)]

fwrite(pwt2,"./data/01 intro/growth.csv")

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

