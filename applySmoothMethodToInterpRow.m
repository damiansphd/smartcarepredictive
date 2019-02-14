function [outputrow] = applySmoothMethodToInterpRow(interpdatarow, smoothingmethod, m, mfev1idx)

% applySmoothMethodToInterpRow - apply appropriate smoothing method to
% given interpolated data row (for use in predictive model)
%
% Smoothingmethod   Description
% ---------------   -----------
%       1           No smoothing
%       2           Centered 5 day window Mean
%       3           FEV1: Centered 3 day window, Max, Other measures: Centered 5 day window Mean

if smoothingmethod == 1
    outputrow = interpdatarow;
elseif smoothingmethod == 2 || (m ~= mfev1idx)
    outputrow = smooth(interpdatarow, 5);
elseif smoothingmethod == 3 && m == mfev1idx
        outputrow = movmax(interpdatarow, 3);
end

end

