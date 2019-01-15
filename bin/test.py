# coding=utf-8
import argparse


def main(args):
    print('Reading target_file and output_file')
    print(f'target_file={args.target_file}, decode_file={args.decode_file}')
    with open(args.target_file, 'r', encoding='utf-8') as target_file, open(args.decode_file, 'r', encoding='utf-8') as decode_file:
        total_count = 0
        total_accuracy = 0
        for index, (target_line, output_line) in enumerate(zip(target_file, decode_file)):

            total_count += 1
            target_line, output_line = target_line.strip(), output_line.strip()
            target_tokens = target_line.split()
            decode_tokens = output_line.split()

            if args.gather_tag:
                target_tokens = ['/'.join(token) for token in zip(target_tokens[0::2], target_tokens[1::2])]
                decode_tokens = ['/'.join(token) for token in zip(decode_tokens[0::2], decode_tokens[1::2])]

            decode_que = decode_tokens
            target_length = len(target_tokens)
            correct_count = 0
            for target_token in target_tokens:
                if target_token in decode_que:
                    correct_count += 1
                    decode_que = decode_que[decode_que.index(target_token) + 1:]
            single_accuracy = correct_count / target_length
            total_accuracy = ((total_accuracy * index) + single_accuracy) / (index + 1)
            if index % 10000 == 0 or index == 51:
                print_dic({'index': index, 'target_length': target_length, 'total_acc': total_accuracy,
                           'single_acc': single_accuracy, 'target': target_tokens, 'output': decode_tokens})
        print('TEST END ------------------------------------------')
        print(f'total_accuracy={total_accuracy}, total_number={index + 1}')


def print_dic(dic):
    print(','.join([f'{k}={v}' for k, v in dic.items()]))


def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--decode_file', help='Location of decode file')
    parser.add_argument('--target_file', help='Location of target file')
    parser.add_argument('--gather_tag', help='Gather morph with tag or not', type=str2bool, default=False)
    args = parser.parse_args()
    main(args)
