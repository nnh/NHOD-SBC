# read file
df <- read.csv("//172.16.0.222/Stat/Trials/NHO/NHOD-SBC/ptosh-format/ads/ptdata.csv", header = TRUE, na.strings = "")
View(df)
library(tidyverse)
library(gt)
library(gtsummary)
library(flextable)

# create dataframe
hyou1 <- df %>% select(SUBJID, resectionYN, adjuvantYN, adjuvantFL, chemoYN, chemFL, DSDECOD, DSTERM) %>%
  mutate(group1 = if_else(resectionYN =="あり", "治癒切除群",
                          if_else(resectionYN == "なし", "治癒未切除群", "NA")
  )
  ) %>% 
  mutate(group2 = if_else(resectionYN == "あり" &((adjuvantYN == "なし") | (adjuvantYN == "あり" & adjuvantFL == "はい")), "治癒切除・non-chemo",
                          if_else(resectionYN == "あり" & (adjuvantYN == "あり" & adjuvantFL == "いいえ"), "治癒切除・chemo",
                                  if_else(resectionYN == "なし" & (chemoYN == "なし") | (chemoYN == "あり" & chemFL == "いいえ"), "治癒未切除・non-chemo",
                                          if_else(resectionYN == "なし" & (chemoYN == "あり" & chemFL == "はい"), "治癒未切除・chemo", "NA")
                                  )
                          )
  )
  ) %>% select(-SUBJID, -resectionYN, -adjuvantYN, -adjuvantFL, -chemoYN, -chemFL, -group1) 

View(hyou1)

# create T001
 # output by pptx or docx
T001 <- hyou1 %>% 
  tbl_summary(by = group2, 
              missing = "no",  # non-indicated group2 = NA
              label = list(DSDECOD ~ "", DSTERM ~ "中止理由"),　# Edit the default label
              statistic = (c("DSDECOD","DSTERM") ~ "{n}")  # non-indicated % ( display results only for n.)
              ) %>% 
  modify_footnote(update = everything() ~ NA) %>%   # remove unnecessary footnotes
  modify_header(label = "") %>%   # non-indicated label( "charactalistic")
  as_flex_table() %>%  # output for office
  add_header_lines("症例の内訳と中止例集計") %>%   # give it a title
  print()
print(T001, preview = "docx")  # output for .docx
print(T001, preview = "pptx")　# output for .pptx

 # output by csv
T001 <- hyou1 %>% 
  tbl_summary(by = group2, 
              missing = "no", 
              label = list(DSDECOD ~ "", DSTERM ~ "中止理由"),　
              statistic = (c("DSDECOD","DSTERM") ~ "{n}")  
  ) %>% 
  modify_footnote(update = everything() ~ NA) %>%   
  modify_header(label = "") %>% 
  as_tibble() %>% add_header_lines("症例の内訳と中止例集計") %>% 
  write.csv("\\\\172.16.0.222/Stat/Trials/NHO/NHOD-SBC/program/second/NHOD_SBC_output/T001.csv", row.names = F) 