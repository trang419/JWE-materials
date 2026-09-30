library(data.table)
library(ggpubr)

dtl = arrow::read_parquet("data/temp/gvc_trade.parquet")
setDT(dtl)

dtl[grepl("trade_int",variable),type:="traditional: intermediate goods"]
dtl[grepl("trade_fin",variable),type:="traditional: final goods"]
dtl[grepl("gvcbp",variable),type:="gvc: backward"]
dtl[grepl("gvcfp",variable),type:="gvc: forward"]
dtl[grepl("gvcmix",variable),type:="gvc: mixed"]

### world trade
dtw = dtl[,.(value=sum(value)),
          by=.(variable,type,t)]
dtw[,valuetot:=sum(value),by=t]
dtw[,share:=round(100*value/valuetot,0)]
dtw[,label:=paste0(type,"(",share,")")]

ggarrange(
  ggpie(dtw[t==2020],
        x="share",
        color="variable",
        fill="variable",
        legend="none",
        label="variable",
        title = "2020"),
  ggpie(dtw[t==1970],
        x="share",
        color="variable",
        fill="variable",
        legend="none",
        label="variable",
        title = "1970",
        caption = "Source: WITS, WIOD, TIVA")
)

fwrite(dtw[t%in%c(1970,2020)],"data/03 gvc/gvc_share.csv")

### japan total trade by flow of gvc
dt_gvc = rbind(
  dtl[exp=="JPN",.(value=sum(value),flow="export"),by=.(variable,type,t)],
  dtl[imp=="JPN",.(value=sum(value),flow="import"),by=.(variable,type,t)])
dt_gvc[,gtrade:=sum(value),by=.(t,flow)]
dt_gvc[,share:=value/gtrade]

ggbarplot(dt_gvc,
          x="t",xlab = "",y="share",
          fill="type",
          color = "type",
          facet.by = "flow",
          title="Japan trade")

fwrite(dt_gvc,"data/03 gvc/gvc_JPN.csv")

## intensity by region
dt_index = dtl[,.(value=sum(value)),by=.(region=exp,t,variable,type)]
dt_index[,gtrade:=sum(value),by=.(region,t)]
dt_index[,share:=value/gtrade]
dt_index[,share_temp:=ifelse(grepl("gvc",variable),share,0)]
dt_index[,gvc_share:=sum(share_temp),by=.(region,t)]
setorder(dt_index,t,-gvc_share)
dt_index[,rid:=rleid(region),by=t]
dt_index[,RegionRank:=paste0(sprintf("%02d",rid),"_",region)]
dt_index[1:100]

ggarrange(
  ggbarplot(dt_index[t==1970&
                       grepl("gvc",variable)&
                       (rid<=10|grepl("JPN|USA|CHN",region))],
            x="RegionRank",y="share",
            facet.by = "t",
            color = "variable",
            fill = "variable") +
    theme(axis.text.x = element_text(angle = 90)),
  ggbarplot(dt_index[t==2000&
                       grepl("gvc",variable)&
                       (rid<=10|grepl("JPN|USA|CHN",region))],
            x="RegionRank",y="share",
            facet.by = "t",
            color = "variable",
            fill = "variable") +
    theme(axis.text.x = element_text(angle = 90)),
  ggbarplot(dt_index[t==2010&
                       grepl("gvc",variable)&
                       (rid<=10|grepl("JPN|USA|CHN",region))],
            x="RegionRank",y="share",
            facet.by = "t",
            color = "variable",
            fill = "variable") +
    theme(axis.text.x = element_text(angle = 90)),
  ggbarplot(dt_index[t==2020&
                       grepl("gvc",variable)&
                       (rid<=10|grepl("JPN|USA|CHN",region))],
            x="RegionRank",y="share",
            facet.by = "t",
            color = "variable",
            fill = "variable") +
    theme(axis.text.x = element_text(angle = 90)),
  common.legend = T
)

fwrite(dt_index[t%in%c(1970,2020)&
                  grepl("gvc",variable)&
                  (rid<=10|grepl("JPN|USA|CHN",region)),
                .(RegionRank,share,t,variable,type)],
       "data/03 gvc/gvc_region.csv")

### index by sector
dt_index_sect = dtl[exp=="JPN",.(value=sum(value)),
                    by=.(region=exp,t,sect_group,sect_name,variable,type)]
dt_index_sect[,gtrade:=sum(value),by=.(region,t,sect_name)]
dt_index_sect[,share:=value/gtrade]
dt_index_sect[,share_temp:=ifelse(grepl("gvc",variable),share,0)]
dt_index_sect[,gvc_share:=sum(share_temp),by=.(region,t,sect_name)]

dt_index_sect_w = dcast(dt_index_sect[t%in%c(1970,2000)],
                        sect_name + type ~ paste0("gvc",t),
                        value.var = "gvc_share")

ggscatter(dt_index_sect_w,
          x="gvc2000",
          y="gvc1970",
          facet.by = "type",
          label = "sect_name")

fwrite(dt_index_sect_w, "data/03 gvc/gvc_jpn_sect.csv")

### forwardness by sector
dt_index_sect_w = dcast(dt_index_sect[grepl("gvc",variable)],
                        sect_group + sect_name + t ~ variable,
                        value.var = "value")

dt_index_sect_w[,forwardness:=(gvcfp-gvcbp)/(gvcfp+gvcbp+gvcmix)]
dt_index_sect_w[,t:=as.character(t)]

ggdensity(dt_index_sect_w,
          x="forwardness",
          color = "t")

ggbarplot(dt_index_sect_w[t%in%c(2005,2020)],
          x="sect_name",
          y="forwardness",
          facet.by = c("sect_group","t"),
          rotate = T) 

dt_index_sect_ww = dcast(dt_index_sect_w[t%in%c(1970,2000)],
                        sect_name  ~ paste0("forward",t),
                        value.var = "forwardness")

ggscatter(dt_index_sect_ww,
          caption = "Data Source: WITS, WIOD",
          x="forward1970",y="forward2000",
          xlab="Forwardness in 1970",
          ylab ="Forwardness in 2000",
          legend="none") +
  geom_abline(intercept = 0, slope = 1, 
              linetype = "dotdash") +
  geom_hline(yintercept = 0, linetype = "dotdash") +
  geom_vline(xintercept = 0, linetype = "dotdash") +
  geom_text_repel(aes(x = forward1970, 
                      y = forward2000, 
                      label = sect_name, 
  ),
  data = dt_index_sect_ww, size = 2,max.overlaps = 20,
  show.legend = FALSE)

fwrite(dt_index_sect_ww[!is.na(forward1970)&!is.na(forward2000)],
       "data/03 gvc/gvc_jpn_sect_forward.csv")

### bilateral gvc
dt_gvc_reg = rbind(
  dtl[exp=="JPN"&imp!="JPN",.(value=sum(value)/10^3,flow="export"),
      by=.(type,variable,t,region=imp_reg,sect_group)],
  dtl[imp=="JPN"&exp!="JPN",.(value=sum(value)/10^3,flow="import"),
      by=.(type,variable,t,region=exp_reg,sect_group)])
dt_gvc_reg[,gtrade:=sum(value),by=.(t,flow,region,sect_group)]
dt_gvc_reg[,share:=value/gtrade]
dt_gvc_reg[,gtrade_w:=sum(value),by=.(t,flow)]
dt_gvc_reg[,gtrade_sh:=round(gtrade/gtrade_w,2)]
dt_gvc_reg[,region_share:=paste0(region,"(",gtrade_sh,")")]

dt_gvc_reg[,.N,by=region]
reg_lab = c("KOR","CHN","ASEAN","Europe","N.America","ROW")
dt_gvc_reg[,region:=factor(region,levels = reg_lab)]
setorder(dt_gvc_reg,t,flow,region)
dt_gvc_reg[,value2:=ifelse(flow=="import",-1*value,value)]

ggbarplot(dt_gvc_reg[t==2020&
                       grepl("Manu|Agri|Mining|Service",sect_group)],
          x="region",
          xlab="",
          ylab = "billion USD",
          y="value2",
          fill="variable",
          color = "variable",
          facet.by = c("sect_group"),
          title="Japan trade",
          rotate =T) +
  geom_vline(xintercept = 0,
             color = "black", linetype = "dotdash")

fwrite(dt_gvc_reg[t==2020&
                    grepl("Manu|Agri|Mining|Service",sect_group)],
       "data/03 gvc/gvc_jpn_bilateral.csv")

### gvc in vehicles
dtl[grepl("Motor vehicle|Electrical|Chemical|Agricul",sect_name)&
    t==2001,.N,by=.(sect_name)]

dt_sec = dcast(
  dtl[grepl("Motor vehicle|Electrical|Chemical|Agricul",sect_name)
      &t>=2001],
  exp + exp_reg + t + sect_name ~ variable,
  value.var="value",
  fun.aggregate=sum)
             
dt_sec[,forwardness:=(gvcfp-gvcbp)/(gvcfp+gvcbp+gvcmix)]
dt_sec[,intensity:=(gvcfp+gvcbp+gvcmix)/(gvcfp+gvcbp+gvcmix+traditional_trade_int+traditional_trade_fin)]

ggplot(
  dt_sec[t%in%c(2001,2020)],
  aes(
    x = forwardness,
    y = intensity,
    color = sect_name
  )
) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_point(alpha = 0.6, size = 2) +
  facet_wrap(~t) +
  scale_x_continuous(
    limits = c(-1, 1),
    breaks = seq(-1, 1, .5)
  ) +
  labs(
    x = "GVC Position (Forwardness)",
    y = "GVC Intensity",
    color = "Sector"
  ) +
  theme_minimal()

fwrite(dt_sec[t%in%c(2001,2020)&!is.na(forwardness)&!is.na(intensity),
              .(forwardness,intensity,exp,sect_name,t)],
       "data/03 gvc/gvc_case_index.csv")

dt_sec_l = dtl[grepl("Motor vehicle|Electrical|Chemical|Agricul",sect_name)
      &t>=2001&grepl("gvc",type),
      .(type,value,t,sect_name,exp,exp_reg)]

dt_sec_l[,value_tot:=sum(value),by=.(t,exp,exp_reg,sect_name)]
dt_sec_l[,value_sh:=value/value_tot]

fwrite(dt_sec_l[t%in%c(2001,2020)&exp=="JPN"],
       "data/03 gvc/gvc_case_jpn_share.csv")
