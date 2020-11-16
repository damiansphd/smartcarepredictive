function [datawinduration, nrawmeasures, nmsmeasures, nvolmeasures, npmeanmeasures, ...
          nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures, ...
          nfeatures, nnormfeatures] = setDWNumMeasAndFeatures(featureparamsrow, measures, nmeasures)

% setDWNumMeasAndFeatures - sets the number of measures and features for a
% given parameter combination

datawinduration    = featureparamsrow.datawinduration;

nrawmeasures       = sum(measures.RawMeas);
nmsmeasures        = sum(measures.MSMeas);
nvolmeasures       = sum(measures.Volatility);
npmeanmeasures     = sum(measures.PMean);

nrawfeatures       = nrawmeasures * datawinduration;
nmsfeatures        = nmsmeasures * datawinduration;
nvolfeatures       = nvolmeasures * (datawinduration - 1);
npmeanfeatures     = npmeanmeasures;

nfeatures       = nmeasures * datawinduration;
nnormfeatures   = nrawfeatures + nmsfeatures + nvolfeatures + ...
                  npmeanfeatures;
              
end


