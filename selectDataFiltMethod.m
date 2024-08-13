function [df1, dfdisplayname, validresponse] = selectDataFiltMethod()

% selectDataFiltMethod - choose the data filtering method used to create
% the predictive model input data

validresponse = true;

fprintf('1: No data filtering\n');
fprintf('2: Keep data only when on Triple Therapy\n');
fprintf('\n');
sdf1 = input('Choose data filtering method ? ', 's');

df1 = str2double(sdf1);

if (isnan(df1) || df1 < 1 || df1 > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    df1 = 0;
    dfdisplayname = '';
    return;
end

if df1 == 1
    dfdisplayname = '';
elseif df1 == 2
    dfdisplayname = 'TT';
end

end

