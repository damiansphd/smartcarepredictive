function [pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
        muntilepoints, sigmantilepoints, pmInterpDatacube, pmInterpVolcube, mvolstats, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ntilepoints, pmMSDatacube] ...
        = createPreBaseFeat(pmPatients, npatients, pmOverallStats, pmPatientMeasStats, ...
        pmRawDatacube, pmInterpDatacube, maxdays, measures, nmeasures, featureparams, rp)

% createPreBaseFeat - utility function to create the various norm, vol,
% range cubes - can be used by main createBaseFeaturesAndLabelsScript as
% well as Missingness Scenario

studydisplayname = featureparams.StudyDisplayName{1};

% create normalisation window cube (for use with Normalisation method 3 & 4 in
% model
tic
fprintf('Creating normalisation window cube\n');
[pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
muntilepoints, sigmantilepoints] = createPMNormWindowcube(pmPatients, pmInterpDatacube, ...
    pmOverallStats, pmPatientMeasStats, featureparams.normmethod(rp), ...
    featureparams.normwindow(rp), featureparams.nbuckpmeas(rp),...
    npatients, maxdays, measures, nmeasures, studydisplayname); 
toc
fprintf('\n');

% create measures volatility cube
tic
fprintf('Creating volatility and segment volatility cubes\n');
[pmInterpVolcube, mvolstats, pmInterpSegVolcube] = createPMInterpVolcube(pmPatients, pmInterpDatacube, ...
    npatients, maxdays, nmeasures, featureparams.featureduration(rp), featureparams.nvolseg(rp), ...
    featureparams.normwindow(rp)); 
toc
fprintf('\n');

% create measures range cube
tic
fprintf('Creating range and segment average measure cubes\n');
[pmInterpRangecube, pmInterpSegAvgcube] = createPMInterpRangecube(pmPatients, pmInterpDatacube, ...
    npatients, maxdays, nmeasures, featureparams.featureduration(rp), featureparams.navgseg(rp), ...
    featureparams.normwindow(rp)); 
toc
fprintf('\n');

if featureparams.smfunction(rp) > 0
    tic
    pmInterpDatacube = createPMInterpSmoothcube(pmInterpDatacube, pmPatients, npatients, ...
                            maxdays, measures, nmeasures, featureparams.smfunction(rp), ...
                            featureparams.smwindow(rp), featureparams.smlength(rp));
    toc
    fprintf('\n');
end

% create bucketed data cube
tic
fprintf('Creating bucketed data\n');
[pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpDatacube, featureparams.nbuckets(rp), npatients, maxdays, nmeasures); 
toc
fprintf('\n');

% create missingness data cube
tic
fprintf('Creating missingness cube\n');
pmMSDatacube = ~isnan(pmRawDatacube);
toc
fprintf('\n');

end

