function [rm1, validresponse] = selectRawMeasComb()

% selectRawMeasComb- choose the combination of Raw Measures to filter model
% results listing by

validresponse = true;
maxrmcomb = 150;

srm1 = input('Choose raw measures combination ? ', 's');

rm1 = str2double(srm1);

if (isnan(rm1) || rm1 < 1 || rm1 > maxrmcomb)
    fprintf('Invalid choice\n');
    validresponse = false;
    rm1 = 0;
    return;
end

end

