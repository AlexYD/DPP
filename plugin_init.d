//          Copyright Alex Dovhal 2010.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module plugin_init ;

struct PluginInfo
{
    string dllName ;
    bool loaded ;
    //NOTE : it's not used now, because no use of DLL.
    //HMODULE handle ;
    string function () shortInfo ;
    string[] function () fullInfo ;
    int function (string, string, int, string, out string) command ;
    string[] function () getAllNames ;

    void init (
        string dllName,
        string function () shortInfo,
        string[] function () fullInfo,
        int function (string, string, int, string, out string) command,
        string[] function () getAllNames )
    {
        this.dllName = dllName ;
        this.shortInfo = shortInfo ;
        this.fullInfo = fullInfo ;
        this.command = command ;
        this.getAllNames = getAllNames ;
        this.loaded = true ;
    }
}

PluginInfo* [string] g_plugin ;
string [string] g_names ;

