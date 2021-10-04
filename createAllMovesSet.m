function [mvsetindex, mvsetmp3D] = createAllMovesSet(currmp3D, qcdrmeasures, nrawmeas, mpdur, iteration, mindatarule)

% createAllMovesSet - function that takes a missingness pattern and creates
% a move set of all possible moves from this pattern

if mindatarule == 1
    % min data rule type == 1, remove points one measure/day at a time
    
    % Move Type 1: Flip point to missing
    movetype = 1;
    movedesc = setMoveDescForType(movetype);

    mprow = reshape(currmp3D, [nrawmeas, mpdur]);
    mprow = reshape(mprow', [1, nrawmeas * mpdur]);

    datapts = find(~mprow);
    nmoves = size(datapts, 2);

    mvsetindex = createQCDRTables(nmoves);
    mvsetmp3D  = zeros(nmoves, nrawmeas, mpdur);

    for m = 1:nmoves

        mvsetindex.Iteration(m)    = iteration;
        mvsetindex.MoveType(m)     = movetype;
        mvsetindex.MoveDesc{m}     = movedesc;
        mvsetindex.Measure(m)      = ceil(datapts(m)/mpdur);
        mvsetindex.ShortName(m)    = qcdrmeasures.ShortName(mvsetindex.Measure(m));
        mvsetindex.MPIndex(m)      = datapts(m);
        mvsetindex.MPRelIndex(m)   = mvsetindex.MPIndex(m) - (mvsetindex.Measure(m) - 1) * mpdur;
        mvsetindex.SelPred(m)      = 0;
        mvsetindex.MoveAccepted(m) = false;

        mvsetmp3D(m, :, :)  = applyMove(currmp3D, movetype, datapts(m), nrawmeas, mpdur, mindatarule);

    end

    % Move Type 2: Shift point to the left


    % Move Type 3: Shift point to the right


    % Move Type 4: Flip point to present

elseif mindatarule == 2
    % min data rule type == 2, remove points all measures per day
    
    % Move Type 5: Flip point to missing (for all measures)
    movetype = 5;
    movedesc = setMoveDescForType(movetype);

    mprow = reshape(currmp3D, [nrawmeas, mpdur]);
    mprow = mprow(1, :);

    datapts = find(~mprow);
    nmoves = size(datapts, 2);

    mvsetindex = createQCDRTables(nmoves);
    mvsetmp3D  = zeros(nmoves, nrawmeas, mpdur);

    for m = 1:nmoves

        mvsetindex.Iteration(m)    = iteration;
        mvsetindex.MoveType(m)     = movetype;
        mvsetindex.MoveDesc{m}     = movedesc;
        mvsetindex.Measure(m)      = 0;
        mvsetindex.ShortName{m}    = 'All';
        mvsetindex.MPIndex(m)      = datapts(m);
        mvsetindex.MPRelIndex(m)   = datapts(m);
        mvsetindex.SelPred(m)      = 0;
        mvsetindex.MoveAccepted(m) = false;

        mvsetmp3D(m, :, :)  = applyMove(currmp3D, movetype, datapts(m), nrawmeas, mpdur, mindatarule);

    end

end

end

