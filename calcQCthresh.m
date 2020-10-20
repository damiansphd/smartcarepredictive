function [baselineqsthresh] = calcQCthresh(baselineqs, threshold)

% calcQCthresh - calculates the operating threshold for the quality
% classifier - used to divide the labels into true and false

baselineqsthresh = baselineqs * threshold;

end

