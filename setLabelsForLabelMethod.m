function [labels] = setLabelsForLabelMethod(labelmethod, ivlabels, exlabels, ablabels, exlblabels, exablabels)

% setLabelsForLabelMethod - sets labels relevant for the chosen label
% method


if  labelmethod == 1
    labels = ivlabels;
elseif labelmethod == 2
    labels = exlabels;
elseif labelmethod == 3
    labels = ablabels;
elseif labelmethod == 4
    labels = exlblabels;
elseif labelmethod == 5
    labels = exablabels;
else
    fprintf('Unknown label method\n');
    labels = [];
    return;
end

end
