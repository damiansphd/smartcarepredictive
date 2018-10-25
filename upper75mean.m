function y = upper75mean(x)

% upper75mean - returns the mean of the upper 75% data points in x 

x = sort(x, 'ascend');
percentile25 = round(size(x,1) * .25) + 1;

y = mean(x(percentile25:end));

end

