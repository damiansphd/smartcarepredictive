function [mpindexrow, mp3D, mpdur, iscyclic, cyclicdur] = setMPAllMeasFromExcel(mptablerow, nrawmeas, dwdur)

% setMPAllMeasFromExcel - function to create an mpindex row and an mp3D array from
% a missingness pattern in a file. This assumes a 1D missingness pattern
% that is applied equally to all measures.


[mpindexrow] = createQCDRTables(1);

mparrayrow = logical(table2array(mptablerow));

mpindexrow.MoveDesc{1} = num2str(~mparrayrow);
mpindexrow.ShortName{1} = 'All';

mpdur = size(mparrayrow, 2);

mp3D = zeros(1, nrawmeas, mpdur);

mp3D(:, :, mparrayrow) = 1;

if mpdur < dwdur
    iscyclic  = 'Y';
    cyclicdur = mpdur;
else
    iscyclic  = 'N';
    cyclicdur = 1;
end

end

