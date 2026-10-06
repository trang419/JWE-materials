library(data.table)

iphone <- data.table(
  Manufacturer = c(
    "Toshiba (Japan)",
    "Toshiba (Japan)",
    "Toshiba (Japan)",
    "Samsung (Korea)",
    "Samsung (Korea)",
    "Infineon (Germany)",
    "Infineon (Germany)",
    "Infineon (Germany)",
    "Infineon (Germany)",
    "Infineon (Germany)",
    "Broadcom (US)",
    "Numonyx (US)",
    "Murata (Japan)",
    "Dialog Semiconductor (Germany)",
    "Cirrus Logic (US)",
    "Other",
    "Other",
    "Other",
    "Other"
  ),
  
  Component = c(
    "Flash Memory",
    "Display Module",
    "Touch Screen",
    "Application Processor",
    "SDRAM-Mobile DDR",
    "Baseband",
    "Camera Module",
    "RF Transceiver",
    "GPS Receiver",
    "Power IC RF Function",
    "Bluetooth/FM/WLAN",
    "Memory MCP",
    "FEM",
    "Power IC Application Processor Function",
    "Audio Codec",
    "Rest of Bill of Materials",
    "Total Bill of Materials",
    "Manufacturing costs",
    "Grand Total"
  ),
  
  `Cost (USD)` = c(
    24.00,
    19.25,
    16.00,
    14.46,
    8.50,
    13.00,
    9.55,
    2.80,
    2.25,
    1.25,
    5.95,
    3.65,
    1.35,
    1.30,
    1.15,
    48.00,
    172.46,
    6.50,
    178.96
  )
)

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
       "data/02 gvc/gvc_iphone.csv")
