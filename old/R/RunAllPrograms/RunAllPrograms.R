##################################################
# Program : RunAllPrograms.R
# Author : Kato Kiroku
# Published : 2020/05/13
# Version : 001.20.05.13
##################################################

CurDir <- dirname(rstudioapi::getSourceEditorContext()$path)
PrgPath <- gsub("RunAllPrograms", "", CurDir)

PrgList <- list.files(PrgPath, pattern = ".R")

for (i in 1:length(PrgList)) {
  print(noquote(paste0(i, "/", length(PrgList), " : ", "Now Running ", '"', PrgList[i], '"')))
  source(paste0(PrgPath, PrgList[i]), encoding = 'UTF-8', echo = FALSE)
}
