function [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, nbuckets, npatients, maxdays, nmeasures)

% createPMBucketedcube - creates the bucketed features cube


% create quintile points for each measure
ntilepoints = zeros(nmeasures, nbuckets + 1);
for m = 1:nmeasures
    malldata = reshape(pmInterpNormcube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');    
    ntilepoints(m,1) = malldata(1);
    for n = 1:nbuckets
        ntilepoints(m,n + 1) = malldata(ceil((size(malldata,2) * n)/nbuckets));
    end
end

% create 4D array of bucketed features
pmBucketedcube = zeros(npatients, maxdays, nmeasures, nbuckets + 1);
for p = 1:npatients
    for m = 1:nmeasures
        for d = 1:maxdays
            if ~isnan(pmInterpNormcube(p, d, m))
                datapoint = pmInterpNormcube(p, d, m);
                lowerq = find(ntilepoints(m,:) <= datapoint, 1, 'last');
                upperq = find(ntilepoints(m,:) >= datapoint, 1);
                if lowerq == upperq
                    % datapoint is exactly on one of the ntile boundaries
                    pmBucketedcube(p, d, m, lowerq) = 1;
                elseif lowerq > upperq
                    % multiple ntile boundaries have the same value - spread
                    % features evenly across all of these
                    pmBucketedcube(p, d, m, upperq:lowerq) = 1/(lowerq - upperq + 1);
                else
                    % regular case - datapoint is between two boundaries
                    pmBucketedcube(p, d, m, lowerq) = abs(ntilepoints(m, upperq) - datapoint) / abs(ntilepoints(m, upperq) - ntilepoints(m, lowerq));
                    pmBucketedcube(p, d, m, upperq) = abs(ntilepoints(m, lowerq) - datapoint) / abs(ntilepoints(m, upperq) - ntilepoints(m, lowerq));
                end
            end
        end
    end
end

% remove last edge to avoid rank deficiency
pmBucketedcube(:,:,:,nbuckets+1) = [];

end

