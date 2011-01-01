//          Copyright Alex Dovhal 2010.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module plugin_math ;

private import std.conv, std.string ;
private import plugin_init ;
private import ast_parser ;
private import std.stdio ;

/*private*/ string g_pluginDLL = (.stringof) ~ ".dll" ;
/*private*/ string g_pluginName = (.stringof) ;

public immutable string[] pluginNames = [
    "sum", "prod",
    "min", "max",
    "forAll", "forAny", "forNone",
    "f"
] ;

static this ()
{
    auto p = new PluginInfo ;

    (*p).init (g_pluginDLL, //null, null, null, null ) ;
            &pluginShortInfo, &pluginFullInfo, &pluginCommand, &pluginGetAllNames) ;

    g_plugin [g_pluginDLL] = p ;

    string [] pluginNames = pluginGetAllNames() ;
    foreach (i ; 0 .. pluginNames.length)
    {
        g_names [pluginNames [i]] = g_pluginDLL ;
    }
}

int pluginCommand (string filename, string command, int lineNo, string textIn, out string textOut)
{
    bool equals (string s1, string s2)
    {
        return s1 == s2 || s1 == g_pluginName ~ "." ~ s2 ;
    }
    string ctfe_buildPlugins ()
    {
        string result ;
        foreach (name ; pluginNames)
        {
            result ~= "if (equals (command,\"" ~ name ~ "\")) return plugin_"
                ~ name ~ "(filename, lineNo, textIn, textOut) ;" ;
        }
        return result ;
    }

    mixin (ctfe_buildPlugins ());
    assert (false) ;
}

string pluginShortInfo ()
{
    return "PluginName, v0.1, 01.12.2010" ;
}

string[] pluginFullInfo ()
{
    string[] info ;
    info ~= "PluinName" ;
    info ~= "v0.1" ;
    info ~= "(date project start)" ;
    info ~= "(last version date)" ;
    info ~= "Authors : ..." ;
    info ~= "License" ;
    info ~= "misc" ;
    return info ;
}

/**
 * Returns:
 *      names of all commands that this plugin contains
 */
//version (deprecated)
//{
string[] pluginGetAllNames ()
{
    string[] lnames ;
    foreach(name; pluginNames)
        lnames ~= name ;
    return lnames ;
}
//}

//Plugin body for sum, prod:
int plugin_template_sum_prod (string filename, int lineNo, string textIn, out string textOut,
    string accummulateVarName, string initValue, string updateFunct)
{
    string AST_ERROR_STR = "Sum AST error : incorrect sum syntax" ;
    string[] loop_var   ;
    string[] loop_start ;
    string[] loop_end   ;
    string[] loop_inc   ;
    string[] loop_cond  ;
    string[] loop_body  ;
    int[]    loop_type  ; //0 - sum!{i=0:n;...} for, 1 - sum!{i:a;...} foreach(i;a)

    auto ast = TokenList.parseD (textIn) ;
    assert (ast.length >= 3, AST_ERROR_STR) ;
    assert (ast.getStringItem (0) == ";", "Sum AST error : sum must be separeted by semicolons") ;

    foreach (i ; 1 .. ast.length - 1)
    {
        auto arg = ast.getItem (i) ;
        TokenList ast_cycle ;
        if (arg.getStringItem (0) == ",")
        {
            ast_cycle = arg.getItem (1) ;
            //loop_cond ~= arg.getItem (2).toD_String () ;
            string fullCondition ;
            foreach (j, cond ; arg [2..arg.length])
            {
                fullCondition ~= "("~cond.toD_String ()~")" ;
                if (j != arg.length - 3)
                    fullCondition ~= "&&" ;
            }
            loop_cond ~= fullCondition ;
        }
        else
        {
            loop_cond ~= null ;
            ast_cycle = arg ;
        }

        //assert (ast_cycle.getStringItem (0) == "=", AST_ERROR_STR) ;
        //loop_var ~= ast_cycle.getStringItem (1) ;
        if (ast_cycle.getStringItem (0) == "=")
        {
            loop_var ~= ast_cycle.getStringItem (1) ;
            loop_type ~= 0 ;
            // (: 1 1 10)
            // (: 1 10)
            ast_cycle = ast_cycle.getItem (2) ;
            assert (ast_cycle.getStringItem (0) == ":", AST_ERROR_STR) ;
            loop_start ~= ast_cycle.getItem (1).toD_String () ;
            if (ast_cycle.length == 4)
            {
                loop_inc ~= ast_cycle.getItem (2).toD_String () ;
                loop_end ~= ast_cycle.getItem (3).toD_String () ;
            }
            else
            if (ast_cycle.length == 3)
            {
                loop_inc ~= null ;
                loop_end ~= ast_cycle.getItem (2).toD_String () ;
            }
            else
                assert (0, AST_ERROR_STR) ;
        }
        else
        if (ast_cycle.getStringItem (0) == ":")
        {
            assert (ast_cycle.length == 3, AST_ERROR_STR) ;
            auto astVar = ast_cycle.getItem (1) ;
            if (astVar.typeId == ID_STRING)
                loop_var ~= astVar.toD_String () ;
            else
            {
                //TODO: this is first try, make it full!!!
                if (astVar.typeId == ID_LIST && astVar.length >= 2
                    && astVar.getStringItem (0) == "%lparen")
                {
                    auto astVarNames = astVar.getItem(1) ;
                    assert (astVarNames.getStringItem(0) == ",") ;
                    string decls ;
                    foreach (ind, item ; astVarNames [1 .. astVarNames.length])
                    {
                        decls ~= item.toD_String ;
                        if (ind != astVarNames.length - 2)
                            decls ~= "," ;
                    }
                    loop_var ~= decls ;
                }
                else
                    assert (0) ; //astError ("incorrect syntax") ;



            }
            loop_type ~= 1 ;
            loop_start ~= ast_cycle.getItem (2).toD_String () ;
        }
    }
    //init astBody
    auto astBody = ast.getItem (ast.length-1) ;
    if (astBody.typeId == ID_LIST && astBody.length >= 3
        && astBody.getItem(0).typeId == ID_STRING && astBody.getStringItem(0) == ",")
    {
        foreach (i; 1..astBody.length)
        {
            loop_body ~= astBody.getItem(i).toD_String () ;
        }
    }
    else
        loop_body ~= ast.getItem (ast.length - 1).toD_String () ;
    //function to be used in replace(...), to parse array of strings and nulls.
    string to_string (string[] arr)
    {
        string result = "[" ;
        foreach (i, val ; arr)
        {
            if (val !is null)
                result ~= "q{"~val~"}" ;
            else
                result ~= "null" ;
            if (i < arr.length - 1)
                result ~= "," ;
        }
        result ~= "]" ;
        return result ;
    }
    //function to be used in replace(...), to parse array of ints and nulls.
    string to_string2 (int[] arr)
    {
        string result = "[" ;
        foreach (i, val ; arr)
        {
            result ~= to!string(val) ;
            if (i < arr.length - 1)
                result ~= "," ;
        }
        result ~= "]" ;
        return result ;
    }

    string result =
q{mixin(delegate string () {
    auto accum_i = new string [$ast.length - 2] ;
    string[] loop_var = $loop_var ;
    string[] loop_cond = $loop_cond ;
    string[] loop_start = $loop_start ;
    string[] loop_inc = $loop_inc ;
    string[] loop_end = $loop_end ;
    string[] loop_body = $loop_body ;
    int[]    loop_type = $loop_type ;
    string returnType = delegate string () {$loop_var_decl return typeof($last_loop_body).stringof ;} () ;
    string result = "delegate " ~ returnType ~ "(){" ;
    foreach (i ; 0 .. $ast.length - 2)
    {
        accum_i [i] = "$accummulateVarName" ~ to!string (i) ;
        result ~= returnType ~ " " ~ accum_i [i] ~ "=cast("~returnType~")("~$initValue~");" ;
        if (loop_type [i] == 0)
        {
            result ~= "for(int " ~ loop_var [i] ~ "=" ~ loop_start [i] ~ ";" ~ loop_var [i] ~ "<" ~ loop_end [i] ~ ";" ;
            if (loop_inc [i] is null)
                result ~= "++" ~ loop_var [i] ;
            else
                result ~= loop_var [i] ~ "+=" ~ loop_inc [i] ;
            result ~= "){" ;
        }
        else if (loop_type [i] == 1)
        {
            result ~= "foreach("~loop_var [i]~";"~loop_start [i]~"){" ;
        }
        else
            assert (0, "not allowed loop_type") ;
        if (loop_cond [i] !is null)
        {
            result ~= "if(" ~ loop_cond [i] ~ "){" ;
        }
        if (i == $ast.length - 3)
        {
            foreach (k ; 0..loop_body.length-1)
                result ~= loop_body [k] ~ ";" ;
            result ~= $updateFunct.replace("$accum", accum_i [i]).replace("$elem", loop_body [$-1])
                .replace("$returnType", returnType) ;
            if (loop_cond [i] !is null)
                result ~= "}" ;
            result ~= "}" ;
        }
    }
    foreach_reverse (i ; 0 .. $ast.length - 3)
    {
        result ~= $updateFunct.replace("$accum", accum_i [i]).replace("$elem", accum_i [i+1])
            .replace("$returnType", returnType) ;
        if (loop_cond [i] !is null)
            result ~= "}" ;
        result ~= "}" ;
    }
    result ~= " return " ~ accum_i [0] ~ ";}()" ;
    return result ;
}())}
.replace ("    ", " ").replace ("   ", " ")
.replace ("$ast.length", to!string(ast.length))
.replace ("$accummulateVarName", accummulateVarName)
.replace ("$initValue", initValue)
.replace ("$updateFunct", "\""~to!string(updateFunct)~"\"")
.replace ("$loop_var_decl",
    delegate string ()
    {
        string result ;
        foreach (var; loop_var)
            result ~= "int " ~ var ~";" ;
        foreach (i ; 0..loop_body.length-1)
            result ~= loop_body [i] ~ ";" ;
        return result ;
    }()
)
.replace ("$loop_var", to_string(loop_var) )
.replace ("$loop_cond", to_string(loop_cond) )
.replace ("$loop_start", to_string(loop_start) )
.replace ("$loop_inc", to_string(loop_inc) )
.replace ("$loop_end", to_string(loop_end) )
.replace ("$loop_type", to_string2(loop_type) )
.replace ("$loop_body", to_string(loop_body) )
.replace ("$last_loop_body", loop_body[$-1] )
    ;

    textOut = result ;
    return 0 ;
}

//Plugin sum:
int plugin_sum (string filename, int lineNo, string textIn, out string textOut)
{
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "sum_", "q{0}", "$accum += $elem ;") ;
}

//Plugin prod:
int plugin_prod (string filename, int lineNo, string textIn, out string textOut)
{
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "prod_", "q{1}", "$accum *= $elem ;") ;
}

//Plugin min
int plugin_min (string filename, int lineNo, string textIn, out string textOut)
{
    //todo: change real to $returnType, real.infinity to $returnType.max
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "min_",
/+initValue=+/ q{delegate string (){
    if(is(typeof(returnType)==float)||is(typeof(returnType)==double)||is(typeof(returnType)==real))
        return returnType~".infinity" ;
    return returnType~".max" ;
}()}.replace ("    ", " "),
        q{{$returnType save = $elem ; if ($accum > save) $accum = save ;}}) ;
}

//Plugin max
int plugin_max (string filename, int lineNo, string textIn, out string textOut)
{
    //todo: change real to $returnType
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "max_",
/+initValue=+/ q{delegate string (){
    if(is(typeof(returnType)==float)||is(typeof(returnType)==double)||is(typeof(returnType)==real))
        return "-"~returnType~".infinity" ;
    return returnType~".min" ;
}()}.replace ("    ", " "),
        q{{$returnType save = $elem;if ($accum < save) $accum = save ;}}) ;
}

//TODO: add forAll, forAny

//Plugin forAll
int plugin_forAll (string filename, int lineNo, string textIn, out string textOut)
{
    //todo: change real to $returnType
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "forAll_",
/+initValue=+/ "q{true}",
q{ if (!is($returnType==bool)) assert(0,q{forAll body must be boolean, not $returnType});
            if (!($elem)) return false; }
    ) ;
}

//Plugin forAny
int plugin_forAny (string filename, int lineNo, string textIn, out string textOut)
{
    //todo: change real to $returnType
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "forAny_",
/+initValue=+/ "q{false}",
        q{ if (!is($returnType==bool)) assert(0,q{forAny body must be boolean, not $returnType});
            if ($elem) return true; }
    ) ;
}

//Plugin forNone
int plugin_forNone (string filename, int lineNo, string textIn, out string textOut)
{
    //todo: change real to $returnType
    return plugin_template_sum_prod (filename, lineNo, textIn, textOut, "forNone_",
/+initValue=+/ "q{true}",
        q{ if (!is($returnType==bool)) assert(0,q{forNone body must be boolean, not $returnType});
            if ($elem) return false; }
    ) ;
}

//Plugin f
int plugin_f (string filename, int lineNo, string textIn, out string textOut)
{
/+    sizediff_t idx = indexOf (textIn, ';') ;
    if (idx == -1)
    {
        stderr.writeln ("Error:"~filename~":"~to!string(lineNo)~": anonymous function should have declaration part") ;
        return 1  ;
    }
    string params = textIn [0..idx] ;
    textOut = "("~params~")"~"{" ;
    string body_ = textIn [idx+1..$] ;
    for(;;)
    {
        idx = indexOf (body_, ';') ;
        if (idx == -1)
        {
            textOut ~= "return "~body_~";}" ;
            break ;
        }
        textOut ~= body_[0..idx+1] ;
        body_ = body_ [idx+1..$] ;
    }
+/
    dchar skipSpaceBefore (string str, sizediff_t idx)
    {
        for (;;)
        {
            if (idx <= 0) return 0 ;
            -- idx ;
            dchar c = str [idx] ;
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r' && c != '\v')
                return c ;
        }
    }

    dchar skipSpaceAfter (string str, sizediff_t idx)
    {
        for (;;)
        {
            ++ idx ;
            if (idx >= str.length) return 0 ;
            dchar c = str [idx] ;
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r' && c != '\v')
                return c ;
        }
    }

    string symbols_before = "~!%^&*()+-=[];,/{}|<>?" ;
    string symbols_after  = "~!%^&*()+-=[];,/{}|<>?." ;
    string parseStr = textIn ;
    bool foundA = false ;
    bool foundB = false ;

    for (;;)
    {
        sizediff_t idx = indexOf (parseStr, 'a') ;
        if (idx == -1)
            break ;
        if ((idx == 0 || indexOf (symbols_before, skipSpaceBefore (parseStr, idx)) != -1)
            && (idx == parseStr.length - 1
                      || indexOf (symbols_after,  skipSpaceAfter  (parseStr, idx)) != -1))
            foundA = true ;
        parseStr = parseStr [idx+1..$] ;
    }
    parseStr = textIn ;
    for (;;)
    {
        sizediff_t idx = indexOf (parseStr, 'b') ;
        if (idx == -1)
            break ;
        if ((idx == 0 || indexOf (symbols_before, skipSpaceBefore (parseStr, idx)) != -1)
            && (idx == parseStr.length - 1
                      || indexOf (symbols_after,  skipSpaceAfter  (parseStr, idx)) != -1))
            foundB = true ;
        parseStr = parseStr [idx+1..$] ;
    }
    if (foundB)
    {
        textOut = "binaryFun!q{"~ textIn~"}" ;
    }
    else
    if (foundA)
    {
        textOut = "unaryFun!q{"~ textIn~"}" ;
    }
    else
    {
        stderr.writeln ("Error:"~filename~":"~to!string(lineNo)~": f!{"~textIn~"} is neither unary function nor binary") ;
        return 1 ;
    }
    return 0 ;
}
