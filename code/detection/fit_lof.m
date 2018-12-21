function scores = fit_lof(Xsensors)
addpath OutlierDetectionToolbox-master/lof

dataset.trainx = Xsensors;
dataset.testx = Xsensors;

params.minptslb = 20;
params.minptsub = 20;
params.theta = 0;

result = LocalOutlierFactor(dataset, params);
scores = result.lof;