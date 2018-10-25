function y = upper50mean(x)

% upper50mean - returns the mean of the upper 50% of data points in x 

x = sort(x, 'ascend');
percentile50 = round(size(x,1) * .5) + 1;

y = mean(x(percentile50:end));

end

