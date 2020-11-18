function [pct, validresponse] = selectThreshPercentage(type, minthresh, maxthresh)

% selectTheshPercentage - select the percentage for the label threshold

spct = input(sprintf('Choose %s theshold percentage (%d-%d)? ', type, minthresh, maxthresh), 's');

pct = str2double(spct);

if (isnan(pct) || pct < minthresh || pct > maxthresh)
    fprintf('Invalid choice\n');
    validresponse = false;
    pct = 0;
else
    validresponse = true;
end

end

