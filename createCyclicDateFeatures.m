function [datefeat] = createCyclicDateFeatures(calcdate, ndatefeatures, monthfeat)

% createCyclicDateFeatures - creates cyclic bucketed date features

daysinyear  = day(datetime(year(calcdate), 12, 31), 'dayofyear');
thisdoy    = day(calcdate, 'dayofyear');

if monthfeat == 1
    datefeat    = zeros(1, ndatefeatures);
    datefeat(1) = sin(2 * pi * thisdoy / daysinyear);
    datefeat(2) = cos(2 * pi * thisdoy / daysinyear);
else
    % set relevant variables
    ntilepoints = zeros(1, ndatefeatures + 1);
    datefeat    = zeros(1, ndatefeatures + 1);
    for n = 1:ndatefeatures
            ntilepoints(n + 1) = (daysinyear * n) / ndatefeatures;
    end

    lowerq = find(ntilepoints <= thisdoy, 1, 'last');
    upperq = find(ntilepoints >= thisdoy, 1);
    if lowerq == upperq
        % datapoint is exactly on one of the ntile boundaries
        datefeat(lowerq) = 1;
    else
        % regular case - datapoint is between two boundaries
        datefeat(lowerq) = abs(ntilepoints(upperq) - thisdoy) / (ntilepoints(upperq) - ntilepoints(lowerq));
        datefeat(upperq) = abs(ntilepoints(lowerq) - thisdoy) / (ntilepoints(upperq) - ntilepoints(lowerq));
    end

    % make the bucketed date features cyclic
    if upperq == ndatefeatures + 1
        datefeat(1) = datefeat(ndatefeatures + 1);
    end
    datefeat(ndatefeatures + 1) = [];
end

end

