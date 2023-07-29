
Instructions for integrating autocorrect code into ios app

1. Sometime near the launch of the app, call the loadDict function
2. When calling isAWord() or autocorrect(), make sure the input word is completely lowercase
3. First call isAWord(). If it returns 0, then only call autocorrect()
4. Change line 97 of autocorrect.m appropriately depending on where you keep the dictionary.txt file
5. autocorrect() returns a string of the form "volatile volatiles volatize lattice dolittle". The suggestions are ranked from best to worst, and each one is separated by a space. There may be less than 5 words returned, maybe even none (e.g., ""). 
