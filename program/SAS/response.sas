**************************************************************************
Program Name : response.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-25
SAS version : 9.4
**************************************************************************;
* 5.5.3. Response rate of treatment;
%macro EDIT_RESPONSE(input_ds, output_ds, var, max_index);
    /*  *** Functional argument *** 
        input_ds : Table name of select statement 
        output_ds : Output dataset
        var : Target variable
        max_index : Number of output items
        *** Example ***
        %EDIT_RESPONSE(ds_res_ope_chemo, res_ope_chemo, adjuvantCAT, 5);
    */
    %local i;
    %do i = 1 %to &max_index.;
        data temp_input_&output_ds.&i.;
            set &input_ds.;
            if &var.=&i. then do;
                output;
            end;
        run;
        %EDIT_TREATMENT(output_&output_ds.&i., RECISTORRES, %quote('CR', 'PR', 'SD', 'PD', 'NE'), input_ds=temp_input_&output_ds.&i.);
    %end;
%mend;
%EDIT_TREATMENT(response_ope_non_chemo, RECISTORRES, %quote('CR', 'PR', 'SD', 'PD', 'NE'));
data ds_res_ope_chemo ds_res_non_ope_chemo;
    set ptdata;
    if analysis_set=&ope_chemo. then do;
        output ds_res_ope_chemo;
    end;
    if analysis_set=&non_ope_chemo. then do;
        output ds_res_non_ope_chemo;
    end;
run;
%EDIT_RESPONSE(ds_res_ope_chemo, res_ope_chemo, adjuvantCAT, 5);
%EDIT_RESPONSE(ds_res_non_ope_chemo, res_non_ope_chemo, chemCAT, 10);
