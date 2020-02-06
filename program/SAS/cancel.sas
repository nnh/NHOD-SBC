**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-29
SAS version : 9.4
**************************************************************************;
* 5.2. Breakdown of cases and count of discontinued cases;
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='�Ǘ�̓���ƒ��~��W�v');
%FORMAT_FREQ(var=DSDECOD, item_list=%quote('����', '���~'), title='�Ǘ�̓���ƒ��~��W�v', output_ds=cancel, input_ds=ptdata_all, output_n_flg=0);
%let withdrawal_item_list=%quote('�����Ώێ҂����S�����ꍇ', '�]���Ȃǂɂ�茤���Ώێ҂��ǐՕs�\�ƂȂ����ꍇ','�����Ώێ҂ɂ�铯�ӓP��̐\���o���������ꍇ', 
                                 '�o�^��s�K�i�Ǘ�ł��邱�Ƃ����������ꍇ', '�d��Ȍ����v�揑�ᔽ�����������ꍇ', '���Y���{��Ë@�ւɂ����鎎�������~���ꂽ�ꍇ', 
                                 '�����S�̂����~���ꂽ�ꍇ', '���̑��̗��R�Ō����ӔC�ҁA�������S�҂ɂ�莎�����~���K�؂Ɣ��f���ꂽ�ꍇ');
%CREATE_OUTPUT_DS(output_ds=reasons_for_withdrawal, items_label='�Ǘ�̓���ƒ��~��W�v');
%FORMAT_FREQ(var=DSTERM, item_list=&withdrawal_item_list., title='���~���R', output_ds=reasons_for_withdrawal, input_ds=ptdata_all, output_n_flg=0);
