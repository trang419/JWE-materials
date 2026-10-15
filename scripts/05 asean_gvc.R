rm(list=ls())
library(data.table)
library(ggpubr)
library(countrycode)
library(ggrepel)

dtl = arrow::read_parquet("data/temp/gvc_trade.parquet")
setDT(dtl)

dtl[grepl("trade_int",variable),type:="traditional: intermediate goods"]
dtl[grepl("trade_fin",variable),type:="traditional: final goods"]
dtl[grepl("gvcbp",variable),type:="gvc: backward"]
dtl[grepl("gvcfp",variable),type:="gvc: forward"]
dtl[grepl("gvcmix",variable),type:="gvc: mixed"]

eurs = codelist$iso3c[codelist$un.region.name=="Europe"
                      &!is.na(codelist$iso3c)]
NAFTA = c("USA","CAN","MEX")
Idvs = c("JPN","CHN","KOR") #"SGP")
asean4 = c("IDN","THA","MYS","PHL")
asean_new = c("VNM","LAO","KHM","MMR","TLS")
asean_other = c("BRN","SGP")
asean_all = c(asean4,asean_new,asean_other)

### map country code -> region (no cty table needed)
get_region = function(x){
  fcase(
    x %in% eurs,      "Europe",
    x %in% asean4,    "ASEAN4",
    x %in% asean_new, "CLMV",
    x %in% NAFTA,     "N.America",
    x %in% Idvs,      x,        # keep JPN / CHN / KOR as themselves
    default = "ROW"
  )
}

### add regions directly
dtl[, exp_reg := get_region(exp)]
dtl[, imp_reg := get_region(imp)]

dtl[exp%in%asean_new,.(.N,min=min(t),max=max(t),Ny=uniqueN(t)),
   by=.(exp,source)]

### gross trade
dt_reg = rbind(
  dtl[exp=="JPN"&source=="tiva"
      &grepl("Agri|Mining|Manu",sect_group)
      &imp%in%asean_all,
      .(value=sum(value),type="export"),
      by=.(region=imp,t)],
  dtl[imp=="JPN"&source=="tiva"
      &grepl("Agri|Mining|Manu",sect_group)
      &exp%in%asean_all,
      .(value=sum(value),type="import"),
      by=.(region=exp,t)],
  dtl[exp=="JPN"&source=="tiva"
      &grepl("Agri|Mining|Manu",sect_group),
      .(value=sum(value),type="export"),
      by=.(region=imp_reg,t)],
  dtl[imp=="JPN"&source=="tiva"
      &grepl("Agri|Mining|Manu",sect_group),
      .(value=sum(value),type="import"),
      by=.(region=exp_reg,t)])

ggbarplot(dt_reg[region%in%asean_all],
          x="t",
          xlab = "",y="value",
          color = "region",
          fill = "region",
          title="Japan trade") +
  geom_line(data=dt_reg[!region%in%c(asean_all,"ASEAN4","CLMV","JPN")],
            aes(x=t,y=value,color=region,fill=region)) +
  facet_wrap(~type)


fwrite(dt_reg,"data/05 asean/asean_japan_trade.csv")

### import content of export = pure backward + mixed
### SHOULD ALSO ADD FINAL AND INTERMEDIATES AS WELL
dtl[,variable3:=variable]
dtl[variable3=="gvcbp",variable3:="gvc backward"]
dtl[variable3=="gvcfp",variable3:="gvc forward"]
dtl[variable3=="gvcmix",variable3:="gvc mixed"]
dtl[grepl("trade_int",variable),variable3:="final goods"]
dtl[grepl("trade_fin",variable),variable3:="intermediates"]
dtl[,.N,by=variable3]

dtgvc = dtl[,
             .(value=sum(value)),
             by=.(t,source,importer=imp_reg,exporter=exp_reg,sect_name,
                  variable=variable3)]

cregss = c("JPN","CHN","KOR","SGP","BRN","ASEAN4","CLMV","Europe","N.America","ROW")
dtgvc[,exporter:=factor(exporter,levels = cregss)]
dtgvc[,importer:=factor(importer,levels = cregss)]

dtgvc[,.N,by=sect_name]
dtgvc[,.N,by=variable]

### eora
dtgvc_eora = dtgvc[(source=="eora"&t%in%c(1990,1997,2007,2015))
               |(source=="tiva"&t%in%seq(2016,2019))]
dtgvc_eora[,.N,by=.(sect_name)]


ggbarplot(dtgvc_eora[grepl("Electrical",sect_name)&source=="eora"
                &!grepl("Europe|America|ROW",exporter)
                &!grepl("Europe|America|ROW",importer)],
          x="exporter",y="value",
          ylab = "Trade Value",
          facet.by = c("importer","t"),
          color="variable",
          fill = "variable") +
  theme(axis.text.x = element_text(angle = 90))


fwrite(dtgvc_eora[source=="eora",
             .(exporter,importer,sect_name,t,variable,value)],
       "data/05 asean/gvc_asean_eora.csv")

fwrite(dtgvc_eora[source=="tiva",
             .(exporter,importer,sect_name,t,variable,value)],
       "data/05 asean/gvc_asean_tiva.csv")

