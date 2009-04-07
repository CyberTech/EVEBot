using System;
using System.Collections.Generic;
using System.Text;
using LavishScriptAPI;

namespace EveBots
{
    public class EVEWatcher : LavishScriptObject
    {
        public EVEWatcher(LavishScriptObject obj)
            : base(obj)
        {
        }
        public void ResetCalledBack()
        {
            ExecuteMethod("ResetCalledBack");
        }
        public void CloseSessions()
        {
            ExecuteMethod("CloseSessions");
        }
        public void DumpSession()
        {
            ExecuteMethod("DumpSession");
        }
        public void DumpCalledBack()
        {
            ExecuteMethod("DumpCalledBack");
        }
        public void DumpLastUpdate()
        {
            ExecuteMethod("DumpLastUpdate");
        }
        public string Test()
        {
            return GetMember<string>("Testu");
        }

    }
}
