//          Copyright Alex Dovhal 2010.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import core.runtime ;
import std.c.windows.windows ;
import std.stdio ;
import std.file ;
import std.conv ;
import std.random ;
import std.process ;
import std.string ;
import std.c.stdlib : exit ;
import core.stdc.ctype ;
//import std.algorithm, std.range, std.array ;

import plugin_init, plugin_math, plugin_list_comprehension ;

Random rndGenerator ;


void initPlugins ()
{
    assert (0) ;
}

bool isFirstNameChar (int c)
{
    return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')
        /*||  ('0' <= c && c <= '9')*/ || c == '_' || c == '@' ;
}

bool isNameChar (int c)
{
    return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')
        ||  ('0' <= c && c <= '9') || c == '_' ;
}

bool parseCode (string fname, string s, int lineNo, out string outCode)
{
    bool isChanged = false ;
    int ws = -1 ; //start index of the word
    bool inWord = false ;
    bool inPhrase = false ;
    int n = s.length ;
    int startIdx = 0, endIdx = 0 ;
    string word ;
    word.length = 0 ;
    int macroLineNo ;

l_main_loop :
    for (int i = 0 ; i < n ; )
    {
        bool skipSimpleString ()
        {
            if (i >= n)
                return false ;
            int c = s [i] ;
            if (c != '\'' && c != '"' && c != '`')
                return false ;
            ++ i ;
            int numSlashes = void ;
            while (i < n && s [i] != c)
            {
                if (s [i] != '\\')
                {
                    ++ i ;
                    continue ;
                }
                ++i ;
                numSlashes = 1 ;
                while (i < n && s [i] == '\\')
                {
                    ++i ;
                    ++numSlashes ;
                }
                if (numSlashes % 2 == 1 && s [i] == c)
                    ++ i ;
            }
            if (i == n)
                assert (0, "No matching " ~ cast(char)c) ;
            ++ i ;
            return true ;
        }

        bool skipString ()
        {
            bool done = skipSimpleString () ;
            if (done)
                return true ;
            if (i >= n - 2)
                return false ;
            if (!(s[i] == 'q' && s [i+1] == '{'))
                return false ;
            i += 2 ;
            int c ;
            int numBraces = 1 ;
            for (;;)
            {
                while (i < n && (c = s [i]) != '\'' && c != '"' && c != '`')
                {
                    if (c == '{')
                    {
                        ++numBraces ;
                        ++i ;
                        continue ;
                    }
                    if (c == '}')
                    {
                        --numBraces ;
                        ++i ;
                        if (numBraces == 0)
                            return true ;
                        continue ;
                    }
                    ++i ;
                }
                if (i >= n)
                    assert (0, "No matching } to q{") ;
                skipSimpleString () ;
            }
        }

        bool skipSpace ()
        {
            if (i >= n)
                return false ;
            int c = s [i] ;
            int j = i ;
            while (c == ' ' || c == '\t' || c == '\r')
            {
            l_skip_space : ;
                ++ i ;
                if (i == n)
                    return true ;
                c = s [i] ;
            }
            if (c == '\n')
            {
                ++ lineNo ;
                goto l_skip_space ;
            }
            return j != i ;
        }

        bool skipComment ()
        {
            int j = i ;

            if (i >= n)
                return false ;
            int c = s [i] ;
            if (c == '/')
            {
                ++i ;
                if (i == n)
                {
                    --i ;
                    return false ;
                }
                c = s [i] ;
                // skip - // ... \n
                if (c == '/')
                {
                    ++ i ;
                    if (i == n)
                        return true ;
                    //c = s [i] ;
                    while (s [i] != '\n')
                    {
                        ++ i ;
                        if (i == n)
                            return true ;
                        //c = s [i] ;
                    }
                    ++lineNo ;
                    ++i ;
                }
                else
                if (c == '*')
                {
                    ++i ;
                    while (i < n && ! ((s [i] == '*') && (s [i+1] == '/')) )
                        ++ i ;
                    i += 2 ;
                }
                else
                if (c == '+')
                {
                    ++i ;
                    while (i < n && ! ((s [i] == '+') && (s [i+1] == '/')) )
                        ++ i ;
                    i += 2 ;
                }
                else
                    -- i ;
            }
            //if (i == n)
            return j != i;
        }

        bool skipEmptyAndComment ()
        {
            int j = i ;
            bool skippedSpace   = false ;
            bool skippedComment = false ;
            do
            {
                skippedSpace   = skipSpace   () ;
                skippedComment = skipComment () ;
            }while (skippedSpace || skippedComment) ;
            return j != i ;
        }

        bool skipEmptyAndCommentAndString ()
        {
            int j = i ;
            bool skippedSpace   = false ;
            bool skippedComment = false ;
            bool skippedString  = false ;
            do
            {
                skippedSpace   = skipSpace   () ;
                skippedComment = skipComment () ;
                skippedString  = skipString  () ;
            }while (skippedSpace || skippedComment || skippedString) ;
            return j != i ;
        }

        /+NOTE: here wrong function, because of weak syntax parser we make this trick - code is parsed even in strings+/
        //skipEmptyAndCommentAndString () ;
        skipEmptyAndComment () ;

        if (i >= n)
            //continue ;
            break ;
        int c = s [i] ;
        if (c == '@')
        {
            int pos = i ;
            ++i ;
            if (! skipString ())
            {
                --i ;
                goto l_next_rule ;
            }

            //found string
            string str = s [pos..i] ;
            string result ;
            result.reserve (str.length) ;

            char postfix = 0 ;
            if (i<n && s[i]=='c' || s[i]=='w' || s[i]=='d')
                postfix = s[i] ;
            string strOpen ;
            string strClose ;

            sizediff_t startPos ;
            if (s[pos] == 'q')
            {
                strOpen = "q{" ;
                strClose = "}" ;
                startPos = 3 ;
            }
            else
            {
                strOpen ~= s [pos+1] ;
                strClose = strOpen ;
                startPos = 2 ;
            }

            if (postfix)
            {
                strClose ~= postfix ;
            }

            //result ~= strOpen~strClose ;
            for (int j=startPos ; j<str.length-1; ++j)
            {
                if (str [j]=='$' && isalpha(str[j+1]))
                {
                    int namePos = j ;
                    do
                    {
                        ++j ;
                    }
                    while (j<str.length && isalnum(str[j])) ;
                    string name = str [namePos..j] ;
                    if (result.length != 0)
                        result ~= "~" ;
                    result ~= strOpen~str [startPos..namePos]~strClose~"~to!string("~str[namePos+1..j]~")" ;
                    startPos = j ;
                    --j ;
                    continue ;
                }
                if (str [j]=='$' && str [j+1] == ';')
                {
                    if (result.length != 0)
                        result ~= "~" ;
                    result ~= strOpen~str [startPos..j+1]~strClose ;
                    ++j ;
                    startPos = j+1 ;
                    continue ;
                }
                //TODO: find matching parenthesis
                if (str [j]=='$' && str[j+1]=='(')
                {

                }
            }
            if (result.length != 0)
                result ~= "~" ;
            result ~= strOpen~str [startPos..str.length-1]~strClose ;
            isChanged = true ;
            outCode ~= s [startIdx .. pos] ~ result ;
            startIdx = i ;
            continue l_main_loop ;
        }
l_next_rule : ;
        if (isFirstNameChar (c))
        {
            if (!inPhrase)
                endIdx = i ;
            ws = i ;

            while (i < n && isNameChar (s [i]))
                ++ i ;
            if (!inPhrase)
                word = s [ws..i] ;
            else
                word ~= s [ws..i] ;

            if ((word in g_names) != null)
                macroLineNo = lineNo ;

            skipEmptyAndComment () ;
            if (i == n)
                //return ;
                continue ;
            c = s [i] ;
            if (c == '.')
            {
                word ~= c ;
                ++ i ;
                inPhrase = true ;
                continue l_main_loop ;
            }
            if (c == '!' && (word in g_names) !is null)
            {
                ++ i ;
                skipEmptyAndComment () ;

                if (i >= n)
                    continue ;
                c = s [i] ;
                if (c == '{') // (word in g_names) !is null)
                {
                    ++i ;
                    int textStart = i ;
                    int numBraces = 1 ;
                    for (;;)
                    {
                        if (i >= n)
                            assert (0, "Expected } but found EOF") ;
                        if (!skipEmptyAndCommentAndString ())
                        {
                            c = s [i] ;
                            if (c == '{')
                            {
                                ++numBraces ;
                                ++i ;
                                continue ;
                            }
                            if (c == '}')
                            {
                                --numBraces ;
                                ++i ;
                                if (numBraces == 0)
                                    break ;
                                continue ;
                            }
                            ++ i ;
                        }

                    }

                    outCode ~= s [startIdx .. endIdx] ;
                    startIdx = i ;
                    isChanged = true ;

                    string textIn = s [textStart .. i-1] ;
                    string textMid ;

                    /+NOTE: here order callPlugin and parseCode is reversed because of weak syntax parser
                      with better parser we should change this.+/
                    callPlugin (fname, word, textIn, lineNo, textMid) ;
                    string textOut ;
                    parseCode (fname, textMid, lineNo, textOut) ;

                    //parseCode (fname, textIn, lineNo, textMid) ;
                    //string textOut ;
                    //callPlugin (fname, word, textMid, lineNo, textOut) ;


                    string newLines ;
                    foreach (j ; 0 .. lineNo-macroLineNo)
                        newLines ~= "\n" ;
                    textOut = textOut.replace ("\n", " ").replace("\r", "") ;
                    outCode ~= textOut ~ newLines ;
                    continue l_main_loop ;
                }
            }
            continue l_main_loop ;
        }
        if (inPhrase)
        {
            inPhrase = false ;
            word.length = 0 ;
        }
        ++ i ;
    }
    outCode ~= s [startIdx .. n] ;
    return isChanged ;
}

version (none)
{

void loadDll (PluginInfo* plugInfo)
{
    FARPROC loadDLL_Function (string dllFuncName)
    {
//        FARPROC fp = GetProcAddress (plugInfo.handle, toStringz (dllFuncName));
//        if (fp is null)
//        {
//            writeln ("error loading symbol " ~ dllFuncName) ;
//            exit (1) ;
//        }
//        return fp ;
        return null ;
    }

//    plugInfo.handle = cast(HMODULE) Runtime.loadLibrary (plugInfo.dllName) ;
//    if (plugInfo.handle is null)
//    {
//        writeln ("Error loading " ~ plugInfo.dllName) ;
//        exit (1) ;
//    }

    plugInfo.shortInfo = cast (string    function ()) loadDLL_Function ("D4math15pluginShortInfoFZAya") ;
    plugInfo.fullInfo  = cast (string [] function()) loadDLL_Function ("D4math14pluginFullInfoFZAAya") ;
    plugInfo.command   = cast (int function (string, string, int, string, out string))
        loadDLL_Function ("D4math13pluginCommandFAyaAyaiAyaJAyaZi") ;

    plugInfo.loaded = true ;
}

}

void callPlugin (string fileName, string commandName, string textIn, int lineNo, out string textOut)
{
    assert ((commandName in g_names ) !is null, "Error : no command " ~ commandName
        ~ " found in any installed plugins" ) ;
    assert ((g_names [commandName] in g_plugin) !is null, "Error : no dll info found") ;

    auto plugInfo = g_plugin [g_names [commandName]] ;

    //TODO : for DLL
    //if (!plugInfo.loaded)
    //    loadDll (plugInfo) ;

    plugInfo.command (fileName, commandName, lineNo, textIn, textOut) ;
}

/**
 * Create temporary file,
 * Params:
 *     tempName - string containing temporary file's name format
 *     every symbol % in it would be changed to temporary value
 * Returns:
 *     created temporary file's name
*/
string makeTempFile (string tempName)
{
    string fname ;
    fname.length = tempName.length ;
    fname.length = 0 ;
    do
    {
        foreach (c ; tempName)
        {
            if (c != '%')
            {
                fname ~= c ;
                continue ;
            }
            char a = cast(char) uniform (0, 36, rndGen) ;
            if (a < 10)
                a += '0' ;
            else
                a += 'a' - 10 ;
            fname ~= a ;
        }
    } while (exists (fname)) ;
    std.file.write (fname, "") ;
    return fname ;
}

int main (string[] args)
{
    string[] tempFileNames ;
    scope (exit)
    {
        foreach (fname ; tempFileNames)
        {
            string realName = fname [0..$-7] ~ ".d" ;
            version (Windows)
            {
                system ("copy " ~ fname ~ " " ~ realName) ;
                remove (fname) ;
            }
        }
        foreach (plugInfo ; g_plugin)
        {
            //TODO : uncomment it when DLLs are usable
//            if (plugInfo.loaded)
//                if (!Runtime.unloadLibrary (plugInfo.handle))
//                {
//                    writeln ("error freeing " ~ plugInfo.dllName);
//                    exit (1) ;
//                }
        }
    }

    //if (args.length >= 2 && args [1] == "--dpp-reconf")
    //{
        //TODO : generate new plugins.conf
        //algorithm:
        //read plugins directory
        //load all plugins
        //from every plugin load all names(short) it contains
        //    add that names to AA. if AA already contains that name
        //    change it with pluginName.name
        //    if thatPluginName != "none" then
        //        change that name to thatPluginName.name
        //        add names [name] = "none" ;
        //

    //    return 0 ;
    //}

    //initPlugins () ;

    foreach (arg; args [1..$])
    {
        if (!(arg [$-2..$] == ".d" ) ) //&& arg [$-3..$] == ".di"))
            continue ;
        if (!exists (arg))
            assert (0, "File \"" ~ arg ~ "\" doesn't exist") ;

        string s = cast(string)read (arg) ; //no UNICODE right now
        string outCode ;
        bool changed = parseCode(arg, s, 0, outCode) ;
        if (changed)
        {
            tempFileNames ~= makeTempFile (arg [0 .. $-2] ~ ".%%%%.d") ;
            std.file.write (tempFileNames [$-1], s) ;
            std.file.write (arg, outCode) ;
            std.file.write (arg [0..$-2] ~ ".result.d" , outCode) ;

        }
    }

    string dmdArgs = "" ;
    foreach (arg ; args [1..$])
    {
        dmdArgs ~= arg ~ " " ;
    }

    writeln("Start compiler") ;
    system ("dmd " ~ dmdArgs ) ; //~ "1>" ~ file_out ~ "2>" ~ file_err) ;
    writeln("Compiler finished") ;

    return 0 ;
}
