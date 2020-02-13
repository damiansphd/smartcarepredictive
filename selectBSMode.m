function [btmode, btsuffix, validresponse] = selectBSMode()

% selectBSMode - choose whether to run bootstrapping or not

sbtmode = input(sprintf('Run bootstrapping (1 = Y, 2 = N) ? '), 's');

btmode = str2double(sbtmode);

if (isnan(btmode) || btmode < 1 || btmode > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    btmode = 0;
else
    validresponse = true;
end

btsuffix = sprintf('bt%1d',btmode);

end

