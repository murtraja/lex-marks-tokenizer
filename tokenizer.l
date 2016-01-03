%option stack
YEAR_SYMBOL 	S
SEAT_NUMERIC	[0-9]{9}
SEAT_NO			{YEAR_SYMBOL}{SEAT_NUMERIC}" "

PRN 			[0-9]{8}[A-Z]
SNAME 			([A-Z]+" "){2,},
SUB_CODE 		[0-9]{6}" "

%s STUDENT_INFO
%s MARKS_SEM_ONE
%s MARKS_SEM_TWO
%s READ_REMAINING_LINE
%%
	BEGIN(STUDENT_INFO);
<READ_REMAINING_LINE>{
.*\n 		{ 	
				printf("%d:%d\n",YYSTATE,STUDENT_INFO);
				yy_pop_state();
				printf("%d:%d\n",YYSTATE,STUDENT_INFO);
			}
				
}
<STUDENT_INFO>{
{SEAT_NO}	printf("%s\n",yytext);
{SNAME}		yytext[yyleng-1]=0; printf("%s\n",yytext);
{PRN} 		printf("%s\n",yytext); yy_push_state(MARKS_SEM_ONE); printf("pushed sem one\n");yy_push_state(READ_REMAINING_LINE);
}
<MARKS_SEM_ONE>{
{SUB_CODE}	printf("%s\n",yytext);
}
.|"\n"
%%
main( argc, argv )
         int argc;
         char **argv;
             {
             ++argv, --argc;  /* skip over program name */
             if ( argc > 0 )
                     yyin = fopen( argv[0], "r" );
             else
                     yyin = stdin;

             yylex();
             }
