% debugging rank deficient feature matrix
% example for patient 59, first calc date (25), fd 25

pmInterpNormcube(p, 1:25, 1)
reshape(pmNormFeatures(6984,1:150),[6,25])'

pmInterpNormcube(p, 1:25, 2)
reshape(pmNormFeatures(6984,151:300),[6,25])'

pmInterpNormcube(p, 1:25, 3)
reshape(pmNormFeatures(6984,301:450),[6,25])'


ntilepoints =

   -1.3476   -0.8857   -0.4299    0.0140    0.6398   16.2660
   -3.7570   -0.6191    0.0085    0.0085    0.6360    1.8912
   -2.0843   -0.9538   -0.4399    0.1253    0.7933    3.1571
   -6.7196   -0.7818   -0.2109    0.4362    1.0452    1.9587
   -2.5581   -0.8444   -0.2961    0.1838    0.8692    4.6393
   -1.6038   -0.5469   -0.2449    0.5100    0.5100    1.5669
   -3.9682         0         0         0         0    5.1583
   -2.3032   -0.8136   -0.4073    0.0917    0.7089    4.6880
   -3.9695   -0.7007   -0.0469   -0.0469    0.6069    1.9144