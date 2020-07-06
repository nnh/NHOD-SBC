##################################################
# Program : characteristics.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/06/17
# Version : 001.20.06.17
##################################################

library(readxl)
library(tidyverse)
library(magrittr)
# library(openxlsx)
# library(xlsx)

getwd()
prtpath <- "//ARONAS/Stat/Trials/NHO/NHOD-SBC"

adspath <- paste0(prtpath, "/ptosh-format/ads")
docpath <- paste0(prtpath, "/document")
rawpath <- paste0(prtpath, "/input/rawdata")
outpath <- paste0(prtpath, "/output/R")

ptdata <- read.csv(paste0(adspath, "/ptdata.csv"), na.strings = "")
sexDF <- read.csv(paste0(rawpath, "/SBC_registration_200203_1042.csv"), na.strings = "")
sexDF <- sexDF %>%
  select("症例登録番号", "性別") %>%
  rename(SUBJID = 症例登録番号, sex = 性別)
allocation <- read_excel(paste0(docpath, "/解析対象集団一覧.xlsx"), na = "")
allocation <- allocation %>%
  rename(SUBJID = 症例登録番号, group = 解析対象集団)
ptdata <- merge(ptdata, sexDF, by = "SUBJID", all = T)
ptdata <- merge(ptdata, allocation, by = "SUBJID", all = T)

TotalNumDF1 <- ptdata %>%
  drop_na(group) %>%
  count() %>%
  as.data.frame()
colnames(TotalNumDF1) <- "全体"
GroupNumDF1 <- ptdata %>%
  drop_na(group) %>%
  count(group) %>%
  as.data.frame()
GroupNumDF2 <- data.frame(t(GroupNumDF1[-1]))
for (i in 1:ncol(GroupNumDF2)) {colnames(GroupNumDF2)[i] <- GroupNumDF1[i, "group"]}
GroupNumDF3 <- cbind(TotalNumDF1, GroupNumDF2)
for (i in 1:ncol(GroupNumDF3)) {GroupNumDF3["n", i] <- paste0("(n=", GroupNumDF3["n", i], ")")}
GroupNumDF3 <- GroupNumDF3[c("全体", "治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]

dsv <- function(x, y){
  # Total
  dfTotal1 <- ptdata %>%
    drop_na(group) %>%
    select(all_of(x)) %>%
    mutate_all(~na_if(., -1)) %>%
    drop_na(all_of(x)) %>%
    group_by(例数 = n(), add = TRUE) %>%
    summarise_all(list(平均 = mean, 標準偏差 = sd, 中央値 = median, 最小値 = min, 最大値 = max), na.rm = TRUE) %>%
    mutate_at(c("平均", "標準偏差"), round, 1)
  dfTotal2 <- data.frame(t(dfTotal1))
  colnames(dfTotal2) <- "全体"
  # Group
  df1 <- ptdata %>%
    select(all_of(x), "group") %>%
    mutate_all(~na_if(., -1)) %>%
    drop_na(group) %>%
    drop_na(all_of(x)) %>%
    group_by(group) %>%
    group_by(例数 = n(), add = TRUE) %>%
    summarise_all(list(平均 = mean, 標準偏差 = sd, 中央値 = median, 最小値 = min, 最大値 = max), na.rm = TRUE) %>%
    mutate_at(c("平均", "標準偏差"), round, 1)
  df2 <- data.frame(t(df1[-1]))
  for (i in 1:ncol(df2)) {colnames(df2)[i] <- (df1[i, 1])}
  df2 <- df2[c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]
  # Summary
  df3 <- data.frame(characteristics = "", characteristics_d = "", category = rownames(df2), dfTotal2, df2, stringsAsFactors = FALSE)
  df3[1, 1] <- y
  assign(x, df3, .GlobalEnv)
}
dsv("AGE", "登録時年齢 (歳)")
dsv("LDH", "血清LDH値 (IU/l)")
dsv("CEA", "血清CEA値 (ng/mL)")
dsv("CA199", "血清CA19-9値 (U/mL)")

frequency <- function(x, y, z){
  dfCategory <- data.frame(category = matrix(unlist(strsplit(z, ","))))
  dfCountN <- ptdata %>%
    mutate(count = "例数") %>%
    drop_na(all_of(x)) %>%
    select("count", "group") %>%
    table %>%
    as.data.frame.matrix
  dfCountN$全体 <- rowSums(dfCountN)
  # Count
  dfCount <- ptdata %>%
    drop_na(all_of(x)) %>%
    select(all_of(x), "group") %>%
    table %>%
    as.data.frame.matrix
  dfCount$全体 <- rowSums(dfCount)
  # Percent
  dfPercent <- format(round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1), nsmall = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", str_trim(format(unlist(dfPercent))), "%)")
  # Concatenation of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  dfCount2 <- rbind(dfCountN, dfCount)
  dfCount2 <- dfCount2[c("全体", "治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]
  df1 <- data.frame(category = rownames(dfCount2), dfCount2, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T) %>%
    mutate(category = factor(category, levels = c("例数", unlist(strsplit(z, ","))))) %>%
    arrange(category)
  df2[is.na(df2)] <- "0 (0.0%)"
  df3 <- data.frame(characteristics = "", characteristics_d = "", df2, stringsAsFactors = FALSE)
  df3[1, 1] <- y
  assign(x, df3, .GlobalEnv)
}
frequency("sex", "性別", "男性,女性")
frequency("CrohnYN", "Crohn's disease", "あり,なし,不明")
frequency("HNPCCYN", "HNPCC", "あり,なし,不明")
frequency("TNMCAT", "TNM stage", "I,II,III,IV")
frequency("PS", "Performance Status", "0,1,2,3,4")
frequency("SBCSITE", "部位", "十二指腸,空腸,回腸")
frequency("SBCdegree", "病理組織の分化度", "高分化,中分化,低分化,未分化,不明")
frequency("RASYN", "RAS変異の有無", "あり,なし,不明")
frequency("metaYN", "転移臓器", "あり,なし,不明")

frequency_true <- function(x,y){
  dfCategory <- data.frame(category = c("TRUE", "FALSE"))
  dfCount <- ptdata %>%
    drop_na(all_of(x)) %>%
    select(all_of(x), "group") %>%
    table %>%
    as.data.frame.matrix
  dfCount$全体 <- rowSums(dfCount)
  dfCount <- dfCount[c("全体", "治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T)
  df2[is.na(df2)] <- 0
  df2 <- subset(df2, category == "TRUE")
  df3 <- data.frame(characteristics = "", characteristics_d = "", df2, stringsAsFactors = FALSE)
  df3["category"] <- paste0("  ", y)
  assign(x, df3, .GlobalEnv)
}
frequency_true("metaSITE_1", "肝臓")
frequency_true("metaSITE_2", "肺")
frequency_true("metaSITE_3", "腹膜播種")
frequency_true("metaSITE_4", "腹腔内リンパ節")
frequency_true("metaSITE_5", "その他")
metasite <- rbind(metaSITE_1, metaSITE_2, metaSITE_3, metaSITE_4, metaSITE_5)
metasite[1, 2] <- "部位 (ありの場合)"
metaYN <- rbind(metaYN, metasite)

# T001
CancelFrame <- data.frame()[1:2, 0]
rownames(CancelFrame)[1] <- "完了"
rownames(CancelFrame)[2] <- "中止"
cancel <- ptdata %>%
  select("DSDECOD", "group") %>%
  table %>%
  as.data.frame.matrix
cancel <- merge(cancel, CancelFrame, by="row.names", all=TRUE)
cancel[is.na(cancel)] <- 0
cancel <- cancel[, c("Row.names", "治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・non-Chemotherapy群", "治癒未切除・Chemotherapy群")]
cancel$Row.names <- paste0(cancel$Row.names, "例")
# write.csv(cancel, paste0(outpath, "/S_5_2_cancel.csv"), row.names = FALSE, na = "")

# T002
characteristics <- rbind(AGE, sex, CrohnYN, HNPCCYN, TNMCAT, PS, SBCSITE, SBCdegree, RASYN, metaYN, LDH, CEA, CA199)
characteristics <- characteristics[, 4:8]
# write.csv(characteristics, paste0(outpath, "/S_5_3_demog.csv"), row.names = FALSE, na = "")

# L001
MultiplePrimaryCancers <- ptdata %>%
  select("SUBJID", "MHCOM") %>%
  drop_na(MHCOM)
# write.csv(MultiplePrimaryCancers, paste0(outpath, "/S_5_3_multiple_primary_cancers.csv"), row.names = FALSE, na = "")

library(XLConnect)

Excelwb <- loadWorkbook(paste0(outpath, "/R_output.xlsx"))
clearRange(Excelwb,
           sheet = c("T001", "L001"),
           coords = c(c(5, 1, 100, 10), c(5, 1, 100, 10)))
Style1 <- createCellStyle(Excelwb)
setBorder(Style1, side = "bottom", type = XLC$"BORDER.THIN", color = XLC$"COLOR.BLACK")
setCellStyle(Excelwb,
             sheet = "T001",
             row = 6,
             col = 1:5,
             cellstyle = Style1)
setCellStyle(Excelwb,
             sheet = "L001",
             row = 27,
             col = 1:2,
             cellstyle = Style1)
saveWorkbook(Excelwb)

writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(cancel, GroupNumDF3, characteristics, MultiplePrimaryCancers),
                     sheet = c("T001", "T002", "T002", "L001"),
                     startRow = c(5, 5, 7, 5),
                     startCol = c(1, 4, 4, 1),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# # Excel
# library(excel.link)
# library(tcltk2)
# tk2dde("R")
# xl.workbook.open("//ARONAS/Stat/Trials/NHO/NHOD-SBC/output/R/R_output.xlsx")
# for (i in 2:ncol(cancel)) {
#   tk2dde.poke("Excel", "T001", paste0("R5C", i, ":R10C", i), cancel[, i])
# }
# for (i in 4:ncol(characteristics)) {
#   tk2dde.poke("Excel", "T002", paste0("R7C", i, ":R75C", i), characteristics[, i])
# }
# for (i in 1:ncol(MultiplePrimaryCancers)) {
#   tk2dde.poke("Excel", "L001", paste0("R5C", i, ":R23C", i), MultiplePrimaryCancers[, i])
# }
# xl.workbook.save("//ARONAS/Stat/Trials/NHO/NHOD-SBC/output/R/Excel/template.xlsx")
# xl.workbook.close()
# system("taskkill /IM Excel.exe")

