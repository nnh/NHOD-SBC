##################################################
# Program : safety.R
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
ptdata1 <- ptdata %>% subset(group == "治癒切除・Chemotherapy群")
ptdata2 <- ptdata %>% subset(group == "治癒未切除・Chemotherapy群")
dfCategory <- data.frame(category = matrix(unlist(strsplit("0,1,2,3,4", ","))))

frequency <- function(x, y){
  dfCount <- y %>%
    select(paste0(x, "_grd"), "group") %>%
    table %>%
    as.data.frame.matrix
  dfLabel <- y %>%
    select(paste0(x, "_trm"), "group") %>%
    table %>%
    as.data.frame.matrix
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(dfCategory, df1, by = "category", all = T)
  df2[is.na(df2)] <- 0
  df3 <- data.frame(t(df2))
  for (i in 1:ncol(df3)) {colnames(df3)[i] <- paste0("Grade", df3[1, i])}
  df3 <- df3[-1,]
  rownames(df3) <- rownames(dfLabel)
  assign(x, df3, .GlobalEnv)
}

frequency("AE_MortoNeuropathy", ptdata1)
frequency("AE_SensNeuropathy", ptdata1)
frequency("AE_diarrhea", ptdata1)
frequency("AE_DecreasNeut", ptdata1)
frequency("AE_DecreasPLT", ptdata1)
frequency("AE_Skin", ptdata1)
frequency("AE_Anorexia", ptdata1)
frequency("AE_HighBDPRES", ptdata1)
frequency("AE_Prote", ptdata1)
ae1 <- rbind(AE_MortoNeuropathy, AE_SensNeuropathy, AE_diarrhea, AE_DecreasNeut, AE_DecreasPLT, AE_Skin, AE_Anorexia, AE_HighBDPRES, AE_Prote)
write.csv(ae1, paste0(outpath, "/ae_RS_CT.csv"), row.names = TRUE, na = "")

frequency("AE_MortoNeuropathy", ptdata2)
frequency("AE_SensNeuropathy", ptdata2)
frequency("AE_diarrhea", ptdata2)
frequency("AE_DecreasNeut", ptdata2)
frequency("AE_DecreasPLT", ptdata2)
frequency("AE_Skin", ptdata2)
frequency("AE_Anorexia", ptdata2)
frequency("AE_HighBDPRES", ptdata2)
frequency("AE_Prote", ptdata2)
ae2 <- rbind(AE_MortoNeuropathy, AE_SensNeuropathy, AE_diarrhea, AE_DecreasNeut, AE_DecreasPLT, AE_Skin, AE_Anorexia, AE_HighBDPRES, AE_Prote)
write.csv(ae2, paste0(outpath, "/ae_nonRS_CT.csv"), row.names = TRUE, na = "")
