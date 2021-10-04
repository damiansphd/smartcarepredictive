function [mpindexrow, mp3D, mpdur, iscyclic, cyclicdur] = setMPOneMeasFromExcel(mptablerow, measures, m, nrawmeas, dwdur)

% setMPOneMeasFromExcel - function to create an mpindex row and an mp3D array from
% a missingness pattern in a file. This applies the missingness pattern for
% one measure (the measure index is passed in as a parameter).

[mpindexrow] = createQCDRTables(1);

mparrayrow = logical(table2array(mptablerow));

mpindexrow.MoveDesc{1} = num2str(~mparrayrow);
mpindexrow.Measure(1) = m;
mpindexrow.ShortName(1) = measures.ShortName(m);

mpdur = size(mparrayrow, 2);

mp3D = zeros(1, nrawmeas, mpdur);

mp3D(:, m, mparrayrow) = 1;

if mpdur < dwdur
    iscyclic  = 'Y';
    cyclicdur = mpdur;
else
    iscyclic  = 'N';
    cyclicdur = 1;
end

end

