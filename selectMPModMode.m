function [mpmodmode, runqc, runpc, validresponse] = selectMPModMode()

% selectMPModMode - selects which models to run the missingness pattern
% safety check for

smpmodmode = input(sprintf('Select run mode (1 = Outer(Quality) Classifier, 2 = Inner (Predictive) Classifier, 3 = Both) ? '), 's');

mpmodmode = str2double(smpmodmode);

if (isnan(mpmodmode) || mpmodmode < 1 || mpmodmode > 3)
    fprintf('Invalid choice\n');
    validresponse = false;
    mpmodmode = 0;
else
    validresponse = true;
end

runqc = false;
runpc = false;

if mpmodmode == 1
    runqc = true;
elseif mpmodmode == 2
    runpc = true;
elseif mpmodmode == 3
    runqc = true;
    runpc = true;
else
    fprintf('**** Unknown mp model mode ****\n');
    validresponse = false;
    return;
end

end

