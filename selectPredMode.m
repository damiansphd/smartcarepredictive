function [predtype, ptsuffix, validresponse] = selectPredMode()

% selectPredMode - select prediction mode - either use actual predictions
% or 3-colour scale

spredtype = input(sprintf('Select prediction mode (1 = Actual predictions, 2 = 3-colour scale) ? '), 's');

predtype = str2double(spredtype);

if (isnan(predtype) || predtype < 1 || predtype > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    predtype = 0;
else
    validresponse = true;
end

if predtype == 1
    ptsuffix = 'ptAct';
elseif predtype == 2
    ptsuffix = 'ptCol';
else
    ptsuffix = 'ptError';
end

end
