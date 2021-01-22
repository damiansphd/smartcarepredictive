function [value, validresponse] = selectFromArrayByIndex(valuetype, valuearray)

% selectFromArrayByIndex - choose a value from an array of choices by index

nvalcomb = unique(valuearray);

if size(nvalcomb, 1) > 1
    fprintf('Available options for %s:\n', valuetype);
    for i = 1:size(nvalcomb, 1)
        fprintf('%d: %.4f\n', i, nvalcomb(i));
    end
    fprintf('\n');
    sindex = input('Choose index value ? ', 's');
    index = str2double(sindex);
    if (isnan(index) || ~ismember(index, 1:size(nvalcomb, 1)))
        fprintf('Invalid choice\n');
        validresponse = false;
        value = 0;
    else
        validresponse = true;
        value = nvalcomb(index);
    end
else
    validresponse = true;
    value = nvalcomb(1);
end

end

