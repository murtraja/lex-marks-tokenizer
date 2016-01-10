file=tokenizer
ifile=sample.txt
debug=1
$(file): $(file).lex.c
	cc -o $(file) $(file).lex.c
	./$(file) $(ifile)
$(file).lex.c: $(file).l
ifeq ($(debug),1)
		lex -d -o $(file).lex.c $(file).l
else
		lex -o $(file).lex.c $(file).l
endif