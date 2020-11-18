function [plottype, validresponse] = selectQCPlotType()

% selectPlotType - choose the type of plot desired

fprintf('Choices of plot\n');
fprintf('---------------\n');
fprintf(' 1. Weights\n');
fprintf(' 2. PR and ROC Curves\n');
fprintf(' 3. QS vs Missingness\n');
fprintf(' 4. Model Calibration\n');
fprintf(' 5. Decision Tree\n');
fprintf(' 6. Tree leaf analysis\n');
fprintf('\n');
splottype = input('Choose plot type ? ', 's');

nplots = 6;
plottype = str2double(splottype);

if (isnan(plottype) || plottype < 1 || plottype > nplots)
    fprintf('Invalid choice\n');
    validresponse = false;
    plottype = 0;
else
    validresponse = true;
end

end

