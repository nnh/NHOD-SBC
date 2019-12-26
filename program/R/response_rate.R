##################################################
# Program : response_rate.R
# Study : NHOD-SBC
# Published : 2019/12/25
# Author : Kato Kiroku
# Version : 19.12.25.000
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
ptdata1 <- ptdata %>% subset(group == "治癒切除・non-Chemotherapy群")
ptdata2 <- ptdata %>% subset(group == "治癒切除・Chemotherapy群")
ptdata3 <- ptdata %>% subset(group == "治癒未切除・Chemotherapy群")
# ptdata$group1 <- with(ptdata, ifelse(group == "治癒切除・non-Chemotherapy群", group, NA))
# ptdata$group2 <- with(ptdata, ifelse(group %in% c("治癒切除・Chemotherapy群", "治癒未切除・Chemotherapy群"), group, NA))
dfCategory <- data.frame(category = matrix(unlist(strsplit("CR,PR,SD,PD,NE", ","))))

frequency <- function(x, y){
  # COUNT
  dfCount <- y %>%
    select("RECISTORRES", "chemCAT") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", format(unlist(dfPercent)), "%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(dfCategory, df1, by = "category", all = T)
  df2[is.na(df2)] <- "0 (  0.0%)"
  df2 <- df2[c(1, 4, 5, 3, 2), ]
  assign(x, df2, .GlobalEnv)
}
frequency("RECISTORRES1", ptdata1)
frequency("RECISTORRES2", ptdata2)
frequency("RECISTORRES3", ptdata3)

write.csv(RECISTORRES1, paste0(outpath, "/response_rate_RS_nonCT.csv"), row.names = FALSE, na = "")
write.csv(RECISTORRES2, paste0(outpath, "/response_rate_RS_CT.csv"), row.names = FALSE, na = "")
write.csv(RECISTORRES3, paste0(outpath, "/response_rate_nonRS_CT.csv"), row.names = FALSE, na = "")
