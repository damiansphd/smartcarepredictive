function [lb1, lb1displayname, validresponse] = selectLabelMethod()

% selectLabelMethod - choose the label method to use in the plots

validresponse = true;

slb1 = input('Choose label method ? ', 's');

lb1 = str2double(slb1);

if (isnan(lb1) || lb1 < 1 || lb1 > 4)
    fprintf('Invalid choice\n');
    validresponse = false;
    lb1 = 0;
    return;
end

if lb1 == 1
    lb1displayname = 'IV';
elseif lb1 == 2
    lb1displayname = 'Ex';
elseif lb1 == 3
    lb1displayname = 'AB';
elseif lb1 == 4
    lb1displayname = 'ExLB';
end

end

