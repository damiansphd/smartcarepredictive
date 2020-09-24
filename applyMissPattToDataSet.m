function [normfeatures, mpidxrow, mparrayrow] = applyMissPattToDataSet(normfeatures, ...
    mpidxrow, mparrayrow, nrawfeatures, nrawmeas, outrangeconst)
    
% applyMissPattToDataSet - choose a missingness pattern at random and apply
% to whole interpolated dataset

% choose missingness pattern at random and create a missingness pattern 
% index and array row
nmsscentypes = 3;
nmrawfeat = nrawfeatures/nrawmeas;
msscen       = randi(nmsscentypes);
mpidxrow.ScenType = msscen;

switch msscen
    case 1
        % remove data points at a fixed frequency
        msfreq = randi(3) + 1;
        nreps = ceil(nmrawfeat/msfreq);
        freqidx = zeros(1, msfreq);
        freqidx(1) = 1;
        featidx = repmat(freqidx, 1, nreps);
        featidx = featidx(1:nmrawfeat);
        for m = 1:nrawmeas
            mparrayrow( (((m - 1) * nmrawfeat) + 1) : (m * nmrawfeat) ) = featidx;
        end
        mpidxrow.Scenario{1} = 'Frequency';
        mpidxrow.Frequency   = msfreq;
    case 2
        % remove a percentage of data points at random
        mspct = rand(1) * 100;
        nrem = ceil(nrawfeatures * mspct / 100);
        posarray = randperm(nrawfeatures, nrem);
        featidx = zeros(1, nrawfeatures);
        featidx(posarray) = 1;
        mparrayrow = featidx;
        mpidxrow.Scenario{1} = 'Percentage';
        mpidxrow.Percentage  = mspct;
    case 3
        % remove all data points for one or more measures
        msmeas = randi([0 1], 1, nrawmeas);
        featidx = zeros(1, nrawfeatures);
        for m = 1:nrawmeas
            featidx((((m - 1) * nmrawfeat) + 1):(m * nmrawfeat)) = msmeas(m);
        end
        mparrayrow = featidx;
        mpidxrow.Scenario{1} = 'Remove all points';
        str_x = num2str(msmeas);
        str_x(isspace(str_x)) = '';
        mpidxrow.Measure{1}  = str_x;
end

% apply to interpolated raw features and missingness features
nexamples = size(normfeatures, 1);
mpmask = repmat(mparrayrow, nexamples, 1);

rawfeatures         = normfeatures(:, 1:nrawfeatures);
rawfeatures(logical(mpmask)) = outrangeconst;

msfeatures          = mpmask;

normfeatures = [rawfeatures, msfeatures];

end

