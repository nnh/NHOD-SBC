##################################################
# Program : pfs.R
# Study : NHOD-SBC
# Author : Kato Kiroku
# Published : 2020/06/17
# Version : 001.20.06.17
##################################################

library(readxl)
library(tidyverse)
library(magrittr)
library(survival)
# library(survminer)
library(XLConnect)

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
ptdata$group1 <- with(ptdata,
                      ifelse(substr(group, 1, 4) == "治癒切除", "治癒切除",
                             ifelse(substr(group, 1, 5) == "治癒未切除", "治癒未切除", NA)))
ptdata$group2 <- with(ptdata,
                      ifelse(substr(group, 1, 4) == "治癒切除", group, NA))
ptdata$group3 <- with(ptdata,
                      ifelse(substr(group, 1, 5) == "治癒未切除", group, NA))
ptdata$event <- with(ptdata,
                     ifelse(RECURRYN == "あり" | SUDTHFL == "死亡", 1,
                            ifelse(RECURRYN == "なし" | SUDTHFL == "生存", 0, ""))) %>%
  as.numeric(ptdata$event)
ptdata$time <- with(ptdata,
                    ifelse(group %in% c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群"),
                           ifelse(RECURRYN == "あり", difftime(RECURRDTC, resectionDTC, units = c("days")),
                                  ifelse(SUDTHFL == "死亡", difftime(DTHDTC, resectionDTC, units = c("days")),
                                         ifelse(SUDTHFL == "生存", difftime(SURVDTC, resectionDTC, units = c("days")),
                                                ""))),
                           ifelse(group == "治癒未切除・Chemotherapy群",
                                  ifelse(RECURRYN == "あり", difftime(RECURRDTC, chemSTDTC, units = c("days")),
                                         ifelse(SUDTHFL == "死亡", difftime(DTHDTC, chemSTDTC, units = c("days")),
                                                ifelse(SUDTHFL == "生存", difftime(SURVDTC, chemSTDTC, units = c("days")),
                                                       ""))),
                                  ifelse(group == "治癒未切除・non-Chemotherapy群",
                                         ifelse(RECURRYN == "あり", difftime(RECURRDTC, DIGDTC, units = c("days")),
                                                ifelse(SUDTHFL == "死亡", difftime(DTHDTC, DIGDTC, units = c("days")),
                                                       ifelse(SUDTHFL == "生存", difftime(SURVDTC, DIGDTC, units = c("days")),
                                                              ""))),
                                         "")))) %>%
  as.numeric(ptdata$time)

KM1 <- survfit(Surv(time, event) ~ group1, data = ptdata)
SurvList1 <- summary(KM1, censored = T)
SurvDF1 <- with(SurvList1, data.frame(strata, time, surv))
SurvDF1 <- SurvDF1[rep(seq_len(nrow(SurvDF1)), each = 2), ]

KM2 <- survfit(Surv(time, event) ~ group2, data = ptdata)
SurvList2 <- summary(KM2, censored = T)
SurvDF2 <- with(SurvList2, data.frame(strata, time, surv))
SurvDF2 <- SurvDF2[rep(seq_len(nrow(SurvDF2)), each = 2), ]

KM3 <- survfit(Surv(time, event) ~ group3, data = ptdata)
SurvList3 <- summary(KM3, censored = T)
SurvDF3 <- with(SurvList3, data.frame(strata, time, surv))
SurvDF3 <- SurvDF3[rep(seq_len(nrow(SurvDF3)), each = 2), ]

SurvivalAnalysis <- function(x, y, z, g){
  TempDF <- y %>%
    mutate(group = sub(g, "", strata)) %>%
    subset(group == z) %>%
    mutate(survival = (lag(surv, default = 1.0)) * 100) %>%
    select(group, time, survival)
  SurvFrame <- data.frame(group = z, time = 0, survival = 100)
  TempDF <- rbind(SurvFrame, TempDF)
  assign(x, TempDF, .GlobalEnv)
}
SurvivalAnalysis("F004a", SurvDF1, "治癒切除", "group1=")
SurvivalAnalysis("F004b", SurvDF1, "治癒未切除", "group1=")
SurvivalAnalysis("F005a", SurvDF2, "治癒切除・non-Chemotherapy群", "group2=")
SurvivalAnalysis("F005b", SurvDF2, "治癒切除・Chemotherapy群", "group2=")
# SurvivalAnalysis("F006a", SurvDF3, "治癒未切除・non-Chemotherapy群", "group3=")
SurvivalAnalysis("F006b", SurvDF3, "治癒未切除・Chemotherapy群", "group3=")

PvalueList1 <- survdiff(Surv(time, event) ~ group1, data = ptdata)
PvalueDF1 <- pchisq(PvalueList1$chisq, df = 1, lower.tail = FALSE) %>%
  as.data.frame
PvalueList2 <- survdiff(Surv(time, event) ~ group2, data = ptdata)
PvalueDF2 <- pchisq(PvalueList2$chisq, df = 1, lower.tail = FALSE) %>%
  as.data.frame
# PvalueList3 <- survdiff(Surv(time, event) ~ group3, data = ptdata)
# PvalueDF3 <- pchisq(PvalueList3$chisq, df = 1, lower.tail = FALSE) %>%
#   as.data.frame

writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(F004a, F004b, F005a, F005b, F006b, PvalueDF1, PvalueDF2),
                     sheet = c("F004", "F004", "F005", "F005", "F006", "F004", "F005"),
                     startRow = c(11, 11, 11, 11, 11, 7, 7),
                     startCol = c(8, 11, 8, 11, 8, 2, 2),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")

SurvivalRate <- function(x, y, z, g){
  list1 <- summary(x, times = c(365*(1:3)), extend = TRUE)
  df1 <- with(list1, data.frame(strata, time, surv, lower, upper))
  df1$surv_rate <- paste0(format(round((df1$surv)*100, digits = 1), nsmall = 1),
                          " (",
                          format(round((df1$lower)*100, digits = 1), nsmall = 1),
                          " - ",
                          format(round((df1$upper)*100, digits = 1), nsmall = 1),
                          ")")
  df2 <- df1 %>%
    mutate(group = sub(g, "", strata)) %>%
    subset(group == z) %>%
    select(surv_rate)
  assign(y, df2, .GlobalEnv)
}
SurvivalRate(KM1, "T011a", "治癒切除", "group1=")
SurvivalRate(KM1, "T011b", "治癒未切除", "group1=")
SurvivalRate(KM2, "T012a", "治癒切除・non-Chemotherapy群", "group2=")
SurvivalRate(KM2, "T012b", "治癒切除・Chemotherapy群", "group2=")
# SurvivalRate(KM3, "T009a", "治癒未切除・non-Chemotherapy群", "group3=")
SurvivalRate(KM3, "T013b", "治癒未切除・Chemotherapy群", "group3=")

dfCount <- ptdata %>%
  select("SUDTHFL", "group") %>%
  mutate(SUDTHFL = na_if(SUDTHFL, "生存")) %>%
  table %>%
  as.data.frame.matrix
dfCount2 <- subset(dfCount, rownames(dfCount) == "死亡")
dfCountPFS <- ptdata %>%
  select("RECURRYN", "group") %>%
  mutate(RECURRYN = na_if(RECURRYN, "なし")) %>%
  table %>%
  as.data.frame.matrix
dfCountPFS2 <- subset(dfCountPFS, rownames(dfCountPFS) == "あり")
rownames(dfCountPFS2)[1] <- "増悪・再発"
T014 <- rbind(dfCount2, dfCountPFS2)
T014 <- T014[c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・Chemotherapy群")]

NumberOfGroup <- function(g, DFName){
  dfCountN <- ptdata %>%
    mutate(count = "例数") %>%
    drop_na(event) %>%
    select("count", all_of(g)) %>%
    table %>%
    as.data.frame.matrix
  for (i in 1:ncol(dfCountN)) {dfCountN["例数", i] <- paste0("(n=", dfCountN["例数", i], ")")}
  assign(DFName, dfCountN, .GlobalEnv)
}
NumberOfGroup("group1", "T011Num")
NumberOfGroup("group2", "T012Num")
NumberOfGroup("group3", "T013Num")
NumberOfGroup("group", "T014Num")
T011Num <- T011Num[, c("治癒切除", "治癒未切除")]
T012Num <- T012Num[, c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群")]
T013Num <- T013Num[c("治癒未切除・Chemotherapy群")]
T014Num <- T014Num[c("治癒切除・non-Chemotherapy群", "治癒切除・Chemotherapy群", "治癒未切除・Chemotherapy群")]

writeWorksheetToFile(file = paste0(outpath, "/R_output.xlsx"),
                     data = list(T011a, T011b, T012a, T012b, T013b, T014, T011Num, T012Num, T013Num, T014Num),
                     sheet = c("T011", "T011", "T012", "T012", "T013", "T014", "T011", "T012", "T013", "T014"),
                     startRow = c(6, 6, 6, 6, 6, 6, 5, 5, 5, 5),
                     startCol = c(2, 3, 2, 3, 2, 2, 2, 2, 2, 2),
                     header = FALSE,
                     styleAction = XLC$"STYLE_ACTION.NONE")


# KM1 <- survfit(Surv(time, event) ~ group1, data = ptdata)
# cairo_pdf(paste0(outpath, "/S_5_5_2_pfs_1.pdf"), family="DejaVu Sans")
# ggsurvplot(KM1, conf.int = TRUE, pval = TRUE)
# dev.off()
# KM2 <- survfit(Surv(time, event) ~ group2, data = ptdata)
# cairo_pdf(paste0(outpath, "/S_5_5_2_pfs_2.pdf"), family="DejaVu Sans")
# ggsurvplot(KM2, conf.int = TRUE, pval = TRUE)
# dev.off()
# KM3 <- survfit(Surv(time, event) ~ group3, data = ptdata)
# cairo_pdf(paste0(outpath, "/S_5_5_2_pfs_3.pdf"), family="DejaVu Sans")
# ggsurvplot(KM3, conf.int = TRUE, pval = TRUE)
# dev.off()
