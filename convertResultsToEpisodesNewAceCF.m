function [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNewAceCF(featureindexwithsig, labels, pred, epilen, safedayidx)

% convertResultsToEpisodesNew - takes daily labels and predictions and
% converts them to episodes

% create enough space for the results with room to spare
bufferrows = round((size(featureindexwithsig, 1) / epilen) * 1.5);

epiindex = table('Size',[bufferrows, 14], ...
    'VariableTypes', {'double', 'double',     'cell',  'double', 'datetime', 'datetime', 'double', 'double', 'double', 'double',        'double',   'cell',        'double', 'double'}, ...
    'VariableNames', {'EpiNbr', 'PatientNbr', 'Study', 'ID',     'FromDate', 'ToDate',   'Fromdn', 'Todn',   'Length', 'PartialPeriod', 'SafeDays', 'SignalState', 'Pred',   'Label'});

epilabl    = zeros(bufferrows, 1);
epipred    = zeros(bufferrows, 1);
episafeidx = false(bufferrows, 1);

actualscentype = 0;
episafedaythresh = 0.375;

epinbr = 1;
patients = unique(featureindexwithsig.PatientNbr);
for i = 1:size(patients, 1)
    pnbr        = patients(i);
    pfidx       = featureindexwithsig.PatientNbr == pnbr & featureindexwithsig.ScenType == actualscentype;
    pfeat       = featureindexwithsig(pfidx, :);
    plabel      = labels(pfidx, :);
    ppred       = pred(pfidx, :);
    psafedayidx = safedayidx(pfidx, :);
    
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
            nextlblfnd      = false;
            nextlabelchgidx = size(pfeat, 1);
        else
            nextlblfnd      = true; 
        end
        
        nexttreatidx    = find(pdiff  ~= 1         & pfeat.CalcDatedn >  date, 1, 'first');
        if size(nexttreatidx, 1) == 0
            nexttreatfnd    = false;
            nexttreatidx = size(pfeat, 1);
        else
            nexttreatfnd    = true;
        end
        
        nextfnd = nextlblfnd || nexttreatfnd;
        nextidx = min(nextlabelchgidx, nexttreatidx);
        
        %if size(nextidx, 1) == 0 || nextidx == size(pfeat, 1)
        if ~nextfnd && nextidx == size(pfeat, 1)
            % if no label change or next treatment over the remaining study period, set block
            % end date to be maxdate
            blockenddt = maxdate;
        %elseif nextfnd && nextidx == size(pfeat, 1)
            % if there is either a label change or next treatment in the remaining study period 
            %but on the last measurement day, set block end date to be maxdate
            
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
                epiindex.SafeDays(epinbr) = sum(psafedayidx(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt));
                
                % create episode label entry
                epilabl(epinbr) = 0;
                epiindex.Label(epinbr) = 0;

                % create episode prediction entry
                epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt));

                % create episode safe index entry - for negative label episodes (eg stable period), 
                % need at least 37.5% of the days to be safe for the episode
                episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= ceil((epiindex.Length(epinbr) * episafedaythresh));

                % set episodic signal state
                if ~episafeidx(epinbr)
                    epiindex.SignalState{epinbr} = 'White';
                    epiindex.Pred(epinbr)        = -1.0;
                else
                    if any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Red'}))
                        epiindex.SignalState{epinbr} = 'Red';
                        epiindex.Pred(epinbr)        = 1.0;
                    elseif any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Amber'}))
                        epiindex.SignalState{epinbr} = 'Amber';
                        epiindex.Pred(epinbr)        = 0.5;
                    elseif any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Green'}))
                        epiindex.SignalState{epinbr} = 'Green';
                        epiindex.Pred(epinbr)        = 0.0;
                    else
                        epiindex.SignalState{epinbr} = 'White';
                        epiindex.Pred(epinbr)        = -1.0;
                    end
                end

                date = min(pfeat.CalcDatedn(pfeat.CalcDatedn > epiindex.Todn(epinbr)));
                %fprintf('EpiNbr %4d: PatNbr %3d Fromdn %3d, Todn %3d, Length %2d Label %1d Pred %5.2f NextFromdn %3d SafeDays %2d SignalState %6s %s\n', ...
                %            epinbr, epiindex.PatientNbr(epinbr), epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), ...
                %            epipred(epinbr), date, epiindex.SafeDays(epinbr), epiindex.SignalState{epinbr}, partialtxt);
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
            
            epienddt                    = blockenddt;
            epiindex.ToDate(epinbr)     = max(pfeat.CalcDate(pfeat.CalcDatedn <= blockenddt));
            epiindex.Todn(epinbr)       = blockenddt;
            epiindex.Length(epinbr)     = blockenddt - date + 1;
            
            epiindex.PartialPeriod(epinbr) = 0;
            partialtxt = '';

            epiindex.SafeDays(epinbr) = sum(psafedayidx(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= blockenddt));
            
            % create episode label entry
            epilabl(epinbr) = 1;
            epiindex.Label(epinbr) = 1;

            % create episode prediction entry
            epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= blockenddt));
            
            % create episode safe index entry - for positive label episodes (eg unstable period),  
            % technically only need 1 safe day to trigger the episode, but also want a representative 
            % number of safe days to avoid skewing our episodic quality scores too much based on a very
            % low number of safe day predictions - use 37.5% as the
            % threshold.
            episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= ceil((epiindex.Length(epinbr) * episafedaythresh));

            % set episodic signal state
            if ~episafeidx(epinbr)
                epiindex.SignalState{epinbr} = 'White';
                epiindex.Pred(epinbr)        = -1.0;
            else
                if any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Red'}))
                    epiindex.SignalState{epinbr} = 'Red';
                    epiindex.Pred(epinbr)        = 1.0;
                elseif any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Amber'}))
                    epiindex.SignalState{epinbr} = 'Amber';
                    epiindex.Pred(epinbr)        = 0.5;
                elseif any(ismember(pfeat.SignalState(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt), {'Green'}))
                    epiindex.SignalState{epinbr} = 'Green';
                    epiindex.Pred(epinbr)        = 0.0;
                else
                    epiindex.SignalState{epinbr} = 'White';
                    epiindex.Pred(epinbr)        = -1.0;
                end
            end

            date = min(pfeat.CalcDatedn(pfeat.CalcDatedn > epiindex.Todn(epinbr)));
            fprintf('EpiNbr %4d: PatNbr %3d Fromdn %3d, Todn %3d, Length %2d Label %1d Pred %5.2f NextFromdn %3d SafeDays %2d SignalState %6s %s\n', ...
                        epinbr, epiindex.PatientNbr(epinbr), epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), ...
                        epipred(epinbr), date, epiindex.SafeDays(epinbr), epiindex.SignalState{epinbr}, partialtxt);
            epinbr = epinbr + 1;
        end
    end
    
end

% remove surplus rows from tables
epiindex(epinbr:end,:)   = [];
epilabl(epinbr:end,:)    = [];
epipred(epinbr:end,:)    = [];
episafeidx(epinbr:end,:) = [];

end
