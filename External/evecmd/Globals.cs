using System;
using System.Text;
using EVE.ISXEVE;

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
            Console.WriteLine(String.Format(format, args));
        }
    }
}