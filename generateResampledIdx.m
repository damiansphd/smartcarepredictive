function [sampleidx] = generateResampledIdx(nexamples, samplesize)

% generateResampledIdx - generates an index vector using random resampling

sampleidx = randsample(nexamples, samplesize, 'true');

end

