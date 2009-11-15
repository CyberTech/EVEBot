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
    public class MissionState : State
    {
        int agent_id = -1;
        State substate = null;

        public MissionState(string command)
        {
            // atm we only support "domission <agent_id>"
            try
            {
                agent_id = Int32.Parse(command.Substring(10));
            }
            catch
            {
            }
        }

        public MissionState(int agent_id)
        {
            this.agent_id = agent_id;
        }

        public override string ToString()
        {
            return "MissionState to agent id " + agent_id.ToString();
        }

        public override bool OnFrame()
        {
            base.OnFrame();
            // first defer to any substate we've assigned
            if (substate != null)
            {
                substate.OnFrame();
                if (substate.IsDone())
                {
                    // since we just hand off to another state, just return its result
                    Result = substate.Result;
                    done = true;
                    return false;
                }
                else
                    return true;
            }

            // now, we have to look at what's going on and figure out what
            // to do next.

            // First, make sure we actually have a mission from the agent
            // we've been assigned

            AgentMission mission = Util.FindMission(agent_id);

            if (mission == null)
            {
                Result = "don't have mission from this agent";
                done = true;
                return false;
            }

            if (mission.State != 2)
            {
                Result = "mission isn't accepted - we need an accept mission atm";
                done = true;
                return false;
            }

            // so, for now, we only know how to do courier missions
            if (mission.Type == "Courier")
            {
                substate = new CourierMission(agent_id);
                substate.OnFrame();
                if (substate.IsDone())
                {
                    Result = substate.Result;
                    done = true;
                    return false;
                }
                else
                    return true;
            }
            else
            {
                Result = "We only support CourierMissions atm";
                done = true;
                return false;
            }
        }
    }

    public class CourierMission : State
    {
        State substate = null;
        MissionPageState page_state = null;
        int agent_id;
        string name;
        MissionPage page = null;
        bool items_delivered = false;

        public CourierMission(int agent_id)
        {
            this.agent_id = agent_id;
            AgentMission mission = Util.FindMission(agent_id);
            name = mission.Name;
        }

        public override string ToString()
        {
            return "CourierMission with mission " + name;
        }

        public override bool OnFrame()
        {
            base.OnFrame();
            if (substate != null)
            {
                if (substate.OnFrame())
                    return true;
            }
            // first, make sure we have the mission page
            if (page == null)
            {
                if (page_state == null)
                {
                    page_state = new MissionPageState(agent_id);
                    page_state.OnFrame();

                    if (page_state.IsDone())
                        page = page_state.Page;
                    else
                    {
                        substate = page_state;
                        return true;
                    }
                }
                else if (page_state.Page != null)
                {
                    page = page_state.Page;
                    substate = null;
                }
                else
                {
                    Result = "We failed to get the mission page - aborting";
                    done = true;
                    return false;
                }
            }

            bool items_in_cargo = ItemsInCargoBay();

            if (items_delivered)
            {
                // check if we're done
                Agent agent = new Agent("ByID", agent_id);
                if (g.me.InStation && g.me.StationID == agent.StationID)
                {
                    Result = "Finished Courier mission - please turn in";
                    done = true;
                    return false;
                }
                else
                {
                    substate = new TravelToStationState(agent.StationID, agent.Solarsystem.ID);
                    substate.OnFrame();
                    return true;
                }
            }
            else if (items_in_cargo)
            {
                BookMark dropoff = Util.FindDropoff(agent_id);

                // the dropoff bookmark ID is the same as the station ID (if its a station, all we support atm)
                if (g.me.InStation && g.me.StationID == dropoff.ID)
                {
                    List<Item> items = g.me.Ship.GetCargo();
                    foreach (Item item in items)
                        if (item.TypeID == page.CargoID)
                            item.MoveToHangar();
                    items_delivered = true;

                    // return to the agent
                    Agent agent = new Agent("ByID", agent_id);

                    substate = new TravelToStationState(agent.StationID, agent.Solarsystem.ID);
                    substate.OnFrame();
                    return true;
                }
                else
                {
                    substate = new TravelToStationState(dropoff.ID, dropoff.SolarSystemID);
                    substate.OnFrame();
                    return true;
                }
            }
            else
            {
                BookMark pickup = Util.FindPickup(agent_id);

                // the dropoff bookmark ID is the same as the station ID (if its a station, all we support atm)
                if (g.me.InStation && g.me.StationID == pickup.ID)
                {
                    List<Item> hanger_items = g.me.GetHangarItems();
                    foreach (Item hanger in hanger_items)
                        if (hanger.TypeID == page.CargoID)
                            hanger.MoveToMyShip();
                    return true;
                }
                else
                {
                    substate = new TravelToStationState(pickup.ID, pickup.SolarSystemID);
                    substate.OnFrame();
                    return true;
                }
            }
        }

        public bool ItemsInCargoBay()
        {
            List<Item> items = g.me.Ship.GetCargo();
            double volume_found = 0;

            foreach (Item item in items)
                if (item.TypeID == page.CargoID)
                    volume_found += item.Volume * item.Quantity;

            if (volume_found >= page.CargoVolume)
                return true;

            return false;
        }
    }
}