#!/usr/bin/env python3 
import sys 

def main():
    current_word = None 
    current_cnt = 0

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue 
        word, _ = line.split('\t')
        if current_word is None:
            current_word = word
        elif word != current_word:
            print(f"{current_word}\t{current_cnt}")
            current_word = word 
            current_cnt = 0
        current_cnt += 1 

    if current_word is not None:
        print(f"{current_word}\t{current_cnt}")

if __name__ == "__main__":
    main()  
        

        
