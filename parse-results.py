#!/usr/bin/env python3

import json
import csv
import sys
import glob

def parse_lemma_name(lemma_name):
    '''
    The names are an array like
    ```
    ['m<=m == True', None]
    ['prop_T50', 'count x (isort y) == count x y']
    ```

    From what I gather this is so that named lemmas have their definition
    alongside them. We don't care about the names, so we take the definition,
    falling back to the name (which is the definition for the "anonymous
    lemmas")
    '''
    return lemma_name[1] or lemma_name[0]

def read_result(filename):
    prop_name = filename.rstrip('.json')
    result_json = json.load(open(filename))
    time, result_obj = result_json[-1]
    unproved_lemmas = list(map(parse_lemma_name, result_obj['qs_unproved']))
    proved_lemmas = list(map(parse_lemma_name, result_obj['qs_proved']))
    num_unproved_lemmas = len(unproved_lemmas)
    num_proved_lemmas = len(proved_lemmas)
    num_lemmas = num_unproved_lemmas + num_proved_lemmas
    # We expect that there is only one top-level property. If this expectation
    # is violated we will have to do more parsing to figure out if the prop is
    # proved.
    proved_props = list(map(parse_lemma_name, result_obj['proved']))
    unproved_props = list(map(parse_lemma_name, result_obj['unproved']))
    assert(len(proved_props) + len(unproved_props) == 1)
    prop_proven = len(proved_props) > 0
    # there should be only one prop between these two, so extract it
    prop = (proved_props + unproved_props)[0]
    return {
        'prop_name': prop_name,
        'prop_proven': prop_proven,
        'time': time,
        'num_lemmas': num_lemmas,
        'num_proved_lemmas': num_proved_lemmas,
        'num_unproved_lemmas': num_unproved_lemmas,
        'proved_lemmas': proved_lemmas,
        'unproved_lemmas': unproved_lemmas,
        'prop': prop,
    }

if __name__ == '__main__':
    results_dir = sys.argv[1]
    output_file = sys.argv[2]
    results = [read_result(filename) for filename in glob.glob(results_dir + '/*.json')]
    with open(output_file, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, ['prop_name', 'prop_proven', 'time', 'num_lemmas', 'num_proved_lemmas', 'num_unproved_lemmas', 'proved_lemmas', 'unproved_lemmas', 'prop'])
        writer.writeheader()
        for result in sorted(results, key=lambda result: result['prop_name']):
            writer.writerow(result)
