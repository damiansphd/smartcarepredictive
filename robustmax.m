function y = robustmax(x)

% robustmax - returns the robust max of data set (2% from max)

x = sort(x, 'descend');
percentile2 = round(size(x,1) * .02) + 1;

y = x(percentile2);

end

