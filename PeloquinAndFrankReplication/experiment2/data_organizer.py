#!/usr/bin/python

import csv
import json
from datetime import datetime

def get_word(scale,degree):
    if scale == 'liked_loved':
        if degree == 'hi1':
            word = 'loved'
        elif degree == 'hi2':
            word = 'liked'
        elif degree == 'mid':
            word = 'indifferent'
        elif degree == 'low1':
            word = 'disliked'
        elif degree == 'low2':
            word = 'hated'
        else:
            raise ValueError(f'Unknown degree {degree}')
    elif scale == 'good_excellent':
        if degree == 'hi1':
            word = 'excellent'
        elif degree == 'hi2':
            word = 'good'
        elif degree == 'mid':
            word = 'okay'
        elif degree == 'low1':
            word = 'bad'
        elif degree == 'low2':
            word = 'terrible'
        else:
            raise ValueError(f'Unknown degree {degree}')
    elif scale == 'palatable_delicious':
        if degree == 'hi1':
            word = 'delicious'
        elif degree == 'hi2':
            word = 'palatable'
        elif degree == 'mid':
            word = 'mediocre'
        elif degree == 'low1':
            word = 'gross'
        elif degree == 'low2':
            word = 'disgusting'
        else:
            raise ValueError(f'Unknown degree {degree}')
    elif scale == 'memorable_unforgettable':
        if degree == 'hi1':
            word = 'unforgettable'
        elif degree == 'hi2':
            word = 'memorable'
        elif degree == 'mid':
            word = 'ordinary'
        elif degree == 'low1':
            word = 'bland'
        elif degree == 'low2':
            word = 'forgettable'
        else:
            raise ValueError(f'Unknown degree {degree}')
    elif scale == 'some_all':
        if degree == 'hi1':
            word = 'all'
        elif degree == 'hi2':
            word = 'most'
        elif degree == 'mid':
            word = 'some'
        elif degree == 'low1':
            word = 'little'
        elif degree == 'low2':
            word = 'none'
        else:
            raise ValueError(f'Unknown degree {degree}')
    elif scale == 'training1':
        if degree == 'hi2':
            word = 'high'
        elif degree == 'low1':
            word = 'low'
        else:
            raise ValueError(f'Unknown degree {degree}')
    else:
        raise ValueError(f'Unknown scale {scale}')
    return(word)

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
    not_answered = 0
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
                not_answered += 1
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
                not_answered += 1
            else:
                raise ValueError(f'Unknown AQ response {responses[i]}')
    return(baroncohen_score,austin_score,not_answered)

# Results file
fname = 'pandfexp.results'

# Read data into memory
#######################
results = []
with open(fname,'r') as f:
    for line in f.readlines():
        l = line.strip().split('\t')
        results.append(l)

WORKER_COL = 19
DATA_COL = 29
TIME_ACCEPTED_COL = 22
TIME_SUBMITTED_COL = 23

data_structure = [
    [
        'worker_id',
        'scale',
        'degree',
        'manipulation',
        'judgment',
        'word',
        'austin_aq',
        'baroncohen_aq',
        'not_answered'
        'age',
        'gender',
        'native_language',
        'expt_aim',
        'comments',
        'duration'
    ] + ['AQ'+str(x+1) for x in range(50)]
]
for row in results[1:]:
    json_string = row[DATA_COL].replace('""','"')[1:-1]
    # Parse the json data with the participant responses
    ####################################################
    participant_data = json.loads(json_string)

    # Get time data
    ###############
    ta_str = row[TIME_ACCEPTED_COL].strip('"')
    ts_str = row[TIME_SUBMITTED_COL].strip('"')
    # Parsing the MTurk time format
    #
    #   Fri Apr 27 11:15:30 PDT 2018
    #   %a  %b  %d %H:%M:%S %Z  %Y
    time_accepted = datetime.strptime(ta_str,'%a %b %d %H:%M:%S %Z %Y')
    time_submitted = datetime.strptime(ts_str,'%a %b %d %H:%M:%S %Z %Y')
    time_taken = time_submitted - time_accepted

    # Put computed data into data structure
    #######################################
    participant_data['worker_id'] = row[WORKER_COL].strip('"')
    participant_data['time_taken'] = str(time_taken)

    # Get AQ scores, both Baron-Cohen and Austin
    ############################################
    aq_responses = participant_data['aq']
    aq_bc_score, aq_a_score, aq_na = scoreAQ(aq_responses)

    # Get non-trial related data
    ############################
    native_lang = participant_data['language'][0]
    expt_aim = participant_data['expt_aim'][0]
    expt_gen = participant_data['expt_gen'][0]
    age = participant_data['age'][0]
    gender = participant_data['gender'][0]
    workerid = participant_data['worker_id']

    # Get trial data and make a row for each
    ########################################
    for i in range(len(participant_data['scale'])):
        scale = participant_data['scale'][i]
        degree = participant_data['degree'][i]
        word = get_word(scale,degree)
        manip = participant_data['manipulation_level'][i]
        judgment = participant_data['judgment'][i]
        struct_row = [
            workerid,
            scale,
            degree,
            manip,
            judgment,
            word,
            aq_a_score,
            aq_bc_score,
            aq_na,
            age,
            gender,
            native_lang,
            expt_aim,
            expt_gen,
            time_taken
        ] + aq_responses
        data_structure.append(struct_row)

# Write out the data to a new csv file
######################################
ofile = 'PeloquinAndFrankReplicationData.csv'
with open(ofile,'w') as f:
    writer = csv.writer(f)
    writer.writerows(data_structure)
