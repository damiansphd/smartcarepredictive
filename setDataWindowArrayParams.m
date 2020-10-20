function [datawinduration, normwinduration, totalduration] = ...
                            setDataWindowArrayParams(datawinparamsrow)

% setDataWindowArrayParams - sets the normalisation and data windows, along
% with total duration

datawinduration = datawinparamsrow.datawinduration;
normwinduration = datawinparamsrow.normwinduration;
totalduration   = datawinduration + normwinduration;

end

