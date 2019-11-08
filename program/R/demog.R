########################################
# Program Name : demog.R
# Study Name : NHOD-SBC
# Author : Kato Kiroku
# Date : 2019/08/08
# Output : .html
########################################

library(magrittr)
library(frequency)
library(dplyr)
library(summarytools)
library(openxlsx)
library(survival)
install.packages("anytime")
library(anytime)

getwd()
prtpath <- "//ARONAS/Stat/Trials/NHO/NHOD-SBC"

adspath <- paste0(prtpath, "/ptosh-format/ads")
docpath <- paste0(prtpath, "/document")
rawpath <- paste0(prtpath, "/input/rawdata")
# extpath <- paste0(prtpath, "/input/ext")
# outpath <- paste0(prtpath, "/output/QC")
outpath <- "C:/Users/KirokuKato/Desktop/R"

ptdata <- read.csv(paste0(adspath, "/ptdata.csv"))
group <- read.xlsx(paste0(docpath, "/解析対象集団一覧.xlsx"), na.strings = "")
group <- rename(group, SUBJID = 症例登録番号)
ptdata <- merge(ptdata, group, by = "SUBJID", all = T)

ptdata$DIGDTC <- anydate(ptdata$DIGDTC)
ptdata$DTHDTC <- anydate(ptdata$DTHDTC)
ptdata$SURVDTC <- anydate(ptdata$SURVDTC)

ptdata$event <- ifelse(ptdata$SUDTHFL == "死亡", 1,
                        ifelse(ptdata$SUDTHFL == "生存", 0, ""))
ptdata$time <- ifelse(ptdata$SUDTHFL == "死亡", as.numeric(difftime(ptdata$DTHDTC, ptdata$DIGDTC, units = c("days"))),
                      ifelse(ptdata$SUDTHFL == "生存", as.numeric(difftime(ptdata$SURVDTC, ptdata$DIGDTC, units = c("days"))), ""))



ptdata$time <- as.numeric(ptdata$time)
class(ptdata$time)
ptdata$event <- as.numeric(ptdata$event)
class(ptdata$censor)

with(data = ptdata, Surv(time, event))[1:10]

survfit(Surv(time, event)~1, data=ptdata)
km <- survfit(Surv(time, event)~1, data=ptdata)
plot(km, las=1, xlab="Survival Time (days)", ylab="Overall Survival")
survfit(Surv(time, event)~解析対象集団, data=ptdata)
km_1
# AGE
# ptdata %>% summary(AGE)
summary(ptdata$AGE)
descr(ptdata$AGE, stats = "common", style = "rmarkdown")

# SEX
registration <- read.csv(paste0(rawpath, "/SBC_registration_190524_0949.csv"), na.strings = "")

# CrohnYN
# ptdata %>% freq(CrohnYN)
freq_cr <- freq(ptdata$CrohnYN)
ptdata$CrohnYN %>% freq()

# HNPCCYN
freq(ptdata$HNPCCYN, plain.ascii = FALSE, totals = FALSE, cumul = FALSE,
     headings = FALSE, style = "rmarkdown")

# function
func_freqency <- function(x){
  freq(ptdata[, x])
}
func_freqency("CrohnYN")
func_freqency("HNPCCYN")

# test
view(ptdata$AGE, file = paste0(getwd(), "/test.html"))
view(dfSummary(ptdata))
