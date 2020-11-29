function [plottype, validresponse] = selectQCPlotType()

% selectPlotType - choose the type of plot desired

fprintf('Choices of plot\n');
fprintf('---------------\n');
fprintf(' 1. Weights\n');
fprintf(' 2. PR, ROC, and QC Cost Curves\n');
fprintf(' 3. QS vs Missingness by type of quality measure\n');
fprintf(' 4. QS vs Missingness by type of measurement\n');
fprintf(' 5. QS vs Missingness by model outcome\n');
fprintf(' 6. Model Calibration\n');
fprintf(' 7. Decision Tree\n');
fprintf(' 8. Tree leaf analysis\n');
fprintf('\n');
splottype = input('Choose plot type ? ', 's');

nplots = 8;
plottype = str2double(splottype);

if (isnan(plottype) || plottype < 1 || plottype > nplots)
    fprintf('Invalid choice\n');
    validresponse = false;
    plottype = 0;
else
    validresponse = true;
end

end

