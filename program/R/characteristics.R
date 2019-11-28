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

AGE <- ptdata %>%
  drop_na(group) %>%
  group_by(group) %>%
  summarise(n = n(),
            mean = mean(AGE),
            std = sd(AGE),
            median = median(AGE),
            max = max(AGE),
            min = min(AGE))
Z_AGE <- data.frame(t(AGE[-1]))
for (i in 1:4) {colnames(Z_AGE)[i] <- (AGE[i, 1])}


dsv <- function(x){
  AGE <- ptdata %>%
    drop_na(group) %>%
    group_by(group) %>%
    summarise(n = n(),
              mean = mean(x),
              std = sd(x),
              median = median(x),
              max = max(x),
              min = min(x))
  Z_x <- data.frame(t(x[-1]))
  for (i in 1:4) {colnames(z_x)[i] <- (x[i, 1])}
}
dsv(AGE)










install.packages("data.table")
