function [nbatch, validresponse] = selectBatchNbr(type, minbatch, maxbatch)

% selectBatchNbr - select the batch nbr to start or end at

snbatch = input(sprintf('Choose batch number to %s at (%d-%d)? ', type, minbatch, maxbatch), 's');

nbatch = str2double(snbatch);

if (isnan(nbatch) || nbatch < minbatch || nbatch > maxbatch)
    fprintf('Invalid choice\n');
    validresponse = false;
    nbatch = 0;
else
    validresponse = true;
end

end

