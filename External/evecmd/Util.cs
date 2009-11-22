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

        public static double Distance(double fromX, double fromY, double fromZ, double toX, double toY, double toZ)
        {
            return Math.Sqrt(Math.Pow(fromX - toX, 2.0) + Math.Pow(fromY - toY, 2.0) + Math.Pow(fromZ - toZ, 2.0));
        }

        public static bool DoWeHaveOre()
        {
            List<Item> items = g.me.Ship.GetCargo();
            foreach (Item item in items)
                if (item.CategoryType == CategoryType.Asteroid)
                    return true;

            return false;
        }
    }
}
