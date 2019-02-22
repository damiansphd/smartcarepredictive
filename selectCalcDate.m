function [calcdate, validresponse] = selectCalcDate(minpcalcdate, maxpcalcdate)

% selectPatientNbr - select a single patient nbr from all patients

scalcdate = input(sprintf('Choose calc datenum (%d-%d) ? ', minpcalcdate, maxpcalcdate), 's');
calcdate = str2double(scalcdate);
if (isnan(calcdate) || calcdate < minpcalcdate || calcdate > maxpcalcdate)
    fprintf('Invalid choice\n');
    calcdate = 0;
    validresponse = false;
else
    validresponse = true;
end

end

