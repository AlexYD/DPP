/* Yet TODO
 * [a*a for a in range(10)]
 * map!"a*a"(iota(10))
 * makeRange!{i=0:10;i*i}
 * makeRange!{i:iota(10);i*i}
 *
 * [x*x for x in range(100) if x!=16]
 * array(filter!"a!=16"(map!"a*a"(iota(100))))
 * makeArray!{x<100, x!=16; x*x}
 *
 */

//          Copyright Alex Dovhal 2010.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module plugin_list_comprehension ;

private import std.conv, std.string, std.range ;
private import plugin_init ;
private import ast_parser ;

/*private*/ string g_pluginDLL = (.stringof) ~ ".dll" ;
/*private*/ string g_pluginName = (.stringof) ;

public immutable string[] pluginNames = ["makeArray", "makeList"] ;

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

//NOTE: obsolete, as it was designed for Shared library, not for build-in plugins
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


//Plugin makeArray:
int plugin_makeArray (string filename, int lineNo, string textIn, out string textOut)
{
    assert (0, "makeArray is not yes designed") ;
}

//Plugin makeList:
int plugin_makeList (string filename, int lineNo, string textIn, out string textOut)
{
    assert (0, "makeList is not yet designed") ;
}

//TODO: add forAll, forAny

