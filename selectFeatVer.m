function [fv1name, validresponse] = selectFeatVer()

% selectFeatVer - select code version that Features & Labels were created
% by

validresponse = true;

fprintf('1: vPM1\n');
fprintf('2: V3\n');
sfv1 = input('Choose code version for features ? ', 's');

fv1 = str2double(sfv1);

if (isnan(fv1) || fv1 < 1 || fv1 > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    fv1 = 0;
    fv1name = '';
    return;
end

if fv1 == 1
    fv1name = 'vPM1';
elseif fv1 == 2
    fv1name = 'V3';
    
end

