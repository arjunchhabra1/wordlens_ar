//
//  autocorrect.h
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//

void loadDict();

int isAWord(const char *word);

char *autocorrect(const char *inputWord);

