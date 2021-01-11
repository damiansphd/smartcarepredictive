function [qcdrmp] = cycleMPArray(qcdrmp)

% cycleMPArray - cycles the missingness pattern array one place to the
% right

ncols = size(qcdrmp, 2);

temp = qcdrmp(:, ncols);
qcdrmp(:, 2:ncols) = qcdrmp(:, 1:ncols - 1);
qcdrmp(:, 1) = temp;

end

