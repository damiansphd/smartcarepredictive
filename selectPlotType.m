function [plottype, validresponse] = selectPlotType()

% selectPlotType - choose the type of plot desired

fprintf('Choices of plot\n');
fprintf('---------------\n');
fprintf('1. Weights\n');
fprintf('2. Weights for Days 2, 5, 8\n');
fprintf('3. PR and ROC Curves\n');
fprintf('4. PR and ROC Curves for Days 2, 5, 8\n');
fprintf('5. Measures and Predictions for all Patients\n');
fprintf('6. Measures and Predictions for a single Patient\n');
fprintf('\n');
splottype = input('Choose plot type ? ', 's');

plottype = str2double(splottype);

if (isnan(plottype) || plottype < 1 || plottype > 6)
    fprintf('Invalid choice\n');
    validresponse = false;
    plottype = 0;
else
    validresponse = true;
end

end

