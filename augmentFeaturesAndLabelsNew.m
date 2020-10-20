function [auFeatureIndex, auMuIndex, auSigmaIndex, auRawMeasFeats, auMSFeats, auVolFeats, auPMeanFeats, auExABxElLabels] ...
            = augmentFeaturesAndLabelsNew(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, ...
                    pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels, basefeatparamsrow, nmeasures)

% first create augmented feature and label arrays.
norigexamples = size(pmFeatureIndex, 1);
multiplier = basefeatparamsrow.augmethod;
naugexamples  = norigexamples * multiplier;

nmsscentypes = 12;

outrangeconst = basefeatparamsrow.msconst;

[~, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures] = setBaseNumMeasAndFeaturesNew(basefeatparamsrow, nmeasures);

[auFeatureIndex, auMuIndex, auSigmaIndex, auRawMeasFeats, auMSFeats, auVolFeats, auPMeanFeats, auExABxElLabels] ...
        = createFeatureAndLabelArraysNew(nexamples, nmeasures, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures); 

fprintf('Augmenting data set with missingness scenarios\n');
tic
fprintf('First copying over existing data\n');
% first need to copy over existing examples, and add entries to the new
% missingness scenario index
auFeatureIndex(1:norigexamples, :)   = pmFeatureIndex;
auMuIndex(1:norigexamples, :)        = pmMuIndex;
auSigmaIndex(1:norigexamples, :)     = pmSigmaIndex;

auRawMeasFeats(1:norigexamples, :)   = pmRawMeasFeats;
auMSFeats(1:norigexamples, :)        = pmMSFeats;
auVolFeats(1:norigexamples, :)       = pmVolFeats;
auPMeanFeats(1:norigexamples, :)     = pmPMeanFeats;

auExABxElLabels(1:norigexamples)     = pmExABxElLabels;

toc
fprintf('\n');
tic
fprintf('Next augmenting data set to be %dx larger\n', multiplier);
% make repeatable
rng(2);
for i = (norigexamples + 1):naugexamples
    % first choose an example at random
    baseex = randi(norigexamples);
    
    auFeatureIndex(i, :)   = pmFeatureIndex(baseex, :);
    auMuIndex(i, :)        = pmMuIndex(baseex, :);
    auSigmaIndex(i, :)     = pmSigmaIndex(baseex, :);
    
    auRawMeasFeats(i, :)   = pmRawMeasFeats(baseex, :);
    auMSFeats(i, :)        = pmMSFeats(baseex, :);
    auVolFeats(i, :)       = pmVolFeats(baseex, :);
    auPMeanFeats(i, :)     = pmPMeanFeats(baseex, :);

    auExABxElLabels(i)     = pmExABxElLabels(baseex);
    
    % then choose missingness scenario type at random
    % then choose relevant parameter at random (within allowed values)
    msscen = randi(nmsscentypes);
    auFeatureIndex.ScenType(i)   = msscen;
    auFeatureIndex.BaseExample(i) = baseex;
    
    switch msscen
        case 1
            % remove data points at a fixed frequency
            msfreq = randi(3) + 1;
            nmrawfeat = nrawfeatures/nmeasures;
            nreps = ceil(nmrawfeat/msfreq);
            freqidx = false(1, msfreq);
            freqidx(1) = true;
            featidx = repmat(freqidx, 1, nreps);
            featidx = featidx(1:nmrawfeat);
            for m = 1:nmeasures
                tmpdata = auRawMeasFeats(i, (((m - 1) * nmrawfeat) + 1):(m * nmrawfeat));
                tmpdata(featidx) = outrangeconst;
                auRawMeasFeats(i, (((m - 1) * nmrawfeat) + 1):(m * nmrawfeat)) = tmpdata;
            end
            auFeatureIndex.Scenario{i}  = 'Frequency';
            auFeatureIndex.Frequency(i) = msfreq;
        case 2
            % remove a percentage of data points at random
            mspct = rand(1) * 100;
            nrem = ceil(nrawfeatures * mspct / 100);
            posarray = randperm(nrawfeatures, nrem);
            featidx = false(1, nrawfeatures);
            featidx(posarray) = true;
            auRawMeasFeats(i, featidx) = outrangeconst;
            auFeatureIndex.Scenario{i} = 'Percentage';
            auFeatureIndex.Percentage(i) = mspct;
        case 3
            % inherit actual missingness from another example
            msex = baseex;
            while msex == baseex
                msex = randi(norigexamples);
            end
            featidx = auRawMeasFeats(msex, :) == outrangeconst;
            auRawMeasFeats(i, featidx) = outrangeconst;
            auFeatureIndex.Scenario{i} = 'Reuse Actual';
            auFeatureIndex.MSExample(i) = msex;
        case {4, 5, 6, 7, 8, 9, 10, 11, 12}
            % remove all data points for one or more measures
            msmeas = randi([0 1], 1, nmeasures);
            nmrawfeat = nrawfeatures/nmeasures;
            featidx = false(1, nrawfeatures);
            for m = 1:nmeasures
                featidx((((m - 1) * nmrawfeat) + 1):(m * nmrawfeat)) = msmeas(m);
            end
            auRawMeasFeats(i, featidx) = outrangeconst;
            auFeatureIndex.Scenario{i} = 'Remove all points';
            str_x = num2str(msmeas);
            str_x(isspace(str_x)) = '';
            auFeatureIndex.Measure{i}  = str_x;
    end
    
    % update missingness features accordingly
    msidx = zeros(1, nmsfeatures);
    msidx(auRawMeasFeats(i,:) == outrangeconst) = 1;
    auMSFeats(i, :) = msidx; 
    
    % should recalculate VolFeats after applying missingness as well.
    % and reapply interpolation and smoothing etc depending on run parameters
    
    if ((i - norigexamples)/100) == round((i - norigexamples)/100)
        fprintf('.');
        if ((i - norigexamples)/5000) == round((i - norigexamples)/5000)
            fprintf('\n');
        end
    end
end
fprintf('\n');
toc
fprintf('\n');

end

