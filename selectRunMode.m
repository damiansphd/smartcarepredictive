function [runtype, rtsuffix, validresponse] = selectRunMode()

% selectFold - select which fold to run plot for

sruntype = input(sprintf('Select run mode (1 = Cross Val, 2 = Held-Out Test Set) ? '), 's');

runtype = str2double(sruntype);

if (isnan(runtype) || runtype < 1 || runtype > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    runtype = 0;
else
    validresponse = true;
end

rtsuffix = sprintf('rt%1d',runtype);

end

