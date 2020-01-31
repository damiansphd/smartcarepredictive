function [hyperparamqsrow] = setHyperParamQSTreeInfo(hyperparamqsrow, mdlres)

% setHyperParamQSTreeInfo - sets the tree info in the hyper parameter row

ntrees = size(mdlres.Trained, 1);

nodesum  = 0;
nodemax  = 0;
bnodesum = 0;
bnodemax = 0;

for n = 1:ntrees
    nodesum  = nodesum  + mdlres.Trained{n}.NumNodes;
    bnodesum = bnodesum + sum(mdlres.Trained{n}.IsBranchNode);
    if mdlres.Trained{n}.NumNodes > nodemax
        nodemax = mdlres.Trained{n}.NumNodes;
    end
    if sum(mdlres.Trained{n}.IsBranchNode) > bnodemax
        bnodemax = sum(mdlres.Trained{n}.IsBranchNode);
    end
end

hyperparamqsrow.MaxNumNodes    = nodemax;
hyperparamqsrow.AvgNumNodes    = nodesum  / ntrees;
hyperparamqsrow.MaxBranchNodes = bnodemax;
hyperparamqsrow.AvgBranchNodes = bnodesum / ntrees;

end

