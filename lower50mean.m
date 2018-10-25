function y = lower50mean(x)

% lower50mean - returns the mean of the lower 50% of data points in x 

x = sort(x, 'descend');
percentile50 = round(size(x,1) * .5) + 1;

y = mean(x(percentile50:end));

end

