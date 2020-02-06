**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-29
SAS version : 9.4
**************************************************************************;
* 5.2. Breakdown of cases and count of discontinued cases;
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='症例の内訳と中止例集計');
%FORMAT_FREQ(var=DSDECOD, item_list=%quote('完了', '中止'), title='症例の内訳と中止例集計', output_ds=cancel, input_ds=ptdata_all, output_n_flg=0);
%let withdrawal_item_list=%quote('研究対象者が死亡した場合', '転居などにより研究対象者が追跡不能となった場合','研究対象者による同意撤回の申し出があった場合', 
                                 '登録後不適格症例であることが判明した場合', '重大な研究計画書違反が判明した場合', '当該実施医療機関における試験が中止された場合', 
                                 '試験全体が中止された場合', 'その他の理由で研究責任者、研究分担者により試験中止が適切と判断された場合');
%CREATE_OUTPUT_DS(output_ds=reasons_for_withdrawal, items_label='症例の内訳と中止例集計');
%FORMAT_FREQ(var=DSTERM, item_list=&withdrawal_item_list., title='中止理由', output_ds=reasons_for_withdrawal, input_ds=ptdata_all, output_n_flg=0);
