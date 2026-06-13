function [trigtype, ttsuffix, validresponse] = selectTriggerMode()

% selectTriggerMode - select which signal colours count as a triggered
% interventions

strigtype = input(sprintf('Select trigger mode (1 = Red Only, 2 = Red and Amber) ? '), 's');

trigtype = str2double(strigtype);

if (isnan(trigtype) || trigtype < 1 || trigtype > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    trigtype = 0;
else
    validresponse = true;
end

if trigtype == 1
    ttsuffix = 'ttRed';
elseif trigtype == 2
    ttsuffix = 'ttRedAmb';
else
    ttsuffix = 'ttError';
end

end

