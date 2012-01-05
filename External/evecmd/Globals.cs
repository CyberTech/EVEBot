// Copyright 2009 Francis Crick fcrick@gmail.com
// License: http://creativecommons.org/licenses/by-nc-sa/3.0/us/

using System;
using System.Text;
using EVE.ISXEVE;
using InnerSpaceAPI;

namespace evecmd
{
    public class g
    {
        // these are already singletons, so we're just exposing them easier
        public static EVE.ISXEVE.EVE eve = null;
        public static EVE.ISXEVE.Me me = null;
        public static EVE.ISXEVE.ISXEVE isxeve = null;
        public static void Print(string format, params object[] args)
        {
            InnerSpace.Echo(String.Format(format, args));
        }
    }
}