library(data.table)

pwt = "data/raw/pwt1001-trade-detail.csv"
pwtd = fread(pwt,header = T)
setnames(pwtd,gsub(" ","",colnames(pwtd)))
str(pwtd)
pwtd[,.N,by=year]
pwtd[grepl("VNM",countrycode)]

# 1: beverage
# 2: industrial supplies
# 3: fuels and lubricants
# 4: capital goods
# 5: transport equipment
# 6: consumer goods
# price: USA GPDo in 2017 = 1
# share in GDP at current PPP

pwtdl = melt(pwtd,
             id.vars = c("countrycode","year"))

ggpubr::ggline(pwtdl[countrycode%in%c("JPN","USA","CHN")&
                       grepl("csh",variable)],
               x="year",y="value",color="countrycode",
               facet.by = "variable",
               numeric.x.axis = T)

ggpubr::ggline(pwtdl[countrycode%in%c("JPN","USA","CHN")&
                       grepl("pl",variable)],
               x="year",y="value",color="countrycode",
               facet.by = "variable",
               numeric.x.axis = T)
pwtdl[,sectorid:=gsub("^.*(x|m)","",variable)]
pwtdl[sectorid%in%c(2,3),sector:="energy and materials"]
pwtdl[sectorid%in%c(4,5),sector:="capital goods"]
pwtdl[sectorid%in%c(1,6),sector:="consumer goods"]

pwtdl[,c("var","type"):=tstrsplit(variable,"_")]
pwtdl[grepl("m",type),type:="m"]
pwtdl[grepl("x",type),type:="x"]

pwtdl_sum = pwtdl[var=="csh"&countrycode%in%c("JPN","USA","CHN")&!is.na(value),
                  .(value=sum(value)),
                  by=.(var,type,sector,countrycode,year)]
pwtdl_sum

fwrite(pwtdl_sum,"data/temp/pwt_trade.csv")
