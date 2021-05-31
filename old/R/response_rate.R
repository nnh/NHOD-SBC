##################################################
# Program : response_rate.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/05/13
# Version : 001.20.05.13
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

frequency <- function(x, y, z){
  # COLUMN VARIABLE LIST
  dfVarList1 <- data.frame(VarList = matrix(unlist(strsplit(z, ","))))
  dfVarList2 <- data.frame(t(dfVarList1[-1]))
  for (i in 1:ncol(dfVarList2)) {colnames(dfVarList2)[i] <- as.character(dfVarList1[i, 1])}
  # TOTAL NUMBER OF EACH VARIABLE
  dfCountN <- y %>%
    mutate(count = "例数") %>%
    drop_na("RECISTORRES") %>%
    select("count", "chemCAT") %>%
    table %>%
    as.data.frame.matrix
  dfCountN2 <- bind_rows(dfVarList2, dfCountN)
  dfCountN2[is.na(dfCountN2)] <- 0
  dfCountN2[] <- paste0("(n=", dfCountN2[], ")")
  assign(paste0(x, "_Num"), dfCountN2, .GlobalEnv)
  # COUNT
  dfCount <- y %>%
    drop_na("RECISTORRES") %>%
    select("RECISTORRES", "chemCAT") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- format(round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1), nsmall = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", str_trim(format(unlist(dfPercent))), "%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  df1 <- merge(dfCategory, dfCount, by.x = "category", by.y = "row.names", all = TRUE)
  df2 <- bind_rows(dfVarList2, df1) %>%
    arrange(match(category, c("CR","PR","SD","PD","NE"))) %>%
    select(category, everything())
  df2[is.na(df2)] <- "0 (0.0%)"
  assign(x, df2, .GlobalEnv)
}
frequency("RECISTORRES1", ptdata1, "治療なし")
frequency("RECISTORRES2", ptdata2, "UFT+LV/S-1,FOLFOX,CapeOX,5'DFUR/capecitabine,Other regimens,治療なし")
frequency("RECISTORRES3", ptdata3, "FOLFOX/CapeOX/SOX,FOLFOX+セツキシマブ,FOLFOX+ベバシズマブ,FOLFOX+パニツムマブ,FOLFIRI,FOLFIRI+セツキシマブ,FOLFIRI+ベバシズマブ,FOLFIRI+パニツムマブ,5FU+LV,Other regimens,治療なし")

library(XLConnect)
writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(RECISTORRES1, RECISTORRES2, RECISTORRES3, RECISTORRES1_Num, RECISTORRES2_Num, RECISTORRES3_Num),
                     sheet = c("T015", "T016", "T017", "T015", "T016", "T017"),
                     startRow = c(6, 6, 6, 5, 5, 5),
                     startCol = c(1, 1, 1, 2, 2,2),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# write.csv(RECISTORRES1, paste0(outpath, "/S_5_5_3_response_ope_no_chemo.csv"), row.names = FALSE, na = "")
# write.csv(RECISTORRES2, paste0(outpath, "/S_5_5_3_response_ope_chemo.csv"), row.names = FALSE, na = "")
# write.csv(RECISTORRES3, paste0(outpath, "/S_5_5_3_response_non_ope_chemo.csv"), row.names = FALSE, na = "")
