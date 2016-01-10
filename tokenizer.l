%option stack
%{

/*  this is required for malloc()
*/
#include<stdlib.h>

/*  it is not a good idea to use #defines
    for these constants as we will be taking
    them through user input
*/
#define TOTAL_SEM_ONE_SUB 12
#define TOTAL_SEM_TWO_SUB 11

/*  Data structures to populate the marks
    and then analysis will be performed
*/
int *MARKS_SEM_ONE;
int *MARKS_SEM_TWO;

/*  running global variables that define the
    tokenizer logic
    SEM_XXX_SUB:
        the no. of subjects taken for sem xxx
    CURRENT_SEM:
        -1; when invalid or not applicable
        1; when 1st semester entry is tokenized
        2; when 2nd semester
    CURRENT_STUDENT:
        keeps track of how many students are completed in a page
*/
int SEM_ONE_SUB = 0, SEM_TWO_SUB = 0, CURRENT_SEM=-1, CURRENT_STUDENT=1;

/*  so the idea is to reduce code redundancy
    therefore i decided to create this function
    and delete the following states:
        MARKS_SEM_ONE
        MARKS_SEM_TWO
    and combine them into one:
        MARKS_ENTRY

    therefore this function manages the states
    and smartly decides based on global running
    variables to which state the execution has 
    to go
*/
void change_sem();

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
DOTS            [.]{2,}\n

%s PAGE_START
%s COLUMN_NAMES
%s STUDENT_INFO
%s MARKS_ENTRY
%s READ_REMAINING_LINE
%s READ_REMAINING_WORDS
%s RESULT
%%
    BEGIN(PAGE_START);
<READ_REMAINING_LINE>{
.*\n        {   
                /*printf("%d:%d\n",YYSTATE,STUDENT_INFO);*/
                yy_pop_state();
                /* popping the read remaining line state 
                printf("%d:%d\n",YYSTATE,STUDENT_INFO); */
            }
                
}
    /*  the reason to make two separate states just for the 7 line header is that
        the initial header has valuable information like branch and stuff which can
        be tokenized. so just to separate it, this approach is followed
    */
<PAGE_START>{
{DOTS}          {
                    BEGIN(COLUMN_NAMES);
                }
}
<COLUMN_NAMES>{
{DOTS}          {
                    BEGIN(STUDENT_INFO);
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
                /*  make data structures based on the following
                    constants - use malloc function i.e. dynamic memory
                    allocation is to be done
                */
                MARKS_SEM_ONE = (int*) malloc(TOTAL_SEM_ONE_SUB*sizeof(int));
                MARKS_SEM_TWO = (int*) malloc(TOTAL_SEM_TWO_SUB*sizeof(int));
                yy_push_state(MARKS_ENTRY);
                CURRENT_SEM=1;
                /*printf("pushed sem one\n");*/
                yy_push_state(READ_REMAINING_LINE);
            }
}
<MARKS_ENTRY>{
            
{SUB_CODE}  {
                /*printf("%s, ",yytext);*/
            }
{SNAME}     {
                /*printf("%s, ",yytext); */
                /* the last 2 characters specify PP|PR|OR|TW */
                /*printf("%s, ",yytext+yyleng-3);*/
            }
{MARKS_FIXED}   {
                    /* need to separate passing marks from total marks */
                    /*printf("%s, ",yytext);*/
                }
{MARKS}         {
                    char *ptr = NULL;
                    int marks = strtol(yytext,&ptr, 10);
                    /*  WARNING!
                        if yytext == "AA", then marks = 0
                        check the value of ptr and test for edge cases
                        the {MARKS} will have to be changed as unipune
                        appends # $ -- etc to the end of marks to denote
                        certain things
                    */
                    printf("%d, ", marks);
                    if(CURRENT_SEM==1)
                    {
                        MARKS_SEM_ONE[SEM_ONE_SUB++]=marks;
                        /*populate data structures for sem one here! */
                        change_sem();
                        
                    }
                    else if (CURRENT_SEM==2)
                    {
                        MARKS_SEM_TWO[SEM_TWO_SUB++]=marks;
                        /*populate data structures for sem two here! */
                        change_sem();
                    }
                }
}
<READ_REMAINING_WORDS>{
([A-Z]+" ")+    /*printf("skipping: %s\n",yytext);*/ yy_pop_state();
}
<RESULT>{
"GRAND TOTAL".*\n       /*printf("---------%s\n", yytext);*/
{DOTS}                  {
                            /*printf("%s\n", yytext);*/
                            printf("\n");
                            int i =0;
                            /*  generate result analysis here
                                this is the most idiotic result
                                analysis whereby each sem marks
                                are printed side by side
                            */
                            /*
                            for(i=0; i<TOTAL_SEM_ONE_SUB; i++)
                            {
                                printf("%d\t%d\n",MARKS_SEM_ONE[i], MARKS_SEM_TWO[i]);
                            }
                            */
                            CURRENT_STUDENT++;
                            if(CURRENT_STUDENT>3)
                            {
                                /*  ok the page is over
                                    time to reiterate
                                */
                                BEGIN(PAGE_START);
                            }
                            else{
                            BEGIN(STUDENT_INFO);
                                
                            }
                        }
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
int yywrap()
{return 1;}
void change_sem()
{
    if(CURRENT_SEM==1)
    {
        /* this checks whether we need to switch
        to sem two marks or not */
        if(SEM_TWO_SUB<TOTAL_SEM_TWO_SUB)
        {
            yy_push_state(MARKS_ENTRY);
            CURRENT_SEM=2;
            yy_push_state(READ_REMAINING_WORDS);
        }
        /*  this checks whether there are more sem one marks?
            this check is necessary because what if the txt
            contains only sem one marks?
        */
        else if (SEM_ONE_SUB<TOTAL_SEM_ONE_SUB)
        {
            /* dont change the sem here! */
            /* do i need to push MARKS_ENTRY again here? */
            yy_push_state(READ_REMAINING_LINE);
        }
        
        /*  we are done taking marks here!
        */
        else
        {
            CURRENT_SEM=-1;
            SEM_ONE_SUB=SEM_TWO_SUB=0;
            yy_push_state(RESULT);
            yy_push_state(READ_REMAINING_LINE);
        }
    }
    else if (CURRENT_SEM==2)
    {
        /*  this checks whether sem one marks are 
            available to be tokenized
        */
        if(SEM_ONE_SUB<TOTAL_SEM_ONE_SUB)
        {
            yy_push_state(MARKS_ENTRY   );
            CURRENT_SEM=1;
        }

        /*  this states that there are no sem one marks
            left to tokenize, so moving to result, now
            the question is of the possibility that there
            may be more sem two marks to be tokenized such
            that sem one marks are over?
            if yes, then one more condition needs to be added,
            but TOTAL_SEM_ONE_SUB<TOTAL_SEM_TWO_SUB is unheard of
        */ 
        else
        {
            CURRENT_SEM=-1; 
            SEM_TWO_SUB=SEM_ONE_SUB=0;
            yy_push_state(RESULT);
        }
        yy_push_state(READ_REMAINING_LINE);
    }
}