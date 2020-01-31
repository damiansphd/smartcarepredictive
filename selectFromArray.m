function [value, validresponse] = selectFromArray(valuetype, valuearray)

% selectFromArray - choose a value from an array of choices

nvalcomb = unique(valuearray);

if size(nvalcomb, 1) > 1
    fprintf('Available options for %s: ', valuetype);
    fprintf('%.2f ', nvalcomb);
    fprintf('\n');
    svalue = input('Choose value ? ', 's');
    value = str2double(svalue);
    if (isnan(value) || ~ismember(value, nvalcomb))
        fprintf('Invalid choice\n');
        validresponse = false;
        value = 0;
    else
        validresponse = true;
    end
else
    value = nvalcomb(1);
    validresponse = true;
end

end

