**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-20
SAS version : 9.4
**************************************************************************;
* 5.4 treatment;
%EDIT_TREATMENT(ds_surgical_curability, resectionCAT, %quote('RX', 'R0', 'R1', 'R2'));
%EDIT_TREATMENT(ds_adjuvant_chemo_regimen, adjuvantCAT, %quote(&regimens_adjuvant.));
%EDIT_TREATMENT(ds_first_line_chemo_regimen, chemCAT, %quote(&regimens_first_line.));
%EDIT_TREATMENT(ds_primary_site_resection, PLresectionYN, %quote('‚ ‚è', '‚È‚µ'));
