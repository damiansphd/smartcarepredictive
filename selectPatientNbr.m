function [pnbr, validresponse] = selectPatientNbr(npatients)

% selectPatientNbr - select a single patient nbr from all patients

spnbr = input('Choose patient nbr ? ', 's');
pnbr = str2double(spnbr);
if (isnan(pnbr) || pnbr < 1 || pnbr > npatients)
    fprintf('Invalid choice\n');
    pnbr = 0;
    validresponse = false;
else
    validresponse = true;
end

end

