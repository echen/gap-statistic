# An implementation of the gap statistic algorithm from Tibshirani, Walther, and Hastie's "Estimating the number of clusters in a data set via the gap statistic".

library(plyr)
library(ggplot2)

gap_statistic = function(data, min_num_clusters = 1, max_num_clusters = 10, num_reference_bootstraps = 10) {
	num_clusters = min_num_clusters:max_num_clusters
	actual_dispersions = maply(num_clusters, function(n) dispersion(data, n))
	ref_dispersions = maply(num_clusters, function(n) reference_dispersion(data, n, num_reference_bootstraps))
	mean_ref_dispersions = ref_dispersions[ , 1]
	stddev_ref_dispersions = ref_dispersions[ , 2]
	gaps = mean_ref_dispersions - actual_dispersions
	
	print(plot_gap_statistic(gaps, stddev_ref_dispersions, num_clusters))
	
	print(paste("The estimated number of clusters is ", num_clusters[which.max(gaps)], ".", sep = ""))
	
	list(gaps = gaps, gap_stddevs = stddev_ref_dispersions)
}

plot_gap_statistic = function(gaps, stddevs, num_clusters) {
	qplot(num_clusters, gaps, xlab = "# clusters", ylab = "gap", geom = "line", main = "Estimating the number of clusters via the gap statistic") + geom_errorbar(aes(num_clusters, ymin = gaps - stddevs, ymax = gaps + stddevs), size = 0.3, width = 0.2, colour = "darkblue")
}

# Calculate log(sum_i(within-cluster_i sum of squares around cluster_i mean)).
dispersion = function(data, num_clusters) {
	# R's k-means algorithm doesn't work when there is only one cluster.
	if (num_clusters == 1) {
		cluster_mean = aaply(data, 2, mean)
		distances_from_mean = aaply((data - cluster_mean)^2, 1, sum)
		log(sum(distances_from_mean))
	} else {	
		# Run the k-means algorithm `nstart` times. Each run uses at most `iter.max` iterations.
		k = kmeans(data, centers = num_clusters, nstart = 10, iter.max = 50)
		# Take the sum, over each cluster, of the within-cluster sum of squares around the cluster mean. Then take the log. This is `W_k` in TWH's notation.
		log(sum(k$withinss))
	}
}

# For an appropriate reference distribution (in this case, uniform points in the same range as `data`), simulate the mean and standard deviation of the dispersion.
reference_dispersion = function(data, num_clusters, num_reference_bootstraps) {
	dispersions = maply(1:num_reference_bootstraps, function(i) dispersion(generate_uniform_points(data), num_clusters))
	mean_dispersion = mean(dispersions)
	stddev_dispersion = sd(dispersions) / sqrt(1 + 1 / num_reference_bootstraps) # the extra factor accounts for simulation error
	c(mean_dispersion, stddev_dispersion)
}

# Generate uniform points within the range of `data`.
generate_uniform_points = function(data) {
	# Find the min/max values in each dimension, so that we can generate uniform numbers in these ranges.
	mins = aaply(data, 2, min)
	maxs = apply(data, 2, max)

	num_datapoints = nrow(data)
	# For each dimension, generate `num_datapoints` points uniformly in the min/max range.
	uniform_pts = maply(1:length(mins), function(dim) runif(num_datapoints, min = mins[dim], max = maxs[dim]))
	uniform_pts = t(uniform_pts)
}