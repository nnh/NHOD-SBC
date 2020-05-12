##################################################
# Program : response_rate.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/05/12
# Version : 000.20.05.12
##################################################

library(readxl)
library(tidyverse)
library(magrittr)

getwd()
prtpath <- "//ARONAS/Stat/Trials/NHO/NHOD-SBC"

adspath <- paste0(prtpath, "/ptosh-format/ads")
docpath <- paste0(prtpath, "/document")
rawpath <- paste0(prtpath, "/input/rawdata")
outpath <- paste0(prtpath, "/output/R")

ptdata <- read.csv(paste0(adspath, "/ptdata.csv"), na.strings = "")
allocation <- read_excel(paste0(docpath, "/解析対象集団一覧.xlsx"), na = "")
allocation <- allocation %>%
  rename(SUBJID = 症例登録番号, group = 解析対象集団)
ptdata <- merge(ptdata, allocation, by = "SUBJID", all = T)
ptdata1 <- ptdata %>% subset(group == "治癒切除・non-Chemotherapy群")
ptdata1$chemCAT <- ifelse(is.na(ptdata1$chemCAT), "治療なし", ptdata1$chemCAT)
ptdata2 <- ptdata %>%
  subset(group == "治癒切除・Chemotherapy群")
ptdata2 <- ptdata2 %>%
  add_row(chemCAT = as.vector(ptdata2[["adjuvantCAT"]]), RECISTORRES = as.vector(ptdata2[["RECISTORRES"]])) %>%
  drop_na(chemCAT)
ptdata3 <- ptdata %>%
  subset(group == "治癒未切除・Chemotherapy群")
ptdata3 <- ptdata3 %>%
  add_row(chemCAT = as.vector(ptdata3[["adjuvantCAT"]]), RECISTORRES = as.vector(ptdata3[["RECISTORRES"]])) %>%
  drop_na(chemCAT)

dfCategory <- data.frame(category = matrix(unlist(strsplit("CR,PR,SD,PD,NE", ","))))
dfVarList1 <- data.frame(colnames = matrix(unlist(strsplit("治療なし", ","))))
dfVarList2 <- data.frame(VarList = matrix(unlist(strsplit("UFT+LV/S-1,FOLFOX,CapeOX,5'DFUR/capecitabine,Other.regimens,治療なし", ","))))
df2 <- data.frame(t(dfVarList2[-1]))
for (i in 1:ncol(df2)) {colnames(df2)[i] <- as.character(dfVarList2[i, 1])}
a <- bind_rows(df2, noquote("RECISTORRES2"))

frequency <- function(x, y, z){
  # dfCountN <- y %>%
  #   mutate(count = "例数") %>%
  #   drop_na("RECISTORRES") %>%
  #   select("count", "chemCAT") %>%
  #   table %>%
  #   as.data.frame.matrix
  dfVarList1 <- data.frame(VarList = matrix(unlist(strsplit(z, ","))))
  dfVarList2 <- data.frame(t(dfVarList1[-1]))
  for (i in 1:ncol(dfVarList2)) {colnames(dfVarList2)[i] <- as.character(dfVarList1[i, 1])}
  # COUNT
  dfCount <- y %>%
    select("RECISTORRES", "chemCAT") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- format(round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1), nsmall = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", str_trim(format(unlist(dfPercent))), "%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  # dfCount <- rbind(dfCountN, dfCount)
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(dfCategory, df1, by = "category", all = T)
  df2[is.na(df2)] <- "0 (0.0%)"
  df2 <- df2[c(1, 4, 5, 3, 2), ]
  df3 <- bind_rows(dfVarList2, df2)
  assign(x, df3, .GlobalEnv)
}
frequency("RECISTORRES1", ptdata1, "治療なし")
frequency("RECISTORRES2", ptdata2, "UFT+LV.S-1,FOLFOX,CapeOX,5'DFUR.capecitabine,Other.regimens,治療なし")
frequency("RECISTORRES3", ptdata3, "FOLFOX.CapeOX.SOX,FOLFOX+セツキシマブ,FOLFOX+ベバシズマブ,FOLFOX+パニツムマブ,FOLFIRI,FOLFIRI+セツキシマブ,FOLFIRI+ベバシズマブ,FOLFIRI+パニツムマブ,5FU+LV,Other.regimens,治療なし")

library(XLConnect)
writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(RECISTORRES1, RECISTORRES2, RECISTORRES3),
                     sheet = c("T015", "T016", "T017"),
                     startRow = c(6, 6, 6),
                     startCol = c(1, 1, 1),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# write.csv(RECISTORRES1, paste0(outpath, "/S_5_5_3_response_ope_no_chemo.csv"), row.names = FALSE, na = "")
# write.csv(RECISTORRES2, paste0(outpath, "/S_5_5_3_response_ope_chemo.csv"), row.names = FALSE, na = "")
# write.csv(RECISTORRES3, paste0(outpath, "/S_5_5_3_response_non_ope_chemo.csv"), row.names = FALSE, na = "")
