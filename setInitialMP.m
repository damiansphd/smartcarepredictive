function [qcdrindexrow, qcdrmp3D] = setInitialMP(mpstartex, pmMissPattArray, nrawmeas, mpdur, dwdur, iteration)

% setInitialMP - sets the initial missingness pattern

[qcdrindexrow] = createQCDRTables(1);

qcdrindexrow.Iteration = iteration;
qcdrindexrow.MoveType  = 0;
qcdrindexrow.MoveDesc{1} = setMoveDescForType(qcdrindexrow.MoveType);
qcdrindexrow.ShortName{1} = 'N/A';

if mpstartex == 0
    % start pattern is no missingness - i.e. all zeros in missingness
    % pattern
    qcdrmp3D = zeros(1, nrawmeas, mpdur);
else
    % start pattern is the rightmost end of a true positive Missingness
    % Pattern, of width = missing pattern width
    tempmp = reshape(pmMissPattArray(mpstartex, :), [dwdur, nrawmeas])';
    qcdrmp3D(1, :, :) = tempmp(:, (dwdur - mpdur + 1):dwdur);
end

end

