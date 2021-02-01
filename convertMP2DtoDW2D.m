function [dw2Dam] = convertMP2DtoDW2D(mp2D, measures, nmeasures, mpdur, dwdur)

% convertMP2DtoDW2D - converts a 2D missing pattern array to a 2D data
% window array (or total window array)

[dw2D] = convertMPtoDW(mp2D, mpdur, dwdur);

% and now explode back out to all measures
dw2Dam = zeros(nmeasures, dwdur);
dw2Dam(logical(measures.RawMeas), :) = dw2D;

end

