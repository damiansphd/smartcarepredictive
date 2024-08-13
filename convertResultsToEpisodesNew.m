function [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(featureindex, labels, pred, epilen, safedayidx)

% convertResultsToEpisodesNew - takes daily labels and predictions and
% converts them to episodes

% create enough space for the results with room to spare
bufferrows = round((size(featureindex, 1) / epilen) * 1.5);

epiindex = table('Size',[bufferrows, 11], ...
    'VariableTypes', {'double', 'double',     'cell',  'double', 'datetime', 'datetime', 'double', 'double', 'double', 'double',        'double'}, ...
    'VariableNames', {'EpiNbr', 'PatientNbr', 'Study', 'ID',     'FromDate', 'ToDate',   'Fromdn', 'Todn',   'Length', 'PartialPeriod', 'SafeDays'});

epilabl    = zeros(bufferrows, 1);
epipred    = zeros(bufferrows, 1);
episafeidx = false(bufferrows, 1);

actualscentype = 0;

epinbr = 1;
patients = unique(featureindex.PatientNbr);
for i = 1:size(patients, 1)
    pnbr        = patients(i);
    pfidx       = featureindex.PatientNbr == pnbr & featureindex.ScenType == actualscentype;
    pfeat       = featureindex(pfidx, :);
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
                    %partialtxt = '****';     
                else
                    epiindex.PartialPeriod(epinbr) = 0;
                    %partialtxt = '';
                end
                epiindex.SafeDays(epinbr) = sum(psafedayidx(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt));
                
                % create episode label entry
                epilabl(epinbr) = 0;
                % create episode prediction entry
                epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= epienddt));
                % create episode safe index entry - for negative label episodes (eg stable period), 
                % need at least 33% of the days to be safe for the episode
                episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= ceil((epiindex.Length(epinbr) / 3));
                
                % to also be safe (eg at least 3of7 days, 3of6, 2of5, 2of4, 1of3, 1of2, 1of1 etc
                %if epiindex.Length(epinbr) >= 1 && epiindex.Length(epinbr) <= 3
                %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 1;
                %elseif epiindex.Length(epinbr) >= 4 && epiindex.Length(epinbr) <= 5
                %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 2;
                %elseif epiindex.Length(epinbr) >= 6 && epiindex.Length(epinbr) <= 7
                %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 3;
                %else
                %    fprintf('**** unexpected stable episode length (>7 days) ****\n');
                %end
                
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
            epiindex.SafeDays(epinbr) = sum(psafedayidx(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= blockenddt));
            
            % create episode label entry
            epilabl(epinbr) = 1;
            % create episode prediction entry
            epipred(epinbr) = max(ppred(pfeat.CalcDatedn >= date & pfeat.CalcDatedn <= blockenddt));
            % create episode safe index entry - for positive label episodes (eg unstable period), 
            % just need at least one safe day for the episode to also be ok
            episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 1;
            
            % create episode safe index entry - for positive label episodes (eg unstable period),  
            % technically only need 1 safe day to trigger the episode, but also want a representative 
            % number of safe days to avoid skewing our episodic quality scores too much based on a very
            % low number of safe day predictions - use 33.33% as the
            % threshold.
            episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= ceil((epiindex.Length(epinbr) / 3));
            
            %if epiindex.Length(epinbr) >= 1 && epiindex.Length(epinbr) <= 3
            %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 1;
            %elseif epiindex.Length(epinbr) >= 4 && epiindex.Length(epinbr) <= 5
            %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 2;
            %elseif epiindex.Length(epinbr) >= 6 && epiindex.Length(epinbr) <= 9
            %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= 3;
            %else
            %    % episodes > 9 days, have >= 33% safe day requirement
            %    episafeidx(epinbr) = epiindex.SafeDays(epinbr) >= ceil((epiindex.Length(epinbr) / 3));
            %end
            
            date = min(pfeat.CalcDatedn(pfeat.CalcDatedn > epiindex.Todn(epinbr)));
            %partialtxt = '';
            %fprintf('EpiNbr %3d: PatNbr %3d Fromdn %3d, Todn %3d, Length %2d Label %1d Pred %.2f NextFromdn %3d %s\n', epinbr, epiindex.PatientNbr(epinbr), ...
            %        epiindex.Fromdn(epinbr), epiindex.Todn(epinbr), epiindex.Length(epinbr), epilabl(epinbr), epipred(epinbr), date, partialtxt);
            epinbr = epinbr + 1;
        end
    end
    
end

% remove surplus rows from tables
epiindex(epinbr:end,:)   = [];
epilabl(epinbr:end,:)    = [];
epipred(epinbr:end,:)    = [];
episafeidx(epinbr:end,:) = [];

% possibly filter by safe index before returning episodic arrays - I think
% the only way to get the sorted prod/label arrays correct.
% or alternatively don't return sorted arrays and calculate them when
% needed (based on just safe days at that point).

%[epipredsort, sortidx] = sort(epipred, 'descend');
%epilablsort = epilabl(sortidx);

end
