function [pct, validresponse] = selectThreshPercentage()

% selectTheshPercentage - select the percentage for the label threshold

spct = input('Choose theshold percentage (0-100)? ', 's');

pct = str2double(spct);

if (isnan(pct) || pct < 0 || pct > 100)
    fprintf('Invalid choice\n');
    validresponse = false;
    pct = 0;
else
    validresponse = true;
end

end

