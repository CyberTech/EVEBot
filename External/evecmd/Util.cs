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
    public class Util
    {
        public static AgentMission FindMission(int agent_id)
        {
            List<AgentMission> missions = g.eve.GetAgentMissions();
            foreach (AgentMission mission in missions)
                if (mission.AgentID == agent_id)
                    return mission;

            return null;
        }

        public static BookMark FindPickup(int agent_id)
        {
            AgentMission mission = FindMission(agent_id);
            foreach (BookMark bookmark in mission.GetBookmarks())
                if (bookmark.LocationType == "objective.source")
                    return bookmark;

            return null;
        }

        public static BookMark FindDropoff(int agent_id)
        {
            AgentMission mission = FindMission(agent_id);
            foreach (BookMark bookmark in mission.GetBookmarks())
                if (bookmark.LocationType == "objective.destination")
                    return bookmark;

            return null;
        }
    }
}
