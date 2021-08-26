function [safemethod, validresponse] = selectSafeDayMethodology()

% selectSafeDayMethodology - choose the methodology to calculate safe days
% - either using a quality classifier or a defined data completeness rule

ssafemethod = input(sprintf('Select safe day methodology (1 = Quality classifier, 2 = Defined completeness rules) ? '), 's');

safemethod = str2double(ssafemethod);

if (isnan(safemethod) || safemethod < 1 || safemethod > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    safemethod = 0;
else
    validresponse = true;
end

end

