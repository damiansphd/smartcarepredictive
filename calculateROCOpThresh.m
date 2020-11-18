function [thresh, threshidx] = calculateROCOpThresh(fpr, tpr, predsort)

% calculateROCOpThresh - calculates the inflexion point of the ROC curve
% for the optimal operatiing threshold.

nexamples = size(fpr, 1);

if nexamples < 100
    fprintf('Not enough samples to calculate\n');
    thresh = 0.5;
    return
end

gradarray = zeros(nexamples, 1);
gradwindow = ceil(nexamples / 10);

for i = (gradwindow + 1): (nexamples - gradwindow)
    temp = polyfit(fpr((i - gradwindow):(i + gradwindow)), tpr((i - gradwindow):(i + gradwindow)),1);
    gradarray(i) = temp(1);
end

gradidx = find(gradarray > 0 & gradarray < 1, 1, 'first');
fprthresh = fpr(gradidx);
fpridx  = find(fpr > fprthresh, 1, 'first');

threshidx = fpridx - 1;
thresh    = predsort(threshidx);

fprintf('Inflexion point is at index point %d with FPR %.6f TPR %.6f with operating threshold %.20f\n', threshidx, fpr(threshidx), tpr(threshidx), thresh);

end

