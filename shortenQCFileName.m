function modresfile = shortenQCFileName(modresfile, hpqs)

% shortenQCFileName - shortens the model results file name to avoid
% OneDrive max path length errors for Quality Classifier work

modresfile = strrep(modresfile, sprintf('lr%.2f-%.2f', hpqs.LearnRate,        hpqs.LearnRate),        sprintf('lr%.2f', hpqs.LearnRate));
modresfile = strrep(modresfile, sprintf('nt%d-%d',     hpqs.NumTrees,         hpqs.NumTrees),         sprintf('nt%d',   hpqs.NumTrees));
modresfile = strrep(modresfile, sprintf('ml%d-%d',     hpqs.MinLeafSize,      hpqs.MinLeafSize),      sprintf('ml%d',   hpqs.MinLeafSize));
modresfile = strrep(modresfile, sprintf('ns%d-%d',     hpqs.MaxNumSplit,      hpqs.LearnRate),        sprintf('ns%d',   hpqs.MaxNumSplit));
modresfile = strrep(modresfile, sprintf('fv%.2f-%.2f', hpqs.FracVarsToSample, hpqs.FracVarsToSample), sprintf('fv%.2f', hpqs.FracVarsToSample));

end

