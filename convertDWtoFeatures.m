function [qcdrfeatrow] = convertDWtoFeatures(qcdrdw, nrawmeas, dwdur)

% convertDWtoFeatures - converts the datawindow by measure to a feature row

qcdrfeatrow = reshape(qcdrdw', [1, nrawmeas * dwdur]);

end

