function scores = fit_parzen(Xsensors)
addpath OutlierDetectionToolbox-master/parzenWindow
addpath OutlierDetectionToolbox-master/datasets

dataset.trainx = Xsensors;
dataset.testx = Xsensors;
dataset.categoricalVars = [];

params.k = 20;
params.local = 0;
params.theta = 0;

result = ParzenWindowOutlierDetection(dataset, params);
scores = result.yprob;