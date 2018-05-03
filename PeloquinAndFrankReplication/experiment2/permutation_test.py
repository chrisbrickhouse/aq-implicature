#!/usr/bin/python

import csv
import json
import math
import random
import statistics

def swap(a,b):
    a_hold = []
    b_hold = []
    # Choose max number to swap == shortest list
    max_swap = min([len(a),len(b)])
    # Choose a random number of values to swap between lists
    n_swap = random.randint(1,max_swap)
    # Remove a random item from each list n_swap times and put them in holding
    for i in range(n_swap):
        a_n = random.randint(0,len(a)-1)
        b_n = random.randint(0,len(b)-1)
        a_hold.append(a.pop(a_n))
        b_hold.append(b.pop(b_n))
    # Swap values
    b_out = b + a_hold
    a_out = a + b_hold
    return(a_out,b_out)

def get_proportion(pd):
    data = {}
    for wid in pd:
        for i in range(len(pd[wid]['scale'])):
            scale = pd[wid]['scale'][i]
            degree = pd[wid]['degree'][i]
            manip = pd[wid]['manipulation_level'][i]
            judgment = pd[wid]['judgment'][i]
            if scale not in data:
                data[scale] = {}
            if degree not in data[scale]:
                data[scale][degree] = {}
            if manip not in data[scale][degree]:
                data[scale][degree][manip] = []
            data[scale][degree][manip].append(int(judgment))
    proportions = {}
    for scale in data:
        for degree in data[scale]:
            for manip in data[scale][degree]:
                try:
                    p = statistics.mean(data[scale][degree][manip])
                except:
                    print(data[scale][degree][manip])
                if scale not in proportions:
                    proportions[scale] = {}
                if degree not in proportions[scale]:
                    proportions[scale][degree] = {}
                if manip not in proportions[scale][degree]:
                    proportions[scale][degree][manip] = p
                else:
                    print("Huh?")
    return(proportions)

def compare_groups(a,b,og_data=None):
    if og_data != None:
        a_d = {x:og_data[x] for x in og_data if x in a}
        b_d = {x:og_data[x] for x in og_data if x in b}
        g1 = get_proportion(a_d)
        g2 = get_proportion(b_d)
    else:
        g1 = get_proportion(a)
        g2 = get_proportion(b)
    data = {}
    for scale in g1:
        for degree in g1[scale]:
            for manip in g1[scale][degree]:
                g1_mean = g1[scale][degree][manip]
                g2_mean = g2[scale][degree][manip]
                delta = g1_mean - g2_mean
                if scale not in data:
                    data[scale] = {}
                if degree not in data[scale]:
                    data[scale][degree] = {}
                if manip not in data[scale][degree]:
                    data[scale][degree][manip] = delta
                else:
                    print("Huh?")
    return(data)

def scoreAQ(responses):
    # Sanity check for all 50 responses
    if len(responses) != 50:
        return(None,None)
    # Indices where an agree response scores
    #    1 (per Baron-Cohen) or
    #    3/4 (per Austin)
    agree_scores = [
        1,
        2,
        4,
        5,
        6,
        7,
        9,
        12,
        13,
        16,
        18,
        19,
        20,
        21,
        22,
        23,
        26,
        33,
        35,
        39,
        41,
        42,
        43,
        45,
        46
    ]
    # Indices where an agree response scores
    #    0 (per Baron-Cohen) or
    #    2/1 (per Austin)
    disagree_scores = [
        3,
        8,
        10,
        11,
        14,
        15,
        17,
        24,
        25,
        27,
        28,
        29,
        30,
        31,
        32,
        34,
        36,
        37,
        38,
        40,
        44,
        47,
        48,
        49,
        50
    ]
    baroncohen_score = 0
    austin_score = 0
    for i in range(len(responses)):
        if i+1 in agree_scores:
            if responses[i] == 'DA':
                baroncohen_score += 1
                austin_score += 4
            elif responses[i] == 'SA':
                baroncohen_score += 1
                austin_score += 3
            elif responses[i] == 'SD':
                baroncohen_score += 0
                austin_score += 2
            elif responses[i] == 'DD':
                baroncohen_score += 0
                austin_score += 1
            elif responses[i] is None:
                baroncohen_score += 0.01
                austin_score += 0.01
            else:
                raise ValueError(f'Unknown AQ response {responses[i]}')
        elif i+1 in disagree_scores:
            if responses[i] == 'DA':
                baroncohen_score += 0
                austin_score += 1
            elif responses[i] == 'SA':
                baroncohen_score += 0
                austin_score += 2
            elif responses[i] == 'SD':
                baroncohen_score += 1
                austin_score += 3
            elif responses[i] == 'DD':
                baroncohen_score += 1
                austin_score += 4
            elif responses[i] is None:
                baroncohen_score += 0.01
                austin_score += 0.01
            else:
                raise ValueError(f'Unknown AQ response {responses[i]}')
    return(baroncohen_score,austin_score)

WORKER_COL = 19
DATA_COL = 29
PERMUTATION_N = 1000
Z_CRIT = 1.95
ifile = 'pandflive.results'
raw_data = []
with open(ifile,'r') as f:
    for line in f.readlines():
        l = line.strip().split('\t')
        raw_data.append(l)

p_data = {}
for row in raw_data[1:]:
    json_string = row[DATA_COL].replace('""','"')[1:-1]
    pd = json.loads(json_string)
    workerid = row[WORKER_COL].strip('"')
    aq_responses = pd['aq']
    aq_bc_score, aq_a_score = scoreAQ(aq_responses)
    pd['bc_aq'] = aq_bc_score
    pd['a_aq'] = aq_a_score
    p_data[workerid] = pd

bc_aq_list = [math.floor(p_data[x]['bc_aq']) for x in p_data.keys()]
aq_median = statistics.median(bc_aq_list)
high_aq = [x for x in p_data.keys() if p_data[x]['bc_aq'] > aq_median]
low_aq = [x for x in p_data.keys() if p_data[x]['bc_aq'] <= aq_median]
test_value = compare_groups(high_aq,low_aq,p_data)
data_arrays = {}
for s in test_value:
    if s not in data_arrays:
        data_arrays[s] = {}
    for d in test_value[s]:
        if d not in data_arrays[s]:
            data_arrays[s][d] = {}
        for m in test_value[s][d]:
            if m not in data_arrays[s][d]:
                data_arrays[s][d][m] = []
a = high_aq[:]
b = low_aq[:]
for _ in range(PERMUTATION_N):
    a,b = swap(a,b)
    permuted_data = compare_groups(a,b,p_data)
    for s in permuted_data:
        for d in permuted_data[s]:
            for m in permuted_data[s][d]:
                data_arrays[s][d][m].append(permuted_data[s][d][m])

z_data = {}
for s in data_arrays:
    if s == 'training1':
        continue
    if s not in z_data:
        z_data[s] = {}
    for d in data_arrays[s]:
        if d not in z_data[s]:
            z_data[s][d] = {}
        for m in data_arrays[s][d]:
            mu = statistics.mean(data_arrays[s][d][m])
            std = statistics.stdev(data_arrays[s][d][m])
            x = test_value[s][d][m]
            try:
                z = (x-mu)/std
            except ZeroDivisionError:
                z = 0
            z_data[s][d][m]=z
            if z > Z_CRIT or z < -Z_CRIT:
                print(s,d,m,z)
