function [epiindex, epilabl, epipred] = convertResultsToEpisodes(featureindex, labels, pred, epilen)

% convertResultsToEpisodes - takes daily labels and predictions and
% converts them to episodes

% create enough space for the results with room to spare
bufferrows = round((size(featureindex, 1) / epilen) * 1.5);

epiindex = table('Size',[bufferrows, 10], ...
    'VariableTypes', {'double', 'double',     'cell',  'double', 'datetime', 'datetime', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'EpiNbr', 'PatientNbr', 'Study', 'ID',     'FromDate', 'ToDate',   'Fromdn', 'Todn',   'Length', 'PartialPeriod'});

epilabl = zeros(bufferrows, 1);
epipred = zeros(bufferrows, 1);

epinbr = 1;
patients = unique(featureindex.PatientNbr);
for i = 1:size(patients, 1)
    pnbr    = patients(i);
    date    = min(featureindex.CalcDatedn(featureindex.PatientNbr == pnbr));
    maxdate = max(featureindex.CalcDatedn(featureindex.PatientNbr == pnbr));
    study   = featureindex.Study{featureindex.PatientNbr == pnbr & featureindex.CalcDatedn == date};
    id      = featureindex.ID(featureindex.PatientNbr == pnbr    & featureindex.CalcDatedn == date);
    
    while date <= maxdate
        % create episode index entry
        epiindex.EpiNbr(epinbr)     = epinbr;
        epiindex.PatientNbr(epinbr) = pnbr;
        epiindex.Study{epinbr}      = study;
        epiindex.ID(epinbr)         = id;
        epiindex.FromDate(epinbr)   =     featureindex.CalcDate(featureindex.PatientNbr == pnbr   & featureindex.CalcDatedn == date);
        epiindex.ToDate(epinbr)     = max(featureindex.CalcDate(featureindex.PatientNbr == pnbr   & featureindex.CalcDatedn <= date + (epilen - 1)));
        epiindex.Fromdn(epinbr)     = date;
        epiindex.Todn(epinbr)       = max(featureindex.CalcDatedn(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn <= date + (epilen - 1)));
        epiindex.Length(epinbr)     = epiindex.Todn(epinbr) - epiindex.Fromdn(epinbr) + 1;
        if epiindex.Length(epinbr) < epilen
            epiindex.PartialPeriod(epinbr) = 1;
            partialtxt = '****';
            
        else
            epiindex.PartialPeriod(epinbr) = 0;
            partialtxt = '';
        end
        
        % create episode label
        if epiindex.Length(epinbr) == 1
            if labels(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn == epiindex.Fromdn(epinbr)) == 1
                epilabl(epinbr) = 1;
            else
                epilabl(epinbr) = 0;
            end
        else
            if all(labels(featureindex.PatientNbr == pnbr  & featureindex.CalcDatedn >= (epiindex.Fromdn(epinbr)    ) & featureindex.CalcDatedn <= epiindex.Todn(epinbr))) || ...
               all(labels(featureindex.PatientNbr == pnbr  & featureindex.CalcDatedn >= (epiindex.Fromdn(epinbr) + 1) & featureindex.CalcDatedn <= epiindex.Todn(epinbr))) 
                epilabl(epinbr) = 1;
            else
                epilabl(epinbr) = 0;
            end 
        end
        
        % create episode prediction
        epipred(epinbr) = max(pred(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn >= epiindex.Fromdn(epinbr) & featureindex.CalcDatedn <= epiindex.Todn(epinbr)));
        
        % increment date and epinbr ahead of next iteration
        date = min(featureindex.CalcDatedn(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn > epiindex.Todn(epinbr)));
        fprintf('EpiNbr %3d: PatNbr %3d Fromdn %3d, Todn %3d, Length %1d Label %1d Pred %.2f NextFromdn %3d %s\n', epinbr, epiindex.PatientNbr(epinbr), ...
            epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), epipred(epinbr), date, partialtxt);
        epinbr = epinbr + 1;
    end

end

% remove surplus rows from tables
epiindex(epinbr:end,:) = [];
epilabl(epinbr:end,:) = [];
epipred(epinbr:end,:) = [];

end
