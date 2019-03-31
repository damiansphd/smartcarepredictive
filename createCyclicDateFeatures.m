function [dfeat] = createCyclicDateFeatures(calcdate, ndatefeatures, datefeat)

% createCyclicDateFeatures - creates cyclic bucketed date features

daysinyear  = day(datetime(year(calcdate), 12, 31), 'dayofyear');
thisdoy    = day(calcdate, 'dayofyear');

if datefeat == 1
    dfeat    = zeros(1, ndatefeatures);
    dfeat(1) = sin(2 * pi * thisdoy / daysinyear);
    dfeat(2) = cos(2 * pi * thisdoy / daysinyear);
else
    % set relevant variables
    ntilepoints = zeros(1, ndatefeatures + 2);
    dfeat    = zeros(1, ndatefeatures + 2);
    for n = 1:ndatefeatures + 1
            ntilepoints(n + 1) = (daysinyear * n) / (ndatefeatures + 1);
    end

    lowerq = find(ntilepoints <= thisdoy, 1, 'last');
    upperq = find(ntilepoints >= thisdoy, 1);
    if lowerq == upperq
        % datapoint is exactly on one of the ntile boundaries
        dfeat(lowerq) = 1;
    else
        % regular case - datapoint is between two boundaries
        dfeat(lowerq) = abs(ntilepoints(upperq) - thisdoy) / (ntilepoints(upperq) - ntilepoints(lowerq));
        dfeat(upperq) = abs(ntilepoints(lowerq) - thisdoy) / (ntilepoints(upperq) - ntilepoints(lowerq));
    end

    % make the bucketed date features cyclic
    if upperq == ndatefeatures + 2
        dfeat(1) = dfeat(ndatefeatures + 2);
    end
    dfeat((ndatefeatures + 1):(ndatefeatures + 2)) = [];
end

end

