function movedescription = setMoveDescForType(movetype)

% setMoveDescForType - sets the move description for a given move type

switch movetype
    case 0
        movedescription = 'Baseline';
    case 1
        movedescription = 'Flip Point to Missing';
    case 2
        movedescription = 'Shift point to the left';
    case 3
        movedescription = 'Shift point to the right';
    case 4
        movedescription = 'Flip Point to Present';
    case 5
        movedescription = 'Flip Points to Missing for all measures';
    otherwise
        movedescription = 'Unknown';
end

end

