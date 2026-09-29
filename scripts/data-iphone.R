library(data.table)


## iphone
iphone = fread("data/slide02/gvc_iphone.txt")
setnames(iphone,gsub("\\(|\\)","",colnames(iphone)))

iphone = iphone[!grepl("Total Bill of Materials|Grand Total",Component)]
iphone[,c("Man","Country"):=tstrsplit(gsub("\\)","",Manufacturer),"\\(")]
iphone[,Manufaturer_Component:=paste0(trimws(Man),"-",trimws(Component))]
iphone[grepl("Other-Manufacturing",Manufaturer_Component),Country:="China"]
iphone[grepl("Other-Rest",Manufaturer_Component),Country:="Unknown"]

ggpubr::ggbarplot(iphone,
                  x="Country",
                  xlab ="",
                  y="Cost USD",
                  label = "Component",
                  fill = "Country")

fwrite(iphone[,.(Country,Manufaturer_Component,`Cost USD`)],
       "data/slide02/gvc_iphone.csv")
