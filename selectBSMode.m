function [bsmode, validresponse] = selectBSMode()

% selectBSMode - choose whether to run bootstrapping or not

sbsmode = input(sprintf('Run bootstrapping (1 = Y, 2 = N) ? '), 's');

bsmode = str2double(sbsmode);

if (isnan(bsmode) || bsmode < 1 || bsmode > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    bsmode = 0;
else
    validresponse = true;
end

end

