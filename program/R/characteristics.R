##################################################
# Program : characteristics.R
# Study : NHOD-SBC
# Published : 2019/12/09
# Author : Kato Kiroku
# Version : 19.12.09.000
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

dsv <- function(x, y){
  df1 <- ptdata %>%
    drop_na(group) %>%
    group_by(group) %>%
    summarise(n = n(),
              mean = round(mean(eval(as.symbol(x))), digits = 1),
              std = round(sd(eval(as.symbol(x))), digits = 1),
              median = round(median(eval(as.symbol(x))), digits = 1),
              max = round(max(eval(as.symbol(x))), digits = 1),
              min = round(min(eval(as.symbol(x))), digits = 1))
  df2 <- data.frame(t(df1[-1]))
  for (i in 1:ncol(df2)) {colnames(df2)[i] <- (df1[i, 1])}
  df3 <- data.frame(characteristics = "", category = rownames(df2), df2, stringsAsFactors = FALSE)
  df3[1, 1] <- y
  assign(x, df3, .GlobalEnv)
}
dsv("AGE", "登録時年齢 (歳)")
dsv("LDH", "血清LDH値 (IU/l)")
dsv("CEA", "血清CEA値 (ng/mL)")
dsv("CA199", "血清CA19-9値 (U/mL)")
# https://stackoverflow.com/questions/9057006/getting-strings-recognized-as-variable-names-in-r/9057793
# https://stackoverflow.com/questions/3969852/update-data-frame-via-function-doesnt-work
# substitute(x)とは... xを環境内の値に置き換える。substitute is designed to not take values from the global environment.
# as.symbol(x)とは... as.names(x)

frequency <- function(x, y, z){
  dfCategory <- data.frame(category = matrix(unlist(strsplit(z, ","))))
  # COUNT
  dfCount <- ptdata %>%
    select(x, "group") %>%
    table %>%
    as.data.frame.matrix
  # PERCENT
  dfPercent <- round(prop.table(as.matrix(dfCount), margin = 2)*100, digits = 1) %>%
    as.data.frame.array
  dfPercent[] <- paste0("(", format(unlist(dfPercent)),"%)")
  # CONCATENATION of dfCount and dfPercent
  for (i in 1:ncol(dfCount)) {dfCount[[i]] <- paste(dfCount[[i]], dfPercent[[i]])}
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T)
  df2[is.na(df2)] <- "0 (  0.0%)"
  df3 <- data.frame(characteristics = "", df2, stringsAsFactors = FALSE)
  df3[1, 1] <- y
  assign(x, df3, .GlobalEnv)
}
frequency("CrohnYN", "Crohn's disease", "あり,なし,不明")
frequency("HNPCCYN", "HNPCC", "あり,なし,不明")
frequency("TNMCAT", "TNM stage", "I,II,III,IV")
frequency("PS", "Performance Status", "0,1,2,3,4")
frequency("SBCSITE", "部位", "十二指腸,空腸,回腸")
frequency("SBCdegree", "病理組織の分化度", "高分化,中分化,低分化,未分化,不明")
frequency("RASYN", "RAS変異の有無", "あり,なし,不明")
frequency("metaYN", "転移臓器", "あり,なし,不明")
# https://www.r-bloggers.com/converting-r-contingency-tables-to-data-frames/

frequency_true <- function(x,y){
  dfCategory <- data.frame(category = c("TRUE", "FALSE"))
  dfCount <- ptdata %>%
    select(x, "group") %>%
    table %>%
    as.data.frame.matrix
  df1 <- data.frame(category = rownames(dfCount), dfCount, stringsAsFactors = FALSE)
  df2 <- merge(df1, dfCategory, by = "category", all = T)
  df2[is.na(df2)] <- 0
  df2 <- subset(df2, category == "TRUE")
  df3 <- data.frame(characteristics = "", df2, stringsAsFactors = FALSE)
  df3["category"] <- paste0("  ", y)
  assign(x, df3, .GlobalEnv)
}
frequency_true("metaSITE_1", "肝臓")
frequency_true("metaSITE_2", "肺")
frequency_true("metaSITE_3", "腹膜播種")
frequency_true("metaSITE_4", "腹腔内リンパ節")
frequency_true("metaSITE_5", "その他")
metasite <- rbind(metaSITE_1, metaSITE_2, metaSITE_3, metaSITE_4, metaSITE_5)
metaYN <- rbind(metaYN[1:1,], metasite, metaYN[-(1:1),])

characteristics <- rbind(AGE, CrohnYN, HNPCCYN, TNMCAT, PS, SBCSITE, SBCdegree, RASYN, metaYN, LDH, CEA, CA199)
write.csv(characteristics, paste0(outpath, "/characteristics.csv"), row.names = FALSE, na = "")


MultiplePrimaryCancers <- ptdata %>%
  select("SUBJID", "MHCOM") %>%
  drop_na(MHCOM)
write.csv(MultiplePrimaryCancers, paste0(outpath, "/multiple_primary_cancers.csv"), row.names = FALSE, na = "")
