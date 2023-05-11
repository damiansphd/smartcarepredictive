testsetexac = pmAMPred(ismember(pmAMPred.PatientNbr, pmPatients.PatientNbr(ismember(pmPatients.PatientNbr, ...
    pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr==5)) & pmPatients.RelLastMeasdn >50)), :);

testsetpats = pmPatients(ismember(pmPatients.PatientNbr, pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr==5)) & pmPatients.RelLastMeasdn >50,:);

testsetpats(~ismember(testsetpats.PatientNbr, testsetexac.PatientNbr),:)
testsetexac(testsetexac.Offset < 23, :)