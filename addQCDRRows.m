function [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
            addQCDRRows(pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
                qcdrindexrow, qcdrmp3D, qcdrdw3D, qcdrfeatrow, qcdrcycpredrow)

% addQCDRRows - convenience function to add QCDR results to various tables
% and arrays

pmQCDRIndex             = [pmQCDRIndex;      qcdrindexrow];
pmQCDRMissPatt          = [pmQCDRMissPatt;   qcdrmp3D];
pmQCDRDataWin           = [pmQCDRDataWin;    qcdrdw3D];
pmQCDRFeatures          = [pmQCDRFeatures;   qcdrfeatrow];
pmQCDRCyclicPred        = [pmQCDRCyclicPred; qcdrcycpredrow];

end

