function [pmVolWinArray, totalvolwin] = createVolWinArray(datawinarray, nexamples, totalwin, nmeasures)

% createVolWinArray - function to create the Volatility window array based on the
% data window array (using only the values in the data window

totalvolwin = totalwin - 1;
pmVolWinArray = zeros(nexamples, totalvolwin, nmeasures);

for m = 1:nmeasures
        mrawfeats = datawinarray(:, :, m);
        mvolfeats = abs(diff(mrawfeats, 1, 2));
        pmVolWinArray(:, :, m) = mvolfeats;
end

fprintf('\n');

end


