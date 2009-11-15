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
    class TravelToStationState : State
    {
        State substate = null;
        int station_id;
        int solarsystem_id;

        public TravelToStationState(string command)
        {
            string[] strs = command.Split(' ');
            this.station_id = Int32.Parse(strs[1]);
            this.solarsystem_id = Int32.Parse(strs[2]);
        }

        public TravelToStationState(int station_id, int solarsystem_id)
        {
            this.station_id = station_id;
            this.solarsystem_id = solarsystem_id;
        }

        public override bool OnFrame()
        {
            base.OnFrame();
            if (substate != null)
            {
                if (substate.OnFrame())
                    return true;
            }

            // check if we're done
            if (g.me.InStation && g.me.StationID == station_id)
            {
                Result = "Reached destination";
                done = true;
                return false;
            }
            // check if we're in the right solar system and just need to dock
            else if (g.me.InSpace && g.me.SolarSystemID == solarsystem_id)
            {
                substate = new DockState(station_id);
                substate.OnFrame();
                return true;
            }
            // if we're in station, undock
            else if (g.me.InStation)
            {
                substate = new UndockState();
                substate.OnFrame();
                return true;
            }
            // if we're out in space, move to the next solarsystem
            else if (g.me.InSpace)
            {
                // set our destination if its not already correct
                List<int> systems = g.eve.GetToDestinationPath();
                if (systems == null || systems.Count == 0 ||
                    systems[systems.Count - 1] != solarsystem_id)
                    Universe.ByID(solarsystem_id).SetDestination();
                
                systems = g.eve.GetToDestinationPath();
                Interstellar next_system = Universe.ByID(systems[0]);
                List<Entity> entities = g.eve.GetEntities("GroupID", "10");
                Entity next_gate = null;
                foreach (Entity stargate in entities)
                    if (stargate.Name.Contains(next_system.Name))
                        next_gate = stargate;

                if (next_gate != null)
                {
                    substate = new JumpState(next_gate.ID, systems[0]);
                    substate.OnFrame();
                    return true;
                }
            }

            // I guess we'll just wait hehe
            return true;
        }
    }

    public class JumpState : State
    {
        WarpState warp_state = null;
        int entity_id, solarsystem_id;
        bool approached = false;
        bool jumped = false;

        public JumpState(int entity_id, int solarsystem_id)
        {
            this.entity_id = entity_id;
            this.solarsystem_id = solarsystem_id;
        }

        public override bool OnFrame()
        {
            base.OnFrame();
            if (warp_state != null)
            {
                warp_state.OnFrame();
                if (warp_state.IsDone())
                    warp_state = null;
                else
                    return true;
            }

            List<Entity> entities = g.eve.GetEntities();
            if (entities == null || entities.Count <= 0)
            {
                // we're probably jumping right now - just chill
                return true;
            }

            if (g.me.InSpace && g.me.SolarSystemID == solarsystem_id)
            {
                Result = "Success";
                done = true;
                return false;
            }

            entities = g.eve.GetEntities("ID", entity_id.ToString());
            if (entities.Count == 0)
            {
                Result = "stargate not found";
                done = true;
                return false;
            }

            if (entities.Count > 1)
            {
                Result = "stargate id ambiguous";
                done = true;
                return false;
            }

            Entity stargate = entities[0];

            if (stargate.Distance > 150000.0)
            {
                warp_state = new WarpState(entity_id);
                warp_state.OnFrame();
                return true;
            }
            else if (stargate.Distance < 2500.0)
            {
                if (!jumped)
                {
                    stargate.Jump();
                    jumped = true;
                }
                return true;
            }
            else if (!approached)
            {
                stargate.Approach();
                approached = true;
            }

            return true;
        }
    }
}
