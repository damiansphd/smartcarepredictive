function [auFeatureIndex, auDataWinArray, auExABxElLabels, naugexamples] ...
            = augmentDataWindowArray(pmFeatureIndex, pmDataWinArray, pmExABxElLabels, datawinparamsrow, nmeasures)

% first create augmented feature and label arrays.
norigexamples = size(pmFeatureIndex, 1);
multiplier = datawinparamsrow.augmethod;
naugexamples  = norigexamples * multiplier;

nmsscentypes = 12;

[~, ~, totalduration] = setDataWindowArrayParams(datawinparamsrow);

[auFeatureIndex, auDataWinArray, auExABxElLabels] = createDataWindowArrays(naugexamples, nmeasures, totalduration); 
    
fprintf('Augmenting data set with missingness scenarios\n');
tic
fprintf('First copying over existing data\n');
% first need to copy over existing examples, and add entries to the new
% missingness scenario index
auFeatureIndex(1:norigexamples, :)    = pmFeatureIndex;
auDataWinArray(1:norigexamples, :, :) = pmDataWinArray;
auExABxElLabels(1:norigexamples)      = pmExABxElLabels;

toc
fprintf('\n');
tic
fprintf('Next augmenting data set to be %dx larger\n', multiplier);
% make repeatable
rng(2);
for i = (norigexamples + 1):naugexamples
    % first choose an example at random
    baseex = randi(norigexamples);
    
    auFeatureIndex(i, :)    = pmFeatureIndex(baseex, :);
    auDataWinArray(i, :, :) = pmDataWinArray(baseex, :, :);
    auExABxElLabels(i)      = pmExABxElLabels(baseex);
    
    % then choose missingness scenario type at random
    % then choose relevant parameter at random (within allowed values)
    msscen = randi(nmsscentypes);
    auFeatureIndex.ScenType(i)   = msscen;
    auFeatureIndex.BaseExample(i) = baseex;
    
    switch msscen
        case 1
            % remove data points at a fixed frequency
            msfreq = randi(3) + 1;
            nreps = ceil(totalduration/msfreq);
            freqidx = false(1, msfreq);
            freqidx(1) = true;
            featidx = repmat(freqidx, 1, nreps);
            featidx = featidx(1:totalduration);
            for m = 1:nmeasures
                auDataWinArray(i, featidx, m) = nan;
            end
            auFeatureIndex.Scenario{i}  = 'Frequency';
            auFeatureIndex.Frequency(i) = msfreq;
        case 2
            % remove a percentage of data points at random
            mspct = rand(1) * 100;
            nrem = ceil(totalduration * mspct / 100);
            posarray = randperm(totalduration, nrem);
            featidx = false(1, totalduration);
            featidx(posarray) = true;
            for m = 1:nmeasures
                auDataWinArray(i, featidx, m) = nan;
            end
            auFeatureIndex.Scenario{i} = 'Percentage';
            auFeatureIndex.Percentage(i) = mspct;
        case 3
            % remove all data points for one or more measures
            msmeas = randi([0 1], 1, nmeasures);
            for m = 1:nmeasures
                if msmeas(m) == 1
                   auDataWinArray(i, :, m) = nan;
                end
            end
            auFeatureIndex.Scenario{i} = 'Remove all points';
            str_x = num2str(msmeas);
            str_x(isspace(str_x)) = '';
            auFeatureIndex.Measure{i}  = str_x;
        case {4, 5, 6, 7, 8, 9, 10, 11, 12}    
            % inherit actual missingness from another example but store
            % all as type as 4 just to make it easier
            auFeatureIndex.ScenType(i)   = 4;
            msex = baseex;
            while msex == baseex
                msex = randi(norigexamples);
            end
            for m = 1:nmeasures
                featidx = isnan(auDataWinArray(msex, :, m));
                auDataWinArray(i, featidx, m) = nan;
                auFeatureIndex.Scenario{i} = 'Reuse Actual';
                auFeatureIndex.MSExample(i) = msex;
            end
    end
    
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

