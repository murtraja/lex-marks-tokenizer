%option stack
%{
int SEM_ONE_SUB = 0, SEM_TWO_SUB = 0;

#define TOTAL_SEM_ONE_SUB 12
#define TOTAL_SEM_TWO_SUB 11
%}
YEAR_SYMBOL     S
SEAT_NUMERIC    [0-9]{9}
SEAT_NO         {YEAR_SYMBOL}{SEAT_NUMERIC}" "

PRN             [0-9]{8}[A-Z]
SNAME           ([A-Z&.]+" "){2,}
                /* student name or subject name */
SUB_CODE        [0-9]{6}" "
MARKS_FIXED     ([0-9]+" "){2}
MARKS           ([0-9]+)|(AA)

%s STUDENT_INFO
%s MARKS_SEM_ONE
%s MARKS_SEM_TWO
%s READ_REMAINING_LINE
%s READ_REMAINING_WORDS
%s RESULT
%%
    BEGIN(STUDENT_INFO);
<READ_REMAINING_LINE>{
.*\n        {   
                /*printf("%d:%d\n",YYSTATE,STUDENT_INFO);*/
                yy_pop_state();
                /* popping the read remaining line state 
                printf("%d:%d\n",YYSTATE,STUDENT_INFO); */
            }
                
}
<STUDENT_INFO>{
{SEAT_NO}   printf("%s, ",yytext);
{SNAME}     yytext[yyleng-1]=0; printf("%s, ",yytext);
{PRN}       {
                printf("%s, ",yytext); 
                /*  now i want to go to sem one marks but only after reading
                    the remaining line. so the logic goes this way
                */
                yy_push_state(MARKS_SEM_ONE); 
                printf("pushed sem one\n");
                yy_push_state(READ_REMAINING_LINE);
            }
}
<MARKS_SEM_ONE>{
            
{SUB_CODE}  printf("%s, ",yytext);
{SNAME}     {
                printf("%s, ",yytext);
                /* the last 2 characters specify PP|PR|OR|TW */
                printf("%s, ",yytext+yyleng-3);
            }
{MARKS_FIXED}   {
                    /* need to separate passing marks from total marks */
                    printf("%s, ",yytext);
                }
{MARKS}         {
                    printf("%s\n", yytext);
                    SEM_ONE_SUB++;
                    printf("new value of sem one sub %d\n",SEM_ONE_SUB);
                    if(SEM_TWO_SUB<TOTAL_SEM_TWO_SUB)
                    {
                        yy_push_state(MARKS_SEM_TWO);
                        yy_push_state(READ_REMAINING_WORDS);
                    }
                    else
                    {
                        SEM_ONE_SUB=SEM_TWO_SUB=0;
                        yy_push_state(RESULT);
                        yy_push_state(READ_REMAINING_LINE);
                    }
                }
}
<MARKS_SEM_TWO>{
{SUB_CODE}  printf("%s, ",yytext);
{SNAME}         {
                    printf("%s, ",yytext);
                    /* the last 2 characters specify PP|PR|OR|TW */
                    printf("%s, ",yytext+yyleng-3);
                }
{MARKS_FIXED}   {
                    /* need to separate passing marks from total marks */
                    printf("%s, ",yytext);
                }
{MARKS}         {
                    printf("%s\n", yytext);
                    SEM_TWO_SUB++;
                    if(SEM_ONE_SUB<TOTAL_SEM_ONE_SUB)
                    {
                        yy_push_state(MARKS_SEM_ONE);
                    }
                    else
                    {
                        SEM_TWO_SUB=SEM_ONE_SUB=0;
                        yy_push_state(RESULT);
                    }
                    yy_push_state(READ_REMAINING_LINE);
                }
}
<READ_REMAINING_WORDS>{
([A-Z]+" ")+    printf("skipping: %s\n",yytext); yy_pop_state();
}
<RESULT>{
"GRAND TOTAL".*\n       printf("---------%s\n", yytext);
[.]+                    printf("%s\n", yytext);
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
