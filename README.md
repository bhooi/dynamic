# dynamic

A paper of this work has been accepted by IEEE transactions on power systems in 2021.

Li, Shimiao, Amritanshu Pandey, Bryan Hooi, Christos Faloutsos, and Larry Pileggi. "Dynamic Graph-Based Anomaly Detection in the Electrical Grid." arXiv preprint arXiv:2012.15006 (2020).

Given sensor readings over time from a power grid, how can we accurately detect when an anomaly occurs? 

A key part of achieving this goal is to use the network of power grid sensors to quickly detect, in real-time, when any unusual events, whether natural faults or malicious, occur on the power grid. 

Existing bad-data detectors in the industry lack the sophistication to robustly detect broad types of anomalies, especially those due to emerging cyber-attacks, since they operate on a single measurement snapshot of the grid at a time. 

New ML methods are more widely applicable, but generally do not consider the impact of topology change on sensor measurements and thus cannot accommodate regular topology adjustments in historical data. 

Hence, we propose DYNWATCH, a domain knowledge based and topology-aware algorithm for anomaly detection using sensors placed on a dynamic grid. This figure briefly shows how it works:

![This is an image](slides/toyexample_dynwatch.png)

Let T denote the width of time window for analysis, then for ∀sensor s, the anomalousness of its observation xT+1 is evaluated based on its previous data x1,x2,...,xT. The anomaly detection method works by assigning weights w1,w2,...,wT (wt ≥0,∀t,∑wt = 1) to all the previous observations and an alarm is created if xT+1 deviates ∑wtxt by a certain
threshold

Our approach is accurate, outperforming existing approaches by 20% or more (F-measure) in experiments; and fast, averaging less than 1.7ms per time tick per sensor on a 60K+ branch case using a laptop computer, and scaling linearly with the size of the graph.
