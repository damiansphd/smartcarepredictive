function [epiindex, epilabl, epipred] = convertResultsToEpisodesNew(featureindex, labels, pred, epilen)

% convertResultsToEpisodesNew - takes daily labels and predictions and
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
    pnbr     = patients(i);
    pfeat    = featureindex(featureindex.PatientNbr == pnbr, :);
    plabel   = labels(featureindex.PatientNbr == pnbr, :);
    ppred    = pred(featureindex.PatientNbr == pnbr, :);
    
    pdiff    = [1; diff(pfeat.CalcDatedn)];
    
    date    = min(pfeat.CalcDatedn);
    maxdate = max(pfeat.CalcDatedn);
    study   = pfeat.Study{pfeat.CalcDatedn == date};
    id      = pfeat.ID(pfeat.CalcDatedn == date);
    
    
    
    while date <= maxdate
        
        currlabel = plabel(pfeat.CalcDatedn == date);
        if currlabel == 0
            nextlabel = 1;
        else
            nextlabel = 0;
        end
        
        nextlabelchgidx = find(plabel == nextlabel & pfeat.CalcDatedn >= date, 1, 'first');
        if size(nextlabelchgidx, 1) == 0
            nextlabelchgidx = size(pfeat, 1);
        end
        nexttreatidx    = find(pdiff  ~= 1         & pfeat.CalcDatedn >  date, 1, 'first');
        if size(nexttreatidx, 1) == 0
            nexttreatidx = size(pfeat, 1);
        end
        nextidx = min(nextlabelchgidx, nexttreatidx);
        
        if size(nextidx, 1) == 0 || nextidx == size(pfeat, 1)
            % if no label change over whole patient study period, set block
            % end date to be maxdate
            blockenddt = maxdate;
        else
            % else set the block end date to the date of the row in feature
            % index prior to the label change
            blockenddt  = pfeat.CalcDatedn(nextidx - 1);
        end
        
        % false label block
        if currlabel == 0
            
            while date <= blockenddt
            
                % create episode index entry
                epiindex.EpiNbr(epinbr)     = epinbr;
                epiindex.PatientNbr(epinbr) = pnbr;
                epiindex.Study{epinbr}      = study;
                epiindex.ID(epinbr)         = id;
                epiindex.FromDate(epinbr)   = pfeat.CalcDate(pfeat.CalcDatedn == date);
                epiindex.Fromdn(epinbr)     = date;
            
                epienddt = min(date + epilen - 1, blockenddt);
                epiindex.ToDate(epinbr)     = max(pfeat.CalcDate(pfeat.CalcDatedn <= epienddt));
                epiindex.Todn(epinbr)       = epienddt;
                epiindex.Length(epinbr)     = epienddt - date + 1;
                if epiindex.Length(epinbr) < epilen
                    epiindex.PartialPeriod(epinbr) = 1;
                    partialtxt = '****';     
                else
                    epiindex.PartialPeriod(epinbr) = 0;
                    partialtxt = '';
                end
                % create episode label entry
                epilabl(epinbr) = 0;
                % create episode prediction entry
                epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt));
                
                date = min(pfeat.CalcDatedn(pfeat.CalcDatedn > epiindex.Todn(epinbr)));
                %fprintf('EpiNbr %3d: PatNbr %3d Fromdn %3d, Todn %3d, Length %2d Label %1d Pred %.2f NextFromdn %3d %s\n', epinbr, epiindex.PatientNbr(epinbr), ...
                %        epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), epipred(epinbr), date, partialtxt);
                epinbr = epinbr + 1;
                
            end
            
        else % true label block
            
            % create episode index entry
            epiindex.EpiNbr(epinbr)     = epinbr;
            epiindex.PatientNbr(epinbr) = pnbr;
            epiindex.Study{epinbr}      = study;
            epiindex.ID(epinbr)         = id;
            epiindex.FromDate(epinbr)   = pfeat.CalcDate(pfeat.CalcDatedn == date);
            epiindex.Fromdn(epinbr)     = date;
            
            epiindex.ToDate(epinbr)     = max(pfeat.CalcDate(pfeat.CalcDatedn <= blockenddt));
            epiindex.Todn(epinbr)       = blockenddt;
            epiindex.Length(epinbr)     = blockenddt - date + 1;
            
            epiindex.PartialPeriod(epinbr) = 0;
            partialtxt = '';
            
            % create episode label entry
            epilabl(epinbr) = 1;
            % create episode prediction entry
            epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= blockenddt));
            
            date = min(pfeat.CalcDatedn(pfeat.CalcDatedn > epiindex.Todn(epinbr)));
            %fprintf('EpiNbr %3d: PatNbr %3d Fromdn %3d, Todn %3d, Length %2d Label %1d Pred %.2f NextFromdn %3d %s\n', epinbr, epiindex.PatientNbr(epinbr), ...
            %        epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), epipred(epinbr), date, partialtxt);
            epinbr = epinbr + 1;
        end
    end
    
end

% remove surplus rows from tables
epiindex(epinbr:end,:) = [];
epilabl(epinbr:end,:) = [];
epipred(epinbr:end,:) = [];

end
