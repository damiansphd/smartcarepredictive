function [runmode, validresponse] = selectRunMode()

% selectFold - select which fold to run plot for

srunmode = input(sprintf('Select run mode (1 = Cross Val, 2 = Held-Out Test Set) ? '), 's');

runmode = str2double(srunmode);

if (isnan(runmode) || runmode < 1 || runmode > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    runmode = 0;
else
    validresponse = true;
end

end

