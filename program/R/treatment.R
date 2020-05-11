##################################################
# Program : treatment.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/05/11
# Version : 000.20.05.11
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
  dfCountN <- ptdata2 %>%
    mutate(count = "例数") %>%
    drop_na(all_of(x)) %>%
    select("count", "group") %>%
    table %>%
    as.data.frame.matrix
  for (i in 1:ncol(dfCountN)) {dfCountN[[i]] <- paste0("(n=", dfCountN[[i]], ")")}
  # COUNT
  dfCount <- ptdata2 %>%
    select(all_of(x), "group") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- format(round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1), nsmall = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", str_trim(format(unlist(dfPercent))), "%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  dfCount <- rbind(dfCountN, dfCount)
  if (x == "resectionCAT"){
    dfCount <- dfCount[c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群")]
  } else if (x == "PLresectionYN"){
    dfCount <- dfCount[c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]
  }
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T) %>%
    mutate(category = factor(category, levels = c("例数", unlist(strsplit(y, ","))))) %>%
    arrange(category)
  df2[is.na(df2)] <- "0 (0.0%)"
  assign(x, df2, .GlobalEnv)
}
frequency("resectionCAT", "RX,R0,R1,R2")
frequency("adjuvantCAT", "UFT+LV/S-1,FOLFOX,CapeOX,5'DFUR/capecitabine,Other regimens")
frequency("chemCAT", "FOLFOX/CapeOX/SOX,FOLFOX+セツキシマブ,FOLFOX+ベバシズマブ,FOLFOX+パニツムマブ,FOLFIRI,FOLFIRI+セツキシマブ,FOLFIRI+ベバシズマブ,FOLFIRI+パニツムマブ,5FU+LV,Other regimens")
frequency("PLresectionYN", "あり,なし")

resectionCAT <- resectionCAT[, -1]
adjuvantCAT <- adjuvantCAT[, -1]
chemCAT <- chemCAT[, -1]
PLresectionYN <- PLresectionYN[, -1]

library(XLConnect)
writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(resectionCAT, adjuvantCAT, chemCAT, PLresectionYN),
                     sheet = c("T003", "T004", "T005", "T006"),
                     startRow = c(5, 5, 5, 5),
                     startCol = c(2, 2, 2, 2),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# write.csv(resectionCAT, paste0(outpath, "/S_5_4_1_surgical_curability.csv"), row.names = FALSE, na = "")
# write.csv(adjuvantCAT, paste0(outpath, "/S_5_4_2_adjuvant_chemo_regimen.csv"), row.names = FALSE, na = "")
# write.csv(chemCAT, paste0(outpath, "/S_5_4_3_first_line_chemo_regimen.csv"), row.names = FALSE, na = "")
# write.csv(PLresectionYN, paste0(outpath, "/S_5_4_4_primary_site_resection.csv"), row.names = FALSE, na = "")

# Excel
# library(excel.link)
# library(tcltk2)
# tk2dde("R")
# xl.workbook.open("//ARONAS/Stat/Trials/NHO/NHOD-SBC/output/R/Excel/template.xlsx")
# for (i in 2:ncol(resectionCAT)) {
#   tk2dde.poke("Excel", "T003", paste0("R5C", i, ":R9C", i), resectionCAT[, i])
# }
# for (i in 2:ncol(adjuvantCAT)) {
#   tk2dde.poke("Excel", "T004", paste0("R5C", i, ":R10C", i), adjuvantCAT[, i])
# }
# for (i in 2:ncol(chemCAT)) {
#   tk2dde.poke("Excel", "T005", paste0("R5C", i, ":R15C", i), chemCAT[, i])
# }
# for (i in 2:ncol(PLresectionYN)) {
#   tk2dde.poke("Excel", "T006", paste0("R5C", i, ":R7C", i), PLresectionYN[, i])
# }
# xl.workbook.save("//ARONAS/Stat/Trials/NHO/NHOD-SBC/output/R/Excel/template.xlsx")
# xl.workbook.close()
# system("taskkill /IM Excel.exe")
