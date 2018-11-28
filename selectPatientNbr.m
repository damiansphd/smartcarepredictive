function [pnbr, validresponse] = selectPatientNbr(patientnbrlist)

% selectPatientNbr - select a single patient nbr from all patients

spnbr = input('Choose patient nbr ? ', 's');
pnbr = str2double(spnbr);
if (isnan(pnbr) || pnbr < min(patientnbrlist) || pnbr > max(patientnbrlist))
    fprintf('Invalid choice\n');
    pnbr = 0;
    validresponse = false;
else
    validresponse = true;
end

end

