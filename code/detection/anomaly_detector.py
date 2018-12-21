import numpy as np
from sklearn.ensemble import IsolationForest


def score_anomaly(data, K=1, N=480, num_trees=100):
    """ Anomaly detection on multi-dimensional time series using Isolation
    Forest.
    :param data: (np.array) T*F array of sensor readings where T = # time
    steps and F = # features.
    :param K: (int) shingle size; isolation forest learns the joint
    distribution of K consecutive values of time series (i.e., moving window
    of size K). Usually small, like 3-5.
    :param N: (int) training period; isolation forest is constructed based on
    the first N shingles. Usually, 256.
    :param num_trees: (int) number of trees in the isolation forest. Usually,
    50 or 100.
    :return: (np.array) T*1 array of anomaly scores (higher => anomalous),
    where the first K values are zero (as these shingles are not well-defined).
    """
    T, F = data.shape

    print 'T=', T, 'F=', F

    # shingle sensor readings
    shingled_data = np.zeros((T - K, F * K))
    for i in range(K):
        shingled_data[:, i*F:(i+1)*F] = data[i:T - K + i, :]

    # find shingle indices containing nan and not containing nan
    shingle_contains_nan = np.any(np.isnan(shingled_data), axis=1)
    num_shingles = shingled_data.shape[0]
    indices_not_nan = np.where(np.logical_not(shingle_contains_nan))[0]

    # training and testing data not containing nan. Note that testing data
    # includes training data as well.
    train_samples = shingled_data[indices_not_nan[:N], :]
    test_samples = shingled_data[indices_not_nan, :]

    # run isolation forest on non-nan shingles
    forest = IsolationForest(n_estimators=num_trees, random_state=0)
    forest.fit(train_samples)
    anomaly_scores_not_nan = - forest.decision_function(test_samples)

    # create anomaly scores vector, NaN values get score zero (lowest).
    anomaly_scores = np.zeros(num_shingles)
    anomaly_scores[indices_not_nan] = anomaly_scores_not_nan
    return np.hstack((np.zeros((K-1,)), anomaly_scores))


def evaluate(anomaly_scores, labels, rank, K):
    """ Evaluate
    :param anomaly_scores: (np.array) T*1 time series of anomaly scores (
    higher => anomalous).
    :param labels: (np.array) T*1 time series of ground truth labels. A
    non-zero value indicates time stamp is anomalous.
    :param rank: (int) rank threshold to compute recall and precision at.
    :return: (float, float, np.array) tuple of precision, recall and
    top 'rank' anomalous time stamps.
    """
    T = len(anomaly_scores)
    # label a shingle as anomalous if it contains any value which is anomalous.
    shingled_labels = np.array(
        [np.sum(labels[max(0, t-K+1):t+1]) for t in range(T)]
    )

    anomalous_time_stamps = np.argsort(anomaly_scores)[-rank:]
    verify = np.zeros((T,))
    for t in anomalous_time_stamps:
        verify[t] = 1 if shingled_labels[t] > 0 else -1
    precision_at_rank = float(np.sum(verify == 1)) / rank
    recall_at_rank = float(np.sum(verify == 1)) / np.sum(shingled_labels>0)
    return precision_at_rank, recall_at_rank, np.sort(anomalous_time_stamps)


if __name__ == '__main__':
    data = np.loadtxt("/Users/bryanhooi/Desktop/bryan-papers/power/dynamic/temp/Xsensors.csv", delimiter=",")
    res = score_anomaly(data)
    np.savetxt("/Users/bryanhooi/Desktop/bryan-papers/power/dynamic/temp/forest_out.csv", res, delimiter=",")
