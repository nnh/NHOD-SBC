**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-06
SAS version : 9.4
**************************************************************************;
* 5.4 treatment;
%EDIT_TREATMENT(ds_surgical_curability, resectionCAT, %quote('RX', 'R0', 'R1', 'R2'), 
                  %quote(ope_non_chemo_cnt ope_chemo_cnt));
%EDIT_TREATMENT(ds_adjuvant_chemo_regimen, adjuvantCAT, %quote(&regimens_adjuvant.), %quote(ope_chemo_cnt));
%EDIT_TREATMENT(ds_first_line_chemo_regimen, chemCAT, %quote(&regimens_first_line.), %quote(non_ope_chemo_cnt));
%EDIT_TREATMENT(ds_primary_site_resection, PLresectionYN, %quote('‚ ‚è', '‚È‚µ'), 
                  %quote(ope_non_chemo_cnt ope_chemo_cnt non_ope_non_chemo_cnt non_ope_chemo_cnt));
