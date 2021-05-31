# ファイル読み込み
df <- read.csv("//172.16.0.222/Stat/Trials/NHO/NHOD-SBC/ptosh-format/ads/ptdata.csv", header = TRUE, na.strings = "")
View(df)
library(tidyverse)
library(gt)
library(gtsummary)
library(flextable)

# 解析対象を表示する列を作る
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

# doxc, pptxで出力
T001 <- hyou1 %>% 
  tbl_summary(by = group2, 
              missing = "no",  # group2がNAを表示しない
              label = list(DSDECOD ~ "", DSTERM ~ "中止理由"),　# デフォルトのラベルの編集
              statistic = (c("DSDECOD","DSTERM") ~ "{n}")  # 完了・中止の結果をnのみに（デフォルトはn(%)の表示
              ) %>% 
  modify_footnote(update = everything() ~ NA) %>%   # 不要な脚注を削除
  modify_header(label = "") %>%   # デフォルトの"charactalisticラベルを非表示に
  as_flex_table() %>%  # office形式
  add_header_lines("症例の内訳と中止例集計") %>%   # タイトル付け
  print()
print(T001, preview = "docx")  # wordで出力
print(T001, preview = "pptx")　# powerpointで出力

# csvで出力
T001 <- hyou1 %>% 
  tbl_summary(by = group2, 
              missing = "no",  # group2がNAを表示しない
              label = list(DSDECOD ~ "", DSTERM ~ "中止理由"),　# デフォルトのラベルの編集
              statistic = (c("DSDECOD","DSTERM") ~ "{n}")  # 完了・中止の結果をnのみに（デフォルトはn(%)の表示
  ) %>% 
  modify_footnote(update = everything() ~ NA) %>%   # 不要な脚注を削除
  modify_header(label = "") %>%   # デフォルトの"charactalisticラベルを非表示に
  as_tibble() %>% add_header_lines("症例の内訳と中止例集計") %>% 
  write.csv("\\\\172.16.0.222/Stat/Trials/NHO/NHOD-SBC/program/second/NHOD_SBC_output/T001.csv", row.names = F) # office形式





#別案？（tableoneパッケージを使ってcsvへ吐き出す？）---------------------------------------------------------------------------------------------------------------------

library(tableone)

hyou3 <- df %>% select(SUBJID, resectionYN, adjuvantYN, adjuvantFL, chemoYN, chemFL, DSDECOD, DSTERM) %>%
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
  )

View(hyou3)

hyou4 <- hyou3 %>% CreateTableOne(strata = "group2",
                                  vars = c("DSDECOD", "DSTERM")
                                  ) %>% 
  print() %>% 
  write.csv("\\\\172.16.0.222/Stat/Trials/NHO/NHOD-SBC/program/second/NHOD_SBC_output/T001.csv")


getwd()
?CreateTableOne
