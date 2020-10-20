function [pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats] ...
            = createModelFeatureArrays(nexamples, nmeasures, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures)
    
pmMuIndex         = zeros(nexamples, nmeasures);
pmSigmaIndex      = zeros(nexamples, nmeasures);

pmRawMeasFeats   = zeros(nexamples, nrawfeatures);
pmMSFeats        = zeros(nexamples, nmsfeatures);
pmVolFeats       = zeros(nexamples, nvolfeatures);
pmPMeanFeats     = zeros(nexamples, npmeanfeatures);

end

