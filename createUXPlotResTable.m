function [tabResults] = createUXPlotResTable(nrows)

% createUXPlotResTable - creates the table to store the UX plot results for
% excel dump

tabResults = table('Size',[nrows, 41], ...
                   'VariableTypes', {'double', ...                                          %days
                                      'double', 'double', 'double', 'logical',...           %meas1
                                      'double', 'double', 'double', 'logical',...           %meas2
                                      'double', 'double', 'double', 'logical',...           %meas3
                                      'double', 'double', 'double', 'logical',...           %meas4
                                      'double', 'double', 'double', 'logical',...           %meas5
                                      'double', 'double', 'double', 'double', 'double', ... %predclass
                                      'double', 'double', ...                               %qualclass
                                      'double', 'double', 'double', ...                     %colours
                                      'double', 'double', 'double', ...
                                      'double', 'double', 'double', ...
                                      'double', 'double', ...                               % oral and iv info
                                      'double', 'double'}, ...                              % ex start info                    
                   'VariableNames', {'Days', ...                                            %days
                                      'Co_raw', 'Co_sm', 'Co_interp', 'Co_miss', ...        %meas1
                                      'Lu_raw', 'Lu_sm', 'Lu_interp', 'Lu_miss', ...        %meas2
                                      'O2_raw', 'O2_sm', 'O2_interp', 'O2_miss', ...        %meas3
                                      'Pu_raw', 'Pu_sm', 'Pu_interp', 'Pu_miss', ...        %meas4
                                      'We_raw', 'We_sm', 'We_interp', 'We_miss', ...        %meas5
                                      'PC_Pred', 'PC_Label', 'PC_Opthr', 'PC_Amthr', 'PC_Rdthr', ... %predclass
                                      'QC_Pred', 'QC_Opthr', ...                            %qualclass
                                      'PC_col_R', 'PC_col_G', 'PC_col_B', ...               %colours
                                      'QC_col_R', 'QC_col_G', 'QC_col_B', ...
                                      'BS_col_R', 'BS_col_G', 'BS_col_B', ...
                                      'Ab_Oral',  'Ab_IV', ...                              % oral and iv info
                                      'Ex_Start',  'Ex_90Conf'});                           % ex start info 
                              
end

