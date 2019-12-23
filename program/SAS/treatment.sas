**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-14
SAS version : 9.4
**************************************************************************;
* 5.4 treatment;
%SET_FREQ(ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_chemo_cnt), surgical_curability.csv);
%SET_FREQ(ds_adjuvant_chemo_regimen, 'アジュバント化学療法レジメン', adjuvantCAT, %str(ope_chemo_cnt), adjuvant_chemo_regimen.csv);
%SET_FREQ(ds_first_line_chemo_regimen, '第一選択化学療法レジメン', chemCAT, %str(non_ope_chemo_cnt), first_line_chemo_regimen.csv);
%let temp_str_keep=%str(ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt non_ope_non_chemo_cnt);
%SET_FREQ(ds_primary_site_resection, '原発巣切除の有無', PLresectionYN, &temp_str_keep., primary_site_resection.csv);
