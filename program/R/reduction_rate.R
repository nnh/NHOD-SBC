##################################################
# Program : reduction_rate.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/06/17
# Version : 001.20.06.17
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

dsv <- function(x, y){
  ptdata[[x]][ptdata[[x]] == -1] <- NA
  df1 <- ptdata %>%
    subset(group == "治癒未切除・Chemotherapy群") %>%
    drop_na(all_of(x)) %>%
    summarise(n = n(),
              平均 = round(mean(eval(as.symbol(x))), digits = 1),
              標準偏差 = round(sd(eval(as.symbol(x))), digits = 1),
              最大 = max(eval(as.symbol(x))),
              最小 = min(eval(as.symbol(x))),
              中央値 = median(eval(as.symbol(x))))
  df2 <- data.frame(t(df1))
  for (i in 1:ncol(df2)) {colnames(df2)[i] <- y}
  assign(x, df2, .GlobalEnv)
}
dsv("SBCsum", "ベースライン")
dsv("Lesion3m", "3ヵ月")
dsv("Lesion6m", "6ヵ月")

reduction_rate <- cbind(SBCsum, Lesion3m, Lesion6m) %>%
  mutate(category = row.names(SBCsum)) %>%
  select(category, everything())

library(XLConnect)
writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(reduction_rate),
                     sheet = c("T018"),
                     startRow = c(5),
                     startCol = c(1),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# write.csv(reduction_rate, paste0(outpath, "/S_5_5_4_ds_tumor_reduction.csv"), row.names = TRUE, na = "")
