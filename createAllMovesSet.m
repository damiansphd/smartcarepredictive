function [mvsetindex, mvsetmp3D] = createAllMovesSet(currmp3D, nrawmeas, mpdur, iteration)

% createAllMovesSet - function that takes a missingness pattern and creates
% a move set of all possible moves from this pattern

% Move Type 1: Flip point to missing
movetype = 1;
movedesc = setMoveDescForType(movetype);

mprow = reshape(currmp3D, [nrawmeas, mpdur]);
mprow = reshape(mprow', [1, nrawmeas * mpdur]);

%mprow = reshape(currmp3D, [1, nrawmeas * mpdur]);
datapts = find(~mprow);
nmoves = size(datapts, 2);

mvsetindex = createQCDRTables(nmoves);
mvsetmp3D  = zeros(nmoves, nrawmeas, mpdur);

for m = 1:nmoves

    mvsetindex.Iteration(m)    = iteration;
    mvsetindex.MoveType(m)     = movetype;
    mvsetindex.MoveDesc{m}     = movedesc;
    mvsetindex.Measure(m)      = ceil(datapts(m)/mpdur);
%   mvsetindex.MPIndex(m)      = mod(datapts(m) - 1, mpdur) + 1;
    mvsetindex.MPIndex(m)      = datapts(m);
    mvsetindex.SelPred(m)      = 0;
    mvsetindex.MoveAccepted(m) = false;
    
    mvsetmp3D(m, :, :)  = applyMove(currmp3D, movetype, datapts(m), nrawmeas, mpdur);

end
    
% Move Type 2: Shift point to the left



% Move Type 3: Shift point to the right



% Move Type 4: Flip point to present


end

