# dynamic

A paper of this work has been accepted by IEEE transactions on power systems in 2021.

Li, Shimiao, Amritanshu Pandey, Bryan Hooi, Christos Faloutsos, and Larry Pileggi. "Dynamic Graph-Based Anomaly Detection in the Electrical Grid." arXiv preprint arXiv:2012.15006 (2020).

Given sensor readings over time from a power grid, how can we accurately detect when an anomaly occurs? 

A key part of achieving this goal is to use the network of power grid sensors to quickly detect, in real-time, when any unusual events, whether natural faults or malicious, occur on the power grid. 

Existing bad-data detectors in the industry lack the sophistication to robustly detect broad types of anomalies, especially those due to emerging cyber-attacks, since they operate on a single measurement snapshot of the grid at a time. 

New ML methods are more widely applicable, but generally do not consider the impact of topology change on sensor measurements and thus cannot accommodate regular topology adjustments in historical data. 

Hence, we propose DYNWATCH, a domain knowledge based and topology-aware algorithm for anomaly detection using sensors placed on a dynamic grid. This figure briefly shows how it works:

![For anomaly detection at time T+1 on sensor s, we seek to estimate a distribution for its measurements xT+1. Weights w1,w2,...,wT are assigned to its previous data x1,x2,...,xT using our algorithm. The weighted sum is used as the distribution center and an alarm is created if the observation xT+1 deviates from the distribution center by a certain threshold. ](plots/toyexample_dynwatch.png)

Our approach is accurate, outperforming existing approaches by 20% or more (F-measure) in experiments; and fast, averaging less than 1.7ms per time tick per sensor on a 60K+ branch case using a laptop computer, and scaling linearly with the size of the graph.
