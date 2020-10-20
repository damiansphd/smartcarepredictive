function [fv1name, validresponse] = selectFeatVer()

% selectFeatVer - select code version that Features & Labels were created
% by

validresponse = true;

fprintf('1: vPM1\n');
fprintf('2: N/A\n');
fprintf('3: V3\n');
fprintf('4: V4\n');
fprintf('5: V5\n');

sfv1 = input('Choose code version for features ? ', 's');

fv1 = str2double(sfv1);

if (isnan(fv1) || fv1 < 1 || fv1 > 5)
    fprintf('Invalid choice\n');
    validresponse = false;
    fv1 = 0;
    fv1name = '';
    return;
end

if fv1 == 1
    fv1name = 'vPM1';
elseif fv1 == 2
    fv1name = 'NA';
else
    fv1name = sprintf('V%d', fv1);
end

end
