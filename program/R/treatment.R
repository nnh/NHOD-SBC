##################################################
# Program : treatment.R
# Study : NHOD-SBC
# Published : 2019/12/10
# Author : Kato Kiroku
# Version : 19.12.10.000
##################################################

library(openxlsx)
library(tidyverse)
library(magrittr)

getwd()
prtpath <- "//ARONAS/Stat/Trials/NHO/NHOD-SBC"

adspath <- paste0(prtpath, "/ptosh-format/ads")
docpath <- paste0(prtpath, "/document")
rawpath <- paste0(prtpath, "/input/rawdata")
outpath <- paste0(prtpath, "/output/R")

ptdata <- read.csv(paste0(adspath, "/ptdata.csv"), na.strings = "")
allocation <- read.xlsx(paste0(docpath, "/解析対象集団一覧.xlsx"), na.strings = "")
allocation <- allocation %>%
  rename(SUBJID = 症例登録番号, group = 解析対象集団)
ptdata <- merge(ptdata, allocation, by = "SUBJID", all = T)

frequency <- function(x, y){
  dfCategory <- data.frame(category = matrix(unlist(strsplit(y, ","))))
  if (x == "resectionCAT"){
    ptdata2 <- ptdata %>% subset(group %in% c("治癒切除・Chemotherapy群", "治癒切除・non-Chemotherapy群"))
  } else if (x == "adjuvantCAT"){
    ptdata2 <- ptdata %>% subset(group == "治癒切除・Chemotherapy群")
  } else if (x == "chemCAT"){
    ptdata2 <- ptdata %>% subset(group == "治癒未切除・Chemotherapy群")
  } else {
    ptdata2 <- ptdata
  }
  # COUNT
  dfCount <- ptdata2 %>%
    select(x, "group") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", format(unlist(dfPercent)), "%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T)
  df2[is.na(df2)] <- "0 (  0.0%)"
  assign(x, df2, .GlobalEnv)
}
frequency("resectionCAT", "RX,R0,R1,R2")
frequency("adjuvantCAT", "UFT+LV/S-1,FOLFOX,CapeOX,5'DFUR/capecitabine,Other regimens")
frequency("chemCAT", "FOLFOX/CapeOX/SOX,FOLFOX+セツキシマブ,FOLFOX+ベバシズマブ,FOLFOX+パニツムマブ,FOLFIRI,FOLFIRI+セツキシマブ,FOLFIRI+ベバシズマブ,FOLFIRI+パニツムマブ,5FU+LV,Other regimens")
frequency("PLresectionYN", "あり,なし")
# https://stackoverflow.com/questions/18142117/how-to-replace-nan-value-with-zero-in-a-huge-data-frame/18143097

write.csv(resectionCAT, paste0(outpath, "/surgical_curability.csv"), row.names = FALSE, na = "")
write.csv(adjuvantCAT, paste0(outpath, "/adjuvant_chemotherapy_regimen.csv"), row.names = FALSE, na = "")
write.csv(chemCAT, paste0(outpath, "/firstline_chemotherapy_regimen.csv"), row.names = FALSE, na = "")
write.csv(PLresectionYN, paste0(outpath, "/primary_tumor_resection.csv"), row.names = FALSE, na = "")

