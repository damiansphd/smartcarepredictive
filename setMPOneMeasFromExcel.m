function [mpindexrow, mp3D, mpdur, iscyclic, cyclicdur] = setMPOneMeasFromExcel(mptablerow, measures, m, nrawmeas, dwdur, mpmeasmode)

% setMPOneMeasFromExcel - function to create an mpindex row and an mp3D array from
% a missingness pattern in a file. This applies the missingness pattern for
% one measure (the measure index is passed in as a parameter).

[mpindexrow] = createQCDRTables(1);

mparrayrow = logical(table2array(mptablerow));

mpdur = size(mparrayrow, 2);

if mpmeasmode == 2
    mpindexrow.MoveDesc{1} = num2str(~mparrayrow);
    mp3D = zeros(1, nrawmeas, mpdur);
    mp3D(:, m, mparrayrow) = 1;
elseif mpmeasmode == 3
    mpindexrow.MoveDesc{1} = num2str(~mparrayrow);
    mp3D = ones(1, nrawmeas, mpdur);
    mp3D(:, m, ~mparrayrow) = 0;
end
mpindexrow.Measure(1) = m;
mpindexrow.ShortName(1) = measures.ShortName(m);

if mpdur < dwdur
    iscyclic  = 'Y';
    cyclicdur = mpdur;
else
    iscyclic  = 'N';
    cyclicdur = 1;
end

end

