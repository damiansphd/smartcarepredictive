function pmMSWinArray = createMSWinArray(datawinarray, nexamples, totalwin, nmeasures, modfeatparamsrow)

% createMSWinArray - creates Missingness Feature Array

fprintf('Creating missingness data window array\n');
if modfeatparamsrow.missinterp == 1
    % calculate missingness features after populating missing values
    % i.e. missingness features always zero
    pmMSWinArray = zeros(nexamples, totalwin, nmeasures);
elseif modfeatparamsrow.missinterp == 2
    % calculate missingness features before populating missing values
    % i.e. missingness features represent true missing data points
    pmMSWinArray = zeros(nexamples, totalwin, nmeasures);
    pmMSWinArray(isnan(datawinarray)) = 1;
else
    fprintf('Unknown missingness interp order method\n');
end




end

