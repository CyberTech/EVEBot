// Copyright 2009 Francis Crick fcrick@gmail.com
// License: http://creativecommons.org/licenses/by-nc-sa/3.0/us/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using LavishScriptAPI;
using LavishVMAPI;
using InnerSpaceAPI;
using EVE.ISXEVE;

namespace evecmd
{
    class MissionPage
    {
        string doc;

        // give this the HTML from a mission window, and it will allow
        // you to access various things from it
        public MissionPage(string html)
        {
            doc = html;
        }

        public string Title
        {
            get
            {
                int start = doc.IndexOf("<Title>") + "<Title>".Length;
                int end = doc.IndexOf("</Title>");

                return doc.Substring(start, end - start);
            }
        }

        public int CargoID
        {
            get
            {
                int start = doc.IndexOf("<img src=\"typeicon:") + "<img src=\"typeicon:".Length;
                int end = doc.IndexOf("\"", start);

                return Int32.Parse(doc.Substring(start, end - start));
            }
        }

        // returns cubic meters times ten
        public double CargoVolume
        {
            get
            {
                int end = doc.IndexOf("m³") - 1;
                int start = doc.LastIndexOf("(", end) + 1;

                return double.Parse(doc.Substring(start, end - start));
            }
        }
    }

    // this state tries to get the mission page of the given mission
    class MissionPageState : SimpleState
    {
        int agent_id;
        string name;
        bool tried_opening = false;
        public MissionPage Page { get; protected set; }

        public MissionPageState(int agent_id)
        {
            this.agent_id = agent_id;
            AgentMission mission = Util.FindMission(agent_id);
            name = mission.Name;
            Page = null;
        }

        public override bool OnFrameImpl()
        {
            // check if we can see the window
            EVEWindow window = EVEWindow.GetWindowByCaption(name);
            if (window != null && window.IsValid && window.HTML.Length > 0)
            {
                Page = new MissionPage(window.HTML);
                SetDone("Success");
                return false;
            }

            // try opening the page if we haven't tried already
            if (!tried_opening)
            {
                // TODO: maybe check if the return value of this matters
                Util.FindMission(agent_id).GetDetails();
                tried_opening = true;
            }
            return true;
        }
    }
}
