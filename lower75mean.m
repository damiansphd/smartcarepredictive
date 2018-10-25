function y = lower75mean(x)

% lower75mean - returns the mean of the lower 75% data points in x 

x = sort(x, 'descend');
percentile25 = round(size(x,1) * .25) + 1;

y = mean(x(percentile25:end));

end

