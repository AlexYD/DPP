//          Copyright Alex Dovhal 2010.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module ast_parser ;
import std.stdio, std.conv ;
import core.stdc.ctype ; //isspace

enum
{
    ID_VOID = 0,
    ID_STRING = 1,
    ID_LIST = 2,
} ;

class TokenList
{
    enum
    {
        LEFT_TO_RIGHT = 1,
        RIGHT_TO_LEFT = 2,
    }
    enum
    {
        INFIX       = 0,
        PREFIX      = 1,
        POSTFIX     = 2,
        PAREN       = 3,
        //SEPARATOR   = 4  //not yet done
    }

    struct OperatorProperties
    {
        int type ; //prefix, postfix, infix, paren
        int priority ;
        int direction ; // left-to-right, right-to-left
    } ;

    static OperatorProperties [string] ms_operator ;

    static this ()
    {
        {
            OperatorProperties w = {INFIX, 0, LEFT_TO_RIGHT} ;
            ms_operator [";"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["foreach"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["%o1foreach"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["for"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["%o1for"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["while"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["%o1while"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["do"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 1, LEFT_TO_RIGHT} ;
            ms_operator ["%o1do"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 2, LEFT_TO_RIGHT} ;
            ms_operator ["return"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 2, LEFT_TO_RIGHT} ;
            ms_operator ["%o1return"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 3, LEFT_TO_RIGHT} ;
            ms_operator [","] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["+="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["-="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["*="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["/="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["%="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["&="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["|="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["^="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator ["<<="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator [">>="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 4, RIGHT_TO_LEFT} ;
            ms_operator [">>>="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 5, RIGHT_TO_LEFT} ;
            ms_operator ["?"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 6, LEFT_TO_RIGHT} ;
            ms_operator [":"] = w ;
        }
        {   //TODO : check
            //OperatorProperties w = {INFIX, 7, RIGHT_TO_LEFT} ;
            //ms_operator ["?:"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 8, LEFT_TO_RIGHT} ;
            ms_operator ["||"] = w ;
        }
                {
            OperatorProperties w = {INFIX, 9, LEFT_TO_RIGHT} ;
            ms_operator ["&&"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 10, LEFT_TO_RIGHT} ;
            ms_operator ["|"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 11, LEFT_TO_RIGHT} ;
            ms_operator ["^"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 12, LEFT_TO_RIGHT} ;
            ms_operator ["&"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 13, LEFT_TO_RIGHT} ;
            ms_operator ["=="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 13, LEFT_TO_RIGHT} ;
            ms_operator ["!="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 14, LEFT_TO_RIGHT} ;
            ms_operator [">"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 14, LEFT_TO_RIGHT} ;
            ms_operator [">="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 14, LEFT_TO_RIGHT} ;
            ms_operator ["<"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 14, LEFT_TO_RIGHT} ;
            ms_operator ["<="] = w ;
        }
        {
            OperatorProperties w = {INFIX, 15, LEFT_TO_RIGHT} ;
            ms_operator [">>"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 15, LEFT_TO_RIGHT} ;
            ms_operator [">>>"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 15, LEFT_TO_RIGHT} ;
            ms_operator ["<<"] = w ;
        }
        {   //TODO : check priority
            OperatorProperties w = {INFIX, 16, LEFT_TO_RIGHT} ;
            ms_operator ["is"] = w ;
        }
        {   //TODO : check priority
            OperatorProperties w = {INFIX, 16, LEFT_TO_RIGHT} ;
            ms_operator ["!is"] = w ;
        }
        {   //TODO : check priority
            OperatorProperties w = {INFIX, 16, LEFT_TO_RIGHT} ;
            ms_operator ["in"] = w ;
        }
        {   //TODO : check priority
            OperatorProperties w = {INFIX, 16, LEFT_TO_RIGHT} ;
            ms_operator ["!in"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 17, LEFT_TO_RIGHT} ;
            ms_operator ["+"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 17, LEFT_TO_RIGHT} ;
            ms_operator ["-"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 18, LEFT_TO_RIGHT} ;
            ms_operator ["*"] = w ;
        }
        {   //TODO : check priority
            OperatorProperties w = {INFIX, 18, LEFT_TO_RIGHT} ;
            ms_operator ["~"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 18, LEFT_TO_RIGHT} ;
            ms_operator ["/"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 18, LEFT_TO_RIGHT} ;
            ms_operator ["%"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 19, LEFT_TO_RIGHT} ;
            ms_operator ["%list"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1+"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1-"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1*"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1&"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ; // virtual, it convers to prefix or postfix form
            ms_operator ["++"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ; // virtual
            ms_operator ["--"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1++"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1--"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1!"] = w ;
        }
        {
            OperatorProperties w = {PREFIX, 20, RIGHT_TO_LEFT} ;
            ms_operator ["%o1~"] = w ;
        }
        //postfix: hightest priority
        {
            OperatorProperties w = {POSTFIX, 21, LEFT_TO_RIGHT} ;
            ms_operator ["%o2--"] = w ;
        }
        {
            OperatorProperties w = {POSTFIX, 21, LEFT_TO_RIGHT} ;
            ms_operator ["%o2++"] = w ;
        }
        {
            OperatorProperties w = {INFIX, 21, LEFT_TO_RIGHT} ;
            ms_operator ["."] = w ;
        }
        {
            OperatorProperties w = {INFIX, 21, LEFT_TO_RIGHT} ;
            ms_operator ["!"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, LEFT_TO_RIGHT} ;
            ms_operator ["%lparen"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, RIGHT_TO_LEFT} ;
            ms_operator ["%rparen"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, LEFT_TO_RIGHT} ;
            ms_operator ["%lbracket"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, RIGHT_TO_LEFT} ;
            ms_operator ["%rbracket"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, LEFT_TO_RIGHT} ;
            ms_operator ["%lbrace"] = w ;
        }
        {
            OperatorProperties w = {PAREN, 21, RIGHT_TO_LEFT} ;
            ms_operator ["%rbrace"] = w ;
        }
    }

private :
    int     m_typeId ;
    bool    m_isSameOperator = false ;
    string  m_str ;
    TokenList[] m_vals ;
    TokenList   m_parent ;
    static int     m_numParenths = 0 ;

    void setString (string s)
    {
        m_str = s ;
        m_typeId = ID_STRING ;
        m_vals = null ;
    }

    void add_node (TokenList node)
    {
        if (m_typeId == ID_VOID)
        {
            m_typeId = ID_LIST ;
            m_vals = new TokenList [1] ;
            m_vals [0] = node ;
            return ;
        }
        if (m_typeId == ID_STRING)
        {
            string data = m_str ;
            m_typeId = ID_LIST ;
            m_vals = new TokenList [2] ;
            m_vals [0] = new TokenList (this, data) ;
            m_vals [1] = node ;
            return ;
        }
        //type_id == ID_LIST
        m_vals ~= node ;
    }

public :
    this ()
    {
        m_typeId = ID_VOID ;
        m_str = null ;
        m_vals = null ;
        m_parent = null ;
        return this ;
    }

    this (string s)
    {
        this () ;
        setString (s) ;
        return this ;
    }

    this (TokenList p)
    {
        this () ;
        m_parent = p ;
        return this ;
    }

    this (TokenList p, string s)
    {
        this () ;
        setString (s) ;
        m_parent = p ;
        return this ;
    }

    this (TokenList parent, TokenList leaf)
    {
        this () ;
        m_parent = parent ;
        m_typeId = ID_LIST ;
        m_vals = new TokenList [1] ;
        m_vals [0] = leaf ;
        return this ;
    }

    string toString ()
    {
        switch (m_typeId)
        {
            case ID_VOID :
                return "void" ;
            case ID_STRING :
                return m_str ;
            case ID_LIST :
            {
                string result = "(" ;
                foreach (i, val ; m_vals)
                {
                    result ~= val.toString () ;
                    if (i != m_vals.length - 1)
                        result ~= " " ;
                }
                result ~= ")" ;
                return result ;
            }
        }
    }

    string toD_String ()
    {
        switch (m_typeId)
        {
            case ID_VOID :
                return "void" ;
            case ID_STRING :
                return m_str ;
            case ID_LIST :
            {
                string result = "" ;
                if (m_vals.length >= 1)
                {
                    if (is_prefix_operator (m_vals [0]))
                    {
                        if (m_vals [0].m_str [0] == '%')
                            result ~= m_vals [0].m_str [3 .. $] ;
                        else
                            result = m_vals [0].m_str ;

                        if (m_vals.length != 2)
                            assert (false, "Prefix operator should have only one argument") ;
                        result ~= " " ~ m_vals [1].toD_String () ;
                    }
                    else
                    if (is_infix_operator (m_vals [0]))
                    {
                        string s = " " ~ m_vals [0].m_str ~ " ";
                        if (s == " %list ")
                            s = " " ;
                        if (s == " , " || s == " ; ")
                        {
                            foreach (i, val ; m_vals [1 .. $-1])
                            {
                                result ~= val.toD_String () ~ s ;
                            }
                            result ~= m_vals [$-1].toD_String () ;
                            if (m_vals [0].m_isSameOperator || m_vals.length == 2)
                                result ~= s ;
                        }
                        else if (s == " . ")
                        {
                            assert (m_vals.length == 3) ;
                            if (m_vals[1].m_typeId != ID_STRING || m_vals[2].m_typeId != ID_STRING)
                                goto l_next_condition ;
                            try
                            {
                                int a = to!int (m_vals [1].m_str) ;
                                result ~= m_vals [1].m_str ~ "." ~ m_vals [2].m_str ;
                            }
                            catch
                            {
                                goto l_next_condition ;
                            }
                        }
                        else
                        {
                        l_next_condition : ;
                            if (m_vals.length < 3)
                                assert (false, "Infix operator should have at list 2 arguments, operator:<"~
                                        m_vals[0].m_str~">, arguments.length:"~to!string(m_vals.length-1)) ;
                            foreach (i, val ; m_vals [1..$-1])
                            {
                                result ~= val.toD_String () ~ s;
                            }
                            result ~= m_vals [$-1].toD_String () ;
                            if (m_isSameOperator)
                                result ~= s ;
                        }
                    }
                    else
                    if (is_any_left_paren (m_vals [0]))
                    {
                        string s1, s2 ;
                        switch (m_vals [0].m_str)
                        {
                            case "%lparen"      : s1 = " (" ; s2 = " ) " ; break ;
                            case "%lbracket"    : s1 = " [" ; s2 = " ] " ; break ;
                            case "%lbrace"      : s1 = " {" ; s2 = " } " ; break ;
                        }
                        result ~= s1 ;
                        foreach (val ; m_vals [1 .. $])
                            result ~= " " ~ val.toD_String () ;
                        result ~= s2 ;
                    }
                    else
                    if (is_operator (m_vals [0])) // is postrix operator
                    {
                        if (m_vals.length != 2)
                            assert (false, "Postfix operator should have one argument") ;
                        result ~= m_vals [1].toD_String () ;
                        result ~= " " ~ m_vals [0].m_str [3..$] ;
                    }
                    else  // is data
                    {
                        result ~= " " ~ m_vals [0].toD_String () ;
                    }
                }
                //result ~= ")" ;
                return result ;
            }
        }
    }

    unittest
    {
        TokenList list = new TokenList ;

        list.setString ("123");
        assert (list.toString () == "123") ;

        list.m_typeId = ID_VOID ;
        assert (list.toString () == "void") ;

        list.m_typeId = ID_LIST ;
        list.m_vals = new TokenList [4] ;
        list.m_vals [0] = new TokenList ("+") ;
        list.m_vals [1] = new TokenList ("a") ;
        list.m_vals [2] = new TokenList () ;
        list.m_vals [2].m_typeId = ID_LIST ;
        list.m_vals [2].m_vals = new TokenList [3] ;
        list.m_vals [2].m_vals [0] = new TokenList ("*") ;
        list.m_vals [2].m_vals [1] = new TokenList ("b") ;
        list.m_vals [2].m_vals [2] = new TokenList ("c") ;
        list.m_vals [3] = new TokenList ("d") ;
        assert (list.toString () == "(+ a (* b c) d)", list.toString ()) ;
    }

    static bool is_operator (string s)
    {
        return (s in ms_operator) != null;
    }

    static bool is_operator (TokenList list)
    {
        if (list !is null && list.m_typeId == ID_STRING)
            return (list.m_str in ms_operator) != null ;
        return false ;
    }

    static bool is_prefix_operator (string s)
    {
        if ((s in ms_operator) is null)
            return false ;
        return ms_operator [s].type == PREFIX ;
    }

    static bool is_prefix_operator (TokenList list)
    {
        if (list !is null && list.m_typeId == ID_STRING)
            return is_prefix_operator (list.m_str) ;
        return false ;
    }

    static bool is_infix_operator (string s)
    {
        if ((s in ms_operator) is null)
            return false ;
        return ms_operator [s].type == INFIX ;
    }

    static bool is_infix_operator (TokenList list)
    {
        if (list !is null && list.m_typeId == ID_STRING)
            return is_infix_operator (list.m_str) ;
        return false ;
    }

    static bool is_any_left_paren (string s)
    {
        if ((s in ms_operator) is null)
            return false ;
        return ms_operator [s].type == PAREN && s [1] == 'l' ;
    }

    static bool is_any_left_paren (TokenList list)
    {
        if  (list !is null && list.m_typeId == ID_STRING && is_any_left_paren (list.m_str))
            return true ;
        return false ;
    }

    static private bool is_any_right_paren (string s)
    {
        if ((s in ms_operator) is null)
            return false ;
        return ms_operator [s].type == PAREN && s [1] == 'r' ;
    }

    static private bool is_any_right_paren (TokenList list)
    {
        if  (list !is null && list.m_typeId == ID_STRING && is_any_right_paren (list.m_str))
            return true ;
        return false ;
    }

    private TokenList add_d (string s)
    {
        //rule 1.0
        if (!is_operator (s))
        {
            // rule 1.1
            if (m_typeId == ID_STRING && !is_operator (m_str))
            {
                TokenList old_parent = this.m_parent ;
                TokenList new_parent = new TokenList (old_parent) ;
                new_parent.m_typeId = ID_LIST ;
                new_parent.m_vals.length = 0 ;
                new_parent.m_vals ~= new TokenList ("%list") ;
                new_parent.m_vals ~= this ;
                new_parent.m_vals ~= new TokenList (s) ;
                this = new_parent ;
                return this;
            }
            else if (m_typeId == ID_LIST && m_vals.length == 1 && !is_operator (m_vals [0]))
            {
                m_vals ~= m_vals [0] ;
                m_vals [0] = new TokenList ("%list") ;
                m_vals ~= new TokenList (s) ;
                return this ;
            }
            else if (m_typeId == ID_LIST && (
                m_vals.length == 2 && (is_prefix_operator (m_vals [0]) || is_any_left_paren (m_vals [0]))
                || m_vals.length >= 3 && is_infix_operator (m_vals [0]) && !m_isSameOperator))
            {
                this = add_d ("%list") ;
                this = add_d (s) ;
                return this ;
            }

            //rule 1.2
            add_node (new TokenList (this, s)) ;
            m_isSameOperator = false ;
            return this ;
        }
        //is operator:
        //rule 2.0
        if (s == "++" || s == "--")
        {
            if (m_typeId == ID_STRING )
            {
                if (! is_operator (m_str))
                {
                    TokenList old_parent = this.m_parent ;
                    if (old_parent is null)
                    {
                        old_parent = new TokenList (null, cast(TokenList)null) ;
                    }
                    TokenList new_parent = new TokenList (old_parent, new TokenList ("%o2" ~ s)) ;
                    new_parent.m_vals [0].m_parent = new_parent ;
                    new_parent.m_vals ~= this ;
                    this.m_parent = new_parent ;
                    old_parent.m_vals [0] = new_parent ;
                    this = old_parent ;
                    return this ;
                }
            }
            if (m_typeId == ID_LIST)
            {
                if (m_vals.length == 1 && !is_operator (m_vals [0]))
                {
                    auto cp_list = m_vals [0] ;
                    m_vals [0] = new TokenList (this, "%o2" ~ s) ;
                    m_vals ~= cp_list ;
                    return this ;
                }
                if (m_vals.length >= 2 && (is_prefix_operator (m_vals [0]) || is_any_left_paren (m_vals [0]))
                    || m_vals.length >= 3 && is_infix_operator (m_vals [0]) && !m_isSameOperator)
                {
                    TokenList data = m_vals [$-1] ;
                    m_vals [$-1] = new TokenList (this, new TokenList ("%o2" ~ s)) ;
                    m_vals [$-1].m_vals [0].m_parent = m_vals [$-1] ;
                    m_vals [$-1].add_node (data) ;
                    data.m_parent = m_vals [$-1] ;
                    return this ;
                }
            }
        }

        //rule 2.0.1
        if (is_any_left_paren (s))
        {
            if (m_typeId == ID_VOID || m_typeId == ID_LIST && m_vals.length == 0)
            {
                add_node (new TokenList (this, s)) ;
                ++ m_numParenths ;
                return this ;
            }
            if (m_typeId == ID_LIST && (
                    is_infix_operator (m_vals [0]) &&
                        (m_vals.length == 2  || m_vals.length >= 3 && m_isSameOperator)
                    || m_vals.length == 1 && (is_prefix_operator (m_vals [0]) || is_any_left_paren (m_vals [0]))
                    ) )
            {
                m_isSameOperator = false ;
                auto list = new TokenList (this) ;
                list.add_node (new TokenList (list, s)) ;
                add_node (list) ;
                ++ m_numParenths ;
                this = list ;
                return this ;
            }
            if (m_typeId == ID_LIST && (
                    m_vals.length >= 3 && is_infix_operator (m_vals [0]) && !m_isSameOperator
                    || m_vals.length == 2 && (is_prefix_operator (m_vals [0]) || is_any_left_paren (m_vals [0]))
                    ) )
            {
                 auto nl1 = new TokenList (this) ;
                 nl1.add_node (new TokenList (nl1, "%list")) ;
                 nl1.m_vals ~= m_vals [$-1] ;
                 nl1.m_vals [1].m_parent = nl1 ;
                 auto nl2 = new TokenList (nl1) ;
                 nl2.add_node (new TokenList (nl2, s)) ;
                 nl1.m_vals ~= nl2 ;
                 m_vals [$-1] = nl1 ;
                 ++ m_numParenths ;
                 this = nl2 ;
                 return this ;
            }

            if (m_typeId == ID_LIST && m_vals.length == 1 && !is_operator (m_vals [0]))
            {
                auto list = m_vals [0] ;
                m_vals [0] = new TokenList (this, "%list") ;
                m_vals ~= list ;
                auto c_list = new TokenList (this) ;
                c_list.add_node (new TokenList (c_list, s)) ;
                m_vals ~= c_list ;
                this = c_list ;
                ++ m_numParenths ;
                return this ;
            }
            assert (false, "AST error : this can't happen") ;
        }

        //todo: rule 2.0.2
        if (is_any_right_paren (s))
        {
            -- m_numParenths ;
            if (m_numParenths < 0)
                assert (false, "AST error : Too much rigth " ~ s) ;
        l_rule_2_0_2_local : ;  //horrible, but, eh... can be for (;;)
            if (m_typeId != ID_LIST
                || m_typeId == ID_LIST && (m_vals.length == 0 ||
                    m_vals.length >= 1 && !is_operator (m_vals [0]) ) )
                assert (0, "AST error : Too much rigth " ~ s) ;
            if (is_any_left_paren (m_vals [0]))
            {
                if (m_vals [0].m_str [2..$] != s [2..$])
                    assert (false, "AST error : no closing to "~m_vals [0].m_str ) ;
                if (m_parent !is null)
                {
                    this = m_parent ;
                }
                else
                {
                    m_parent = new TokenList (null, this) ;
                    this = m_parent ;
                }
                return this ;
            }
            if (m_parent is null)
                assert (0, "AST error : Too much rigth " ~ s) ;
            this = m_parent ;
            goto l_rule_2_0_2_local ;
            assert (0, "Can't be here") ;
        }

        //rule 2.1
        //todo:
        if (m_typeId == ID_LIST && m_vals.length >= 1 &&
                (is_infix_operator (m_vals [0]) &&
                    ( m_vals.length <= 2 || m_vals.length >= 3 && m_isSameOperator)
                || is_prefix_operator (m_vals [0]) && m_vals.length == 1)
                //&& !is_any_left_paren (m_vals [0])
            || m_typeId == ID_VOID || m_typeId == ID_LIST && m_vals.length == 0
            || m_typeId == ID_LIST && m_vals.length == 1 && is_any_left_paren (m_vals [0]) )
        {
            m_isSameOperator = false ;
            string new_op = "%o1" ~ s ;
            if ((new_op in ms_operator) == null)
                assert (false, "AST error - unknown operator " ~ new_op) ;
            auto new_op_list = new TokenList (this, new_op) ;
            if (m_typeId == ID_VOID)
            {
                add_node (new_op_list) ;
            }
            else
            {
                TokenList pre_list = new TokenList (this, new_op_list) ;
                new_op_list.m_parent = pre_list ;
                add_node (pre_list) ;
                this = pre_list ;
            }
            return this ;
        }

        //rule 2.2
    l_rule_2_2 : ;
        if (m_typeId == ID_STRING && !is_operator (this)
            || m_typeId == ID_LIST && m_vals.length == 1 && !is_operator (m_vals [0]))
        {
            TokenList swap ;
            if (m_typeId == ID_STRING)
            {
                swap = new TokenList (this, m_str) ;
            }
            else if (m_typeId == ID_LIST && m_vals.length == 1)
                swap = m_vals [0] ;
            add_node (swap) ;
            m_vals [0] = new TokenList (this, s) ;
            return this ;
        }

        //rule 2.2.1
        if (m_typeId == ID_LIST && (
                m_vals.length >= 3 && is_infix_operator (m_vals [0]) && !m_isSameOperator
                    /* && (s in ms_operator) != null  -- already tested */
                    && ms_operator [s].priority > ms_operator [this.m_vals [0].m_str].priority
                || m_vals.length >= 2 && is_prefix_operator (m_vals [0])
                        && ms_operator [s].priority > ms_operator [this.m_vals [0].m_str].priority
                || m_vals.length >= 2 && is_any_left_paren (m_vals [0]) )
            )
        {
            auto new_op_list = new TokenList (this, new TokenList (null, s)) ;
            new_op_list.m_vals [0].m_parent = new_op_list ;
            new_op_list.add_node (this.m_vals [$-1]) ;
            m_vals [$-1] = new_op_list ;
            this = new_op_list ;
            return this ;
        }

        //rule 2.3
        if (m_typeId == ID_LIST && m_vals.length >= 1 && is_operator (m_vals [0]) &&
            ms_operator [s].priority < ms_operator [m_vals [0].m_str].priority )
        {
            if (! is_any_left_paren (m_vals [0]))
            {
                if (m_parent is null)
                    m_parent = new TokenList (null, this) ;
                this = m_parent ;
                goto l_rule_2_2 ;
            }
        }

        //rule 2.4
        if (m_typeId == ID_LIST && m_vals.length >= 2)
        {
            auto val = m_vals [0] ;
            if (is_operator (val))
            {
                auto str = val.m_str ;
                auto this_op = ms_operator [s] ;
                auto curr_op = ms_operator [str] ;
                if (this_op.priority == curr_op.priority
                    && !is_any_left_paren (str) && !is_prefix_operator (str))
                {
                    if (this_op.direction != curr_op.direction)
                        assert (false,
"AST error : currently no support for operators with different directions to be equal in priority") ;
                    if (this_op.direction == RIGHT_TO_LEFT)
                    {
                        auto op_list = new TokenList (this, new TokenList (null, s)) ;
                        op_list.m_vals [0].m_parent = op_list ;
                        op_list.add_node (m_vals [$-1]) ;
                        op_list.m_vals [1].m_parent = op_list ;
                        m_vals [$-1] = op_list ;
                        this = op_list ;
                        return this ;
                    }
                    //direction == LEFT_TO_RIGHT
                    if (str != s)
                    {
                        if (m_parent is null)
                        {
                            m_parent = new TokenList (null, this) ;
                        }
                        this = m_parent ;
                        goto l_rule_2_2 ;
                    }
                    //rule 2.4 г
                    m_isSameOperator = true ;
                    return this ;
                }
            }
        }
        assert (0, "AST no matching rule to \"" ~ s ~ "\"") ;
        //return this ;
    }

    static TokenList parseD (string s)
    {
        /+  PREUDOCODE
        int ws = -1 ;
        for (int i = 0 ; i < s.len ;)
        {
            skip_space () ;
            skip_comments () ;
            if (if_nameable (s [i]) )
                ws = i ;
                do_while_nameabe (s [i]) ;
                 ++i;
            word = s [ws .. i] ;
            add_d (word)
            continue ;

            if (is_first_operator_symbol (s[i]))
                max_op = s [i]
                while max_op + s[i+1] in operators
                    max_op ~= s [i+1]
                    ++i ;
            add_d (max_op) ;
        }
        +/

        bool is_nameable (char c)
        {
            immutable byte [] symbs =
            [
                '_', '@', '$'
            ] ;
            bool result = false ;
            if ('a' <= c && c <= 'z')
                result = true ;
            if ('A' <= c && c <= 'Z')
                result = true ;
            if ('0' <= c && c <= '9')
                result = true ;
            foreach (i ; symbs)
                if (c == i)
                {
                    result = true ;
                    break ;
                }
            return result ;
        }

        bool is_first_operator_symbol (char c)
        {
            immutable ubyte [] symbs =
            [
                ';', ',', '=', '?', ':', '|', '&',
                '^', '<', '>', '!', '+', '-', '*', '/', '%', '~', '.',
                '[', ']', '(', ')', '{', '}',
            ] ;
            foreach (v ; symbs)
                if (c == v)
                    return true ;
            return false ;
        }

        auto list = new TokenList () ;
        list.m_typeId = ID_VOID ;
        list.m_str = null ;
        list.m_vals = null ;

        int ws = -1 ;
        for (int i = 0 ; i < s.length ;)
        {
            while (i < s.length && isspace (s [i]))
                ++ i ;

            //TODO : skip_comments () ;

            if (i < s.length && is_nameable (s [i]) )
            {
                ws = i ;
                ++i ;
                while (i < s.length && is_nameable (s [i]) )
                    ++i ;
                string word = s [ws .. i] ;
                list = list.add_d (word) ;
                continue ;
            }

            if (i < s.length && is_first_operator_symbol (s[i]))
            {
                string max_op = "" ~ s [i] ;
                ++ i ;
                while (i < s.length && (max_op ~ s[i]) in ms_operator)
                {
                    max_op ~= s [i] ;
                    ++i ;
                }
                switch (max_op)
                {
                    case "(" : max_op = "%lparen" ; break ;
                    case ")" : max_op = "%rparen" ; break ;
                    case "[" : max_op = "%lbracket" ; break ;
                    case "]" : max_op = "%rbracket" ; break ;
                    case "{" : max_op = "%lbrace" ; break ;
                    case "}" : max_op = "%rbrace" ; break ;
                    default : break ;
                }
                list = list.add_d (max_op) ;
                continue ;
            }
        }

        while (list.m_parent !is null)
            list = list.m_parent ;
        return list ;
    }

    unittest
    {
        TokenList test ; //= new TokenList () ;

        test = TokenList.parseD ("++a . b * c") ;
        assert (test.toString () == "(* (%o1++ (. a b)) c)") ;

        test = TokenList.parseD ("a + b * c") ;
        assert (test.toString () == "(+ a (* b c))") ;

        test = TokenList.parseD ("a + b + * c") ;
        assert (test.toString () == "(+ a b (%o1* c))") ;

        test = TokenList.parseD ("a + b * c * d") ;
        assert (test.toString () == "(+ a (* b c d))") ;

        test = TokenList.parseD ("a + b + c") ;
        assert (test.toString () == "(+ a b c)") ;

        test = TokenList.parseD ("a * b + c") ;
        assert (test.toString () == "(+ (* a b) c)") ;

        test = TokenList.parseD ("a * (b + c) ") ;
        assert (test.toString () == "(* a (%lparen (+ b c)))") ;

        test = TokenList.parseD ("a + b c ") ;
        assert (test.toString () == "(+ a (%list b c))") ;

        test = TokenList.parseD ("a . b c ") ;

        assert (test.toString () == "(%list (. a b) c)") ;
        test = TokenList.parseD ("a * (b + c / d ++ ) ") ;
        assert (test.toString () == "(* a (%lparen (+ b (/ c (%o2++ d)))))") ;

        test = TokenList.parseD ("a ++") ;
        assert (test.toString () == "(%o2++ a)") ;

        test = TokenList.parseD ("(a ++)") ;
        assert (test.toString () == "((%lparen (%o2++ a)))", test.toString ()) ;

        test = TokenList.parseD (" + a") ;
        assert (test.toString () == "(%o1+ a)") ;

        test = TokenList.parseD ("{abb + (x+c); c, ++d.x ;d ; e+f ; if (x = 1) x + 1 ;}") ;
        assert (test.toString () == "((%lbrace (; (+ abb (%lparen (+ x c))) (, c (%o1++ (. d x))) " ~
            "d (+ e f) (+ (%list if (%lparen (= x 1)) x) 1))))", test.toString ()) ;
        //writeln (test.toD_String ()) ;

        test = TokenList.parseD ("a [] + b") ;
        assert (test.toString () == "(+ (%list a (%lbracket)) b)") ;

        test = TokenList.parseD ("a + b []") ;
        assert (test.toString () == "(+ a (%list b (%lbracket)))") ;

        test = TokenList.parseD ("a . b []") ;
        assert (test.toString () == "(. a (%list b (%lbracket)))") ;

        test = TokenList.parseD ("(a b)") ;
        assert (test.toString () == "((%lparen (%list a b)))") ;

        test = TokenList.parseD ("a++ . b") ;
        assert (test.toString () == "(. (%o2++ a) b)") ;

        test = TokenList.parseD ("++a . b") ;
        assert (test.toString () == "(%o1++ (. a b))") ;

        test = TokenList.parseD ("++a ; b ;") ;
        assert (test.toString () == "(; (%o1++ a) b)" && test.m_isSameOperator) ;

        test = TokenList.parseD ("+ +a ") ;
        assert (test.toString () == "(%o1+ (%o1+ a))") ;

        test = TokenList.parseD ("i = 1:1:10, if(i % 2 == 0); i*i +1") ;
        assert (test.toString () == "(; (, (= i (: 1 1 10)) (%list if (%lparen (== (% i 2) 0)))) " ~
            "(+ (* i i) 1))") ;
        //writeln (test.toD_String ()) ;

        test = TokenList.parseD ("(i, x):a; x>0") ;
        assert (test.toString () == "(; (: (%lparen (, i x)) a) (> x 0))") ;

        //!!!
        /+
        test = TokenList.parseD ("function float () { float sum_ ; for (int i = 0 ; i < n ; ++i){ sum_ += i*j ; } return sum_ ;  }") ;
        writeln ("Before:\n" ~ "function float () { float sum_ ; for (int i = 0 ; i < n ; ++i){ sum_ += i*j ; } return sum_ ;  }" ~
                 "\nAfter:\n" ~ test.toD_String () ~
                 "\nAST:\n" ~ test.toString ()) ;
        +/
    }

    string getStringItem (int n)
    {
        assert (m_typeId == ID_LIST, "AST error : expected ID_LIST argument, but found "
                ~ (m_typeId == ID_VOID ? "ID_VOID" : "ID_STRING") ) ;
        assert (m_vals.length > n, "AST error : index out of bounds") ;
        assert (m_vals [n].m_typeId == ID_STRING, "AST error : List should be of type string") ;
        return m_vals [n].m_str ;
    }

    TokenList getItem (int n)
    {
        assert (m_typeId == ID_LIST, "AST error : expected ID_LIST argument, but found "
                ~ (m_typeId == ID_VOID ? "ID_VOID" : "ID_STRING") ) ;
        assert (m_vals.length > n, "AST error : index out of bounds") ;
        return m_vals [n] ;
    }

    @property int typeId ()
    {
        return m_typeId ;
    }

    @property bool isEndSeparator ()
    {
        return m_isSameOperator ;
    }

    @property string str ()
    {
        assert (m_typeId == ID_STRING, "AST error : expected list m_typeId to be ID_STRING") ;
        return m_str ;
    }

    @property int length  ()
    {
        assert (m_typeId == ID_LIST, "AST error : expected list m_typeId to be ID_LIST") ;
        return m_vals.length ;
    }

    TokenList opIndex(int idx)
    {
        return getItem (idx) ;
    }

    TokenList opSlice ()
    {
        return this ;
    }
    TokenList[] opSlice (int a, int b)
    {
        assert (this.typeId == ID_LIST) ;
        assert (0<=a && a < this.length) ;
        assert (0<=b && b <= this.length) ;
        return this.m_vals [a .. b] ;
    }


}
