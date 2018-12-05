clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
featureparamfile = selectFeatureParameters();
featureparamfile = strcat(featureparamfile, '.xlsx');

pmThisFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmThisFeatureParams.featureduration);

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fbasefilename = generateFileNameFromFeatureParams(pmThisFeatureParams(1,:));
featureinputmatfile = sprintf('%s.mat',fbasefilename);
fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
load(fullfile(basedir, subfolder, featureinputmatfile));

nbuckets = pmThisFeatureParams.nbuckets(1);

ntilepoints = zeros(nmeasures, nbuckets + 1);
ntilecounts = zeros(nmeasures, nbuckets);
ntilepoints2 = zeros(nmeasures, nbuckets + 1);
ntilecounts2 = zeros(nmeasures, nbuckets);

for m = 1:nmeasures
    malldata = reshape(pmInterpNormcube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');
    minval = malldata(1);
    maxval = malldata(size(malldata,2));
    ntilepoints(m,1)              = minval;
    ntilepoints2(m,1)             = minval;
    for n = 1:nbuckets
        ntilepoints(m, n + 1)  = malldata(ceil((size(malldata,2) * n)/nbuckets));
        ntilepoints2(m, n + 1) = minval + ((maxval - minval) * (n/nbuckets));
    end
    ntilepoints2(m,nbuckets + 1) = maxval;
end

for p = 1:npatients
    for m = 1:nmeasures
        for d = 1:maxdays
            if ~isnan(pmInterpNormcube(p, d, m))
                datapoint = pmInterpNormcube(p, d, m);
                
                lowerq1 = find(ntilepoints(m,:) <= datapoint, 1, 'last');
                upperq1 = find(ntilepoints(m,:) >= datapoint, 1);
                if lowerq1 == upperq1
                    % datapoint is exactly on one of the ntile boundaries
                    if lowerq1 > nbuckets
                        ntilecounts(m, nbuckets) = ntilecounts(m, nbuckets)  + 1;
                    else
                        ntilecounts(m, lowerq1) = ntilecounts(m, lowerq1)  + 1;
                    end
                elseif lowerq1 > upperq1
                    % multiple ntile boundaries have the same value - spread
                    % features evenly across all of these
                    ntilecounts(m, upperq1) = ntilecounts(m, upperq1)  + 1;
                else
                    % regular case - datapoint is between two boundaries
                    ntilecounts(m, lowerq1) = ntilecounts(m, lowerq1)  + 1;
                end
                
                lowerq2 = find(ntilepoints2(m,:) <= datapoint, 1, 'last');
                upperq2 = find(ntilepoints2(m,:) >= datapoint, 1);
                if lowerq2 == upperq2
                    % datapoint is exactly on one of the ntile boundaries
                    if lowerq2 > nbuckets
                        ntilecounts2(m, nbuckets) = ntilecounts2(m, nbuckets) + 1;
                    else
                        ntilecounts2(m, lowerq2) = ntilecounts2(m, lowerq2) + 1;
                    end
                elseif lowerq2 > upperq2
                    % multiple ntile boundaries have the same value - spread
                    % features evenly across all of these
                    ntilecounts2(m, upperq2) = ntilecounts2(m, upperq2) + 1;
                else
                    % regular case - datapoint is between two boundaries
                    ntilecounts2(m, lowerq2) = ntilecounts2(m, lowerq2) + 1;
                end
            end
        end
    end
end




%if pmThisFeatureParams.bucketfeat(1) == 2
%    fprintf('Creating bucketed data\n');
%    [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, pmThisFeatureParams.nbuckets(1), npatients, maxdays, nmeasures); 
%else
%    pmBucketedcube = [];
%end


