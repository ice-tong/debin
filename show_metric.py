import re
import os
import argparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stat_dir', type=str, help='Path of statistics file.')
    args = parser.parse_args()
    
    p_list = []
    r_list = []
    f_list = []
    accuracy_1p_list = []

    total_name_inf = 0
    total_name_known = 0
    total_name_correct = 0

    for stat_file in os.listdir(args.stat_dir):
        stat_fpath = os.path.join(args.stat_dir, stat_file)
        with open(stat_fpath) as f:
            content = f.read()
        p = re.findall(r'precision_name_2p: (.*?)\n', content)[0]
        r = re.findall(r'recall_name_2p: (.*?)\n', content)[0]
        f = re.findall(r'f1_name_2p: (.*?)\n', content)[0]
        inf = re.findall(r'name_inf: (.*?)\n', content)[0]
        correct = re.findall(r'name_correct: (.*?)\n', content)[0]
        known = re.findall(r'name_known: (.*?)\n', content)[0]
        p_list.append(float(p))
        r_list.append(float(r))
        f_list.append(float(f))
        total_name_inf += int(inf)
        total_name_correct += int(correct)
        total_name_known += int(known)

        accuracy_1p = re.findall(r'accuracy_1p: (.*?)\n', content)[0]
        accuracy_1p_list.append(float(accuracy_1p))

    print('binary-wise mean precision_name_2p:', sum(p_list)/len(p_list))
    print('binary-wise mean recall_name_2p:', sum(r_list)/len(r_list))
    print('binary-wise mean f1_name_2p:', sum(f_list)/len(f_list))
    
    p = total_name_correct / total_name_inf
    r = total_name_correct / total_name_known
    f = 2 * p * r / (p + r)
    print('variable-wise mean precision_name_2p:', p)
    print('variable-wise mean recall_name_2p:', r)
    print('variable-wise mean f1_name_2p:', f)
    
    print("total name known:", total_name_known)
    print("total name inf:", total_name_inf)
    print("total name correct:", total_name_correct)

    print('binary-wise mean accuracy_1p:', sum(accuracy_1p_list)/len(accuracy_1p_list))


if __name__=="__main__":
    main()

