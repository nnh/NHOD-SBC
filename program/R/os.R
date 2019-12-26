##################################################
# Program : os.R
# Study : NHOD-SBC
# Published : 2019/12/24
# Author : Kato Kiroku
# Version : 19.12.24.000
##################################################

library(openxlsx)
library(tidyverse)
library(magrittr)
library(survival)
library(survminer)

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
ptdata$group1 <- with(ptdata,
                      ifelse(substr(group, 1, 4) == "治癒切除", "治癒切除",
                             ifelse(substr(group, 1, 5) == "治癒未切除", "治癒未切除", NA)))
ptdata$group2 <- with(ptdata,
                      ifelse(substr(group, 1, 4) == "治癒切除", group, NA))
ptdata$group3 <- with(ptdata,
                      ifelse(substr(group, 1, 5) == "治癒未切除", group, NA))
ptdata$event <- with(ptdata,
                     ifelse(SUDTHFL == "死亡", 1,
                            ifelse(SUDTHFL == "生存", 0, ""))) %>%
  as.numeric(ptdata$event)
ptdata$time <- with(ptdata,
                    ifelse(SUDTHFL == "死亡", difftime(DTHDTC, DIGDTC, units = c("days")),
                           ifelse(SUDTHFL == "生存", difftime(SURVDTC, DIGDTC, units = c("days")), ""))) %>%
  as.numeric(ptdata$time)

KM1 <- survfit(Surv(time, event) ~ group1, data = ptdata)
cairo_pdf(paste0(outpath, "/OS_KM1.pdf"), family="DejaVu Sans")
ggsurvplot(KM1, conf.int = TRUE, pval = TRUE)
dev.off()
KM2 <- survfit(Surv(time, event) ~ group2, data = ptdata)
cairo_pdf(paste0(outpath, "/OS_KM2.pdf"), family="DejaVu Sans")
ggsurvplot(KM2, conf.int = TRUE, pval = TRUE)
dev.off()
KM3 <- survfit(Surv(time, event) ~ group3, data = ptdata)
cairo_pdf(paste0(outpath, "/OS_KM3.pdf"), family="DejaVu Sans")
ggsurvplot(KM3, conf.int = TRUE, pval = TRUE)
dev.off()

describe <- function(x, y){
  list1 <- summary(x, times = c(365*(1:3)))
  df1 <- with(list1, data.frame(strata, time, surv, lower, upper))
  df1$surv_rate <- paste0(round(df1$surv, digits = 1), "(", round(df1$lower, digits = 1), " - ", round(df1$upper, digits = 1), ")")
  df2 <- df1 %>% subset(select = c(strata, time, surv_rate))
  assign(y, df2, .GlobalEnv)
  write.csv(df2, paste0(outpath, "/", y, ".csv"), row.names = FALSE, na = "")
}
describe(KM1, "OS_KM1_survival")
describe(KM2, "OS_KM2_survival")
describe(KM3, "OS_KM3_survival")

dfCount <- ptdata %>%
  select("SUDTHFL", "group") %>%
  mutate(SUDTHFL = na_if(SUDTHFL, "生存")) %>%
  table %>%
  as.data.frame.matrix
dfCount2 <- subset(dfCount, rownames(dfCount) == "死亡")
write.csv(dfCount2, paste0(outpath, "/OS_event.csv"), row.names = TRUE, na = "")
