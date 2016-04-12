# -*- coding: utf-8 -*-
"""
Created on Wed Jul 18 18:09:25 2012

@author: janak
"""

from __future__ import print_function

import numpy as np
import scipy as sp
import matplotlib as mpl
import matplotlib.pyplot as plt


def edist(a, b):
	n = len(a)
	m = len(b)
	if n == m:
		d = a - b
		return np.sqrt(np.sum(d**2))
	else:
		return -1


def dist(x, y):
	return np.abs(x - y)


def dtw(a, b):
	n = len(a)-1
	m = len(b)-1
	DTW = np.zeros((n+1, m+1))
	for i in range(1, n+1):
		for j in range(1, m+1):
			DTW[i][j] = dist(a[i-1], b[j-1]) + min(DTW[i-1][j], DTW[i][j-1], DTW[i-1][j-1])
#	print(DTW)
	return DTW[n][m]


def lcss(a, b):
	n = len(a)-1
	m = len(b)-1
	delta = 0.1
	LCSS = np.zeros((n+1, m+1))
	for i in range(1, n+1):
		for j in range(1, m+1):
			if dist(a[i], b[j]) < delta:
				LCSS[i][j] = LCSS[i-1][j-1] + 1
			else:
				LCSS[i][j] = max(LCSS[i][j-1], LCSS[i-1][j])
#	print(LCSS)
	return 1 - LCSS[n][m] / min(n, m)


if __name__ == "__main__":

    x = np.linspace(0, 3*np.pi, 100)
    a = np.sin(x/10)+np.cos(x/5+40)/2
    b = np.sin(x/10)+np.cos(x/5-80)/2


    e = edist(a, b)
    if e >= 0:
        print("edist = {}".format(e))
        print("dtw = {}".format(dtw(a, b)))
        print("lcss = {}".format(lcss(a, b)))
    plt.plot(x, a)
    plt.plot(x, b)
    plt.show()
