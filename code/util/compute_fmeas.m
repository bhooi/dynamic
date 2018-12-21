% pred and truth are binary vectors
function fmeas = compute_fmeas(pred, truth)
fmeas = 2 * sum(pred & truth) / (sum(pred) + sum(truth));
end