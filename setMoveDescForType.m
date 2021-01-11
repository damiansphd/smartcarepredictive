function movedescription = setMoveDescForType(movetype)

% setMoveDescForType - sets the move description for a given move type

switch movetype
    case 0
        movedescription = 'Baseline';
    case 1
        movedescription = 'Flip Point to Missing';
    otherwise
        movedescription = 'Unknown';
end

end

