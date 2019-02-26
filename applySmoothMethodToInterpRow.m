function [outputrow] = applySmoothMethodToInterpRow(interpdatarow, smfunction, smwindow, smlength, m, mfev1idx)

% applySmoothMethodToInterpRow - apply appropriate smoothing method to
% given interpolated data row (for use in predictive model)
%
% smfunction        Description
% ---------------   -----------
%       0           No smoothing
%       1           Mean for all measures
%       2           Median for all measures
%       3           Max for FEV1, mean for all others
%
% smwindow          Description
% ---------------   -----------
%       1           Centered
%       2           Trailing
%
% smlength - number of days for window

if smfunction == 0
    outputrow = rawdatarow;
else
    if smwindow == 1
        width = smlength;
    elseif smwindow == 2
        width = [(smlength - 1) 0];
    end
    outputrow = interpdatarow;
    if smfunction == 1
        if smwindow == 1
            % for backward compatibility - can remove once prove results
            % match
            outputrow = smooth(interpdatarow, width);
        else
            outputrow = movmean(outputrow, width);
        end
    elseif smfunction == 2
        outputrow = movmedian(outputrow, width);
    else
        if m == mfev1idx
            outputrow = movmax(outputrow, width);
        else
            if smwindow == 1
                % for backward compatibility - can remove once prove results
                % match
                outputrow = smooth(interpdatarow, width);
            else
                outputrow = movmean(outputrow, width);
            end
        end
            
    end
end

end

