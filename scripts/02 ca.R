library(data.table)
library(ggpubr)
library(countrycode)
library(ggrepel)
library(forcats)

dt = arrow::read_parquet("data/temp/gvc_trade.parquet")
setDT(dt)

###
dt[,.N,by=variable]

### revealed CA
dt[,variable2:=ifelse(grepl("tradition",variable),"traditional","gvc")]
dtca = dt[,.(value=sum(value)),
           by=.(source,sect_name,sect_group,
                region=exp,t,variable=variable2)]
dtca[,value_w:=sum(value),by=.(source,region,t,variable)]
dtca[,value_w_tot:=sum(value),by=.(source,t,variable)]
dtca[,value_w_sect:=sum(value),by=.(source,t,sect_name,variable)]
dtca[,RCA:=(value/value_w)/(value_w_sect/value_w_tot)]
dtca[,export_sh:=100*value/value_w]
dtca[,export_w_sh:=100*value_w_sect/value_w_tot]

dtcaw = dcast(dtca,
              source + region + t + sect_name + sect_group ~ variable,
              value.var = "RCA",
              fun.aggregate = mean,
              drop = T)

##
dtcaw_tiva = dtcaw[source=="tiva"
                   &region=="JPN"
                   &t==2019
                   &!is.na(traditional)]

dtcaw_tiva[dtca,on=.(region,source,t,sect_name),
           export_share:=export_sh]

dtcaw_tiva[, label_sect := ifelse(traditional > 1.5|export_share>5, sect_name, "")]

ggscatter(
  dtcaw_tiva,
  x = "export_share",     
  y = "traditional",
  size = "export_share",
  xlab = "Japan's export share",
  ylab = "RCA",
  title = "Japan RCA vs. Export Share, 2019",
  caption = "Source: TIVA from WITS"
) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
  geom_text_repel(
    aes(label = label_sect),
    size = 3.2,
    max.overlaps = 20,
    box.padding = 0.4
  ) +
  theme(legend.position = "none")

fwrite(dtcaw_tiva,"./data/02 ca/rca_jpn_tiva.csv")

##
dtcaw_wiod_jpn = dtcaw[source=="wiodlr"&region=="JPN"
                       &grepl("Manufacturing|Agriculture",sect_group)]
dtcaw_wiod_jpn[,period:=cut(t,
                            breaks = c(seq(1964,1985,10),2000),
               labels = c("1965-1974","1975-1984","1985-2000"))]
dtcaw_wiod_jpn[,traditional_med:=median(traditional),by=sect_name]
order_levels = unique(dtcaw_wiod_jpn[order(-traditional_med),sect_name])
dtcaw_wiod_jpn[,sect_name:=factor(sect_name,levels = order_levels)]

ggboxplot(
  dtcaw_wiod_jpn,
  x = "sect_name",
  xlab = "sector",
  y = "traditional",
  ylab = "RCA",
  rotate=T,
  facet.by = "period",
  nrow=1
)

fwrite(dtcaw_wiod_jpn,
       "./data/02 ca/rca_jpn.csv")

### compare gvc and tradition
dtcaw_wiod_jpn[,label:=ifelse(traditional>1|gvc>1,sect_name,"")]

ggscatter(dtcaw_wiod_jpn[t%in%c(1970,2000)],
          x="traditional",y="gvc",facet.by = "t",
          color = "sect_group") +
  #label = dtcaw_jpn$label,
  #repel = T,
  #font.label = c(6, "plain", "black")) +
  geom_abline(intercept = 0, slope = 1, color = "red",
              linetype = "dotdash") +
  geom_hline(yintercept = 1, linetype = "dotdash") +
  geom_vline(xintercept = 1, linetype = "dotdash") +
  geom_text_repel(aes(x = traditional, y = gvc, label = label, 
                      color = sect_group),
                  data = dtcaw_wiod_jpn[t%in%c(1970,2000)], size = 2,
                  show.legend = FALSE)


### 
regss = c("JPN","CHN","VNM",
          "SGP","THA","MYS",
          "LUX","DEU","SVK",
          "USA","MEX","SAU")

dtcaw_reg = dtcaw[source=="wiodlr"
                  #&region%in%regss
                  &grepl("Manufacturing|Agriculture",sect_group)
                  &grepl("Electrical|Transport|Machinery|Textile|Metals|Recyling",sect_name)
                  &t%in%c(1970,1990,2000)]
dtcaw_reg[,t:=as.character(t)]
dtcaw_reg[,sect_name:=factor(sect_name,levels = order_levels)]

# Japan's value per sector/period, to draw the vertical line
japan_vals <- dtcaw_reg[region == "JPN",
                        .(traditional_jpn = traditional), 
                        by = .(sect_name, t)]
us_vals <- dtcaw_reg[region == "USA",
                        .(traditional_usa = traditional), 
                        by = .(sect_name, t)]
chn_vals <- dtcaw_reg[region == "CHN",
                     .(traditional_chn= traditional), 
                     by = .(sect_name, t)]


# Merge back so each facet has Japan's reference value available
dtcaw_reg <- merge(dtcaw_reg, japan_vals, by = c("sect_name", "t"), all.x = TRUE)

ggdensity(
  dtcaw_reg,
  x = "traditional",
  facet.by = c("t", "sect_name"),
  ncol = 3
) +
  geom_vline(
    data = japan_vals,
    aes(xintercept = traditional_jpn, color = "Japan"),
    linetype = "dashed", linewidth = 0.8
  ) +
  geom_vline(
    data = us_vals,
    aes(xintercept = traditional_usa, color = "United States"),
    linetype = "dashed", linewidth = 0.8
  ) +
  geom_vline(
    data = chn_vals,
    aes(xintercept = traditional_chn, color = "China"),
    linetype = "dashed", linewidth = 0.8
  ) +
  scale_color_manual(
    name = "Country",
    values = c("Japan" = "red", "United States" = "blue", "China" = "darkgreen")
  ) +
  xlab("RCA") +
  theme(strip.text = element_text(size = 9))


fwrite(dtcaw_reg,"./data/02 ca/rca_reg.csv")

### trad vs gvc
dtcaw_reg[,label:=ifelse(traditional>1|gvc>1,sect_name,"")]
dtcaw_reg[,region:=factor(region,levels=regss)]
setorder(dtcaw_reg,region)
ggscatter(dtcaw_reg,
          x="traditional",y="gvc",facet.by = "region") +
  # label = dtcaw_reg$label,
  # repel = T,
  # font.label = c(6, "plain", "black")) +
  geom_abline(intercept = 0, slope = 1, color = "red",
              linetype = "dotdash") +
  geom_hline(yintercept = 1, linetype = "dotdash") +
  geom_vline(xintercept = 1, linetype = "dotdash") +
  geom_text_repel(aes(x = traditional, y = gvc, label = label, 
                      color = sect_group),
                  data = dtcaw_reg, size = 2, max.overlaps = 40,
                  show.legend = FALSE)


