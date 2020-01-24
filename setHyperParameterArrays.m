function [lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs] = setHyperParameterArrays(pmHyperParams)

% setHyperParameterArrays - sets the hyper parameter arrays from the file
% input

if ismember(class(pmHyperParams.LearnRate), 'cell')
    lrarray  = str2num(pmHyperParams.LearnRate{1});
else
    lrarray  = pmHyperParams.LearnRate(1);
end

if ismember(class(pmHyperParams.NumTrees), 'cell')
    ntrarray  = str2num(pmHyperParams.NumTrees{1});
else
    ntrarray  = pmHyperParams.NumTrees(1);
end

if ismember(class(pmHyperParams.MinLeafSize), 'cell')
    mlsarray = str2num(pmHyperParams.MinLeafSize{1});
else
    mlsarray = pmHyperParams.MinLeafSize(1);
end

if ismember(class(pmHyperParams.MaxNumSplit), 'cell')
    mnsarray = str2num(pmHyperParams.MaxNumSplit{1});
else
    mnsarray = pmHyperParams.MaxNumSplit(1);
end

if ismember(class(pmHyperParams.FracVarSel), 'cell')
    fvsarray = str2num(pmHyperParams.FracVarSel{1});
else
    fvsarray = pmHyperParams.FracVarSel(1);
end

nlr  = size(lrarray, 2);
ntr  = size(ntrarray, 2);
nmls = size(mlsarray, 2);
nmns = size(mnsarray, 2);
nfvs = size(fvsarray, 2);

end

