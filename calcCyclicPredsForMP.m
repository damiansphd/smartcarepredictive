function [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
    calcCyclicPredsForMP(qcmdlres, qcmdlver, pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
        qcdrindexrow, qcdrmp, mpdur, dwdur, nrawmeas, cyclicdur, iscyclic, qcopthres)

% calcCyclicPredsForMP - run the quality classifier for a given
% missingness pattern and all cyclic versions and returns the results
% appended to the tables/arrays.

qcmdl = qcmdlres.Folds(1).Model;
qcdrcycpredrow = zeros(1, cyclicdur);
qcdrmp2D = reshape(qcdrmp, [nrawmeas, mpdur]);

% add fprintf to show progress

for c = 1:cyclicdur
    
    % cycle the missingness pattern array and recreate features
    if iscyclic == 'Y'
        [qcdrmp2D] = cycleMPArray(qcdrmp2D);
    end
    [qcdrdw2D] = convertMPtoDW(qcdrmp2D, mpdur, dwdur);
    [qcdrfeatrow] = convertDWtoFeatures(qcdrdw2D, nrawmeas, dwdur);
    
    % get prediction for featrow
    if ismember(qcmdlver, {'vPM1'})
        qcdrcycpredrow(c) = predict(qcmdl, qcdrfeatrow);
    else    
        [~, tempscore] = predict(qcmdl, qcdrfeatrow);
        tempscore      = tempscore ./ sum(tempscore, 2);
        qcdrcycpredrow(c) = tempscore(:, 2);
    end

end

qcdrindexrow.SelPred = min(qcdrcycpredrow);
if qcdrindexrow.SelPred < qcopthres
    qcdrindexrow.MoveAccepted = false;
else
    qcdrindexrow.MoveAccepted = true;
end

[pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
        addQCDRRows(pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
            qcdrindexrow, reshape(qcdrmp2D, [1, nrawmeas, mpdur]), reshape(qcdrdw2D, [1, nrawmeas, dwdur]), qcdrfeatrow, qcdrcycpredrow);
            

end

