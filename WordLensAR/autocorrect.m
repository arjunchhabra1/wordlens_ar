//
//  autocorrect.m
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#import <Foundation/Foundation.h>

char **dictionary;
int vocab_size;

int maxDist = 4;
int numSuggestions = 5;

struct Letter{
    char letter;
    int end_of_word;
    struct Letter *right;
    struct Letter *child;
} *root;
typedef struct Letter Letter;

void addToTrie(char *word, int length){
    Letter *curr = root;
    for(int i = 0; i<length; i++){
        char c = word[i];
        Letter *child = curr->child;
        if(child == NULL){
            Letter *letter = (Letter*)malloc(sizeof(Letter));
            letter->letter = c;
            letter->end_of_word = 0;
            letter->right = NULL;
            letter->child = NULL;
            curr->child = letter;
            curr = letter;
            continue;
        }
        while(1){
            if(child->letter == c){
                curr = child;
                break;
            }
            if(child->right == NULL){
                Letter *letter = (Letter*)malloc(sizeof(Letter));
                letter->letter = c;
                letter->end_of_word = 0;
                letter->right = NULL;
                letter->child = NULL;
                child->right = letter;
                curr = letter;
                break;
            }
            child = child->right;
        }
    }
    curr->end_of_word = 1;
}

int isAWord(const char *word){
    int length = strlen(word);
    Letter *curr = root;
    for(int i = 0; i<length; i++){
        char c = word[i];
        Letter *child = curr->child;
        if(child == NULL) return 0;
        while(1){
            if(child->letter == c){
                curr = child;
                break;
            }
            if(child->right == NULL){
                return 0;
            }
            child = child->right;
        }
    }
    return curr->end_of_word;
}

void loadDict(){
    root = (Letter*)malloc(sizeof(Letter));
    root->letter = '\0';
    root->end_of_word = 0;
    root->right = NULL;
    root->child = NULL;

    dictionary = (char**)malloc(sizeof(char*));
    int end = 0, size = 1;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dictionary" ofType:@"txt"];
    FILE *file = fopen([filePath cStringUsingEncoding: NSUTF8StringEncoding], "r");

    //FILE *file = fopen("dictionary.txt", "r");
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    while ((read = getline(&line, &len, file)) != -1) {
        addToTrie(line, read-1);
        char *word = (char*)malloc(read*sizeof(char));
        memcpy(word, line, read-1);
        word[read-1] = '\0';
        dictionary[end++] = word;
        if(end >= size) dictionary = (char**)realloc(dictionary, (size*=2)*sizeof(char*));
    }
    fclose(file);
    if(line) free(line);
    vocab_size = end;
}

int distance(char *word1, char *word2) {
    int len1 = strlen(word1), len2 = strlen(word2);
    int matrix[len1 + 1][len2 + 1];
    int i;
    for (i = 0; i <= len1; i++) {
        matrix[i][0] = i;
    }
    for (i = 0; i <= len2; i++) {
        matrix[0][i] = i;
    }
    for (i = 1; i <= len1; i++) {
        int j;
        char c1;

        c1 = word1[i-1];
        for (j = 1; j <= len2; j++) {
            char c2;

            c2 = word2[j-1];
            if (c1 == c2) {
                matrix[i][j] = matrix[i-1][j-1];
            }
            else {
                int delete;
                int insert;
                int substitute;
                int minimum;

                delete = matrix[i-1][j] + 1;
                insert = matrix[i][j-1] + 1;
                substitute = matrix[i-1][j-1] + 1;
                minimum = delete;
                if (insert < minimum) {
                    minimum = insert;
                }
                if (substitute < minimum) {
                    minimum = substitute;
                }
                matrix[i][j] = minimum;
            }
        }
    }
    return matrix[len1][len2];
}

struct Word{
    char *word;
    int distance;
};
typedef struct Word Word;

int cmpfunc(const void *a, const void *b){
    return ((Word*)a)->distance - ((Word*)b)->distance;
}

char *autocorrect(const char *inputWord){
    Word *closestWords = (Word*)malloc(sizeof(Word));
    int end = 0, size = 1;

    for(int i = 0; i<vocab_size; i++){
        char *dictWord = dictionary[i];
        int dist = distance(inputWord, dictWord);
        if(dist <= maxDist){
            closestWords[end].word = dictWord;
            closestWords[end].distance = dist;
            if(++end >= size) closestWords = (Word*)realloc(closestWords, (size*=2)*sizeof(Word));
        }
    }

    if(end == 0){
        free(closestWords);
        return "";
    }

    qsort(closestWords, end, sizeof(Word), cmpfunc);

    int n = numSuggestions < end ? numSuggestions : end;
    char *returnString = (char*)malloc(100*sizeof(char));
    char *wordPtr = returnString;
    for(int i = 0; i<n; i++){
        char *dictWord = closestWords[i].word;
        int length = strlen(dictWord);
        memcpy(wordPtr, dictWord, length);
        wordPtr += length;
        *wordPtr++ = ' ';
    }
    *wordPtr = '\0';

    free(closestWords);
    return returnString;
}

