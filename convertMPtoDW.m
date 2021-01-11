function [qcdrdw] = convertMPtoDW(qcdrmp, mpdur, dwdur)

% convertMPtoDW - converts the missing pattern window by measure to a
% datawindow by measure

nrepeats   = ceil(dwdur/mpdur);
remainder = (nrepeats * mpdur) - dwdur;

qcdrdw = repmat(qcdrmp, 1, nrepeats);
qcdrdw = qcdrdw(:, remainder + 1:nrepeats * mpdur);

end

