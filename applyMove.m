function [qcdrmp3Dupd] = applyMove(qcdrmp, movetype, moveindex, nrawmeas, mpdur)

% applyMove - applies a move to a missingness pattern for various move
% types

% first flatten out the missingness pattern array
temp = reshape(qcdrmp, [nrawmeas, mpdur]);
temp = reshape(temp', [1, nrawmeas * mpdur]);

if movetype == 1 % Flip point to missing
    temp(moveindex) = 1;
else
    % add logic for other move types here
end

qcdrmp3Dupd = reshape(temp, [mpdur, nrawmeas]);
qcdrmp3Dupd = reshape(qcdrmp3Dupd', [1, nrawmeas, mpdur]);

end

