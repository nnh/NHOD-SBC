##################################################
# Program : reduction_rate.R
# Study : NHOD-SBC
# Published : 2019/12/26
# Author : Kato Kiroku
# Version : 19.12.26.000
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
  ptdata[[x]][ptdata[[x]] == -1] <- NA
  df1 <- ptdata %>%
    subset(group == "治癒未切除・Chemotherapy群") %>%
    drop_na(x) %>%
    summarise(n = n(),
              mean = round(mean(eval(as.symbol(x))), digits = 1),
              std = round(sd(eval(as.symbol(x))), digits = 1),
              median = round(median(eval(as.symbol(x))), digits = 1),
              max = round(max(eval(as.symbol(x))), digits = 1),
              min = round(min(eval(as.symbol(x))), digits = 1))
  df2 <- data.frame(t(df1))
  for (i in 1:ncol(df2)) {colnames(df2)[i] <- y}
  assign(x, df2, .GlobalEnv)
}
dsv("SBCsum", "ベースライン")
dsv("Lesion3m", "3ヵ月")
dsv("Lesion6m", "6ヵ月")

reduction_rate <- cbind(SBCsum, Lesion3m, Lesion6m)
write.csv(reduction_rate, paste0(outpath, "/reduction_rate.csv"), row.names = TRUE, na = "")
