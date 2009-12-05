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
    class GotoState : SimpleState
    {
        State substate = null;
        string bm_label;

        public GotoState(string command)
        {
            List<string> args = new List<string>(command.Split(' '));

            // "goto bm <Bookmark name>"
            if (args.Count == 3 && args[1] == "bm")
            {
                BookMark bm = g.eve.Bookmark(args[2]);

                if (bm != null && bm.IsValid)
                    bm_label = bm.Label;
                else
                    SetDone("Bookmark not found");
            }
            else
                SetDone("Invalid arguments");
        }

        public override bool OnFrameImpl()
        {
            if (substate != null)
            {
                if (substate.OnFrame())
                    return true;
            }

            BookMark bm = g.eve.Bookmark(bm_label);

            if (bm == null || !bm.IsValid)
                SetDone("Bookmark no longer available");

            // check if we're in a station
            if (g.me.InStation)
            {
                // maybe we're at our destination already
                if (bm.ToEntity != null && g.me.StationID == bm.ToEntity.ID)
                {
                    SetDone("We're already docked at the place we're trying to go");
                    return false;
                }
                else
                {
                    substate = new UndockState();
                    substate.OnFrame();
                    return true;
                }
            }
            else
            {
                // if we're in the right solar system, then warp to or approach the bookmark
                if (g.me.SolarSystemID == bm.SolarSystemID)
                {
                    double distance;
                    if (bm.ToEntity != null && bm.ToEntity.IsValid)
                        distance = bm.ToEntity.Distance;
                    else
                        distance = Util.Distance(bm.X, bm.Y, bm.Z, g.me.ToEntity.X, g.me.ToEntity.Y, g.me.ToEntity.Z);

                    // if we're too far away, warp
                    if (distance > 150000.0)
                    {
                        substate = new WarpState(bm);
                        substate.OnFrame();
                        return true;
                    }
                    else if (distance > 10000.0)
                    {
                        substate = new ApproachState(bm);
                        substate.OnFrame();
                        return true;
                    }
                    else
                    {
                        // we've made it!
                        SetDone("Success");
                        return false;
                    }
                }
            }

            return true;
        }

    }

    // TODO: make this use the GotoState
    class TravelToStationState : SimpleState
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

        public override bool OnFrameImpl()
        {
            if (substate != null)
            {
                if (substate.OnFrame())
                    return true;
            }

            // check if we're done
            if (g.me.InStation && g.me.StationID == station_id)
            {
                SetDone("Reached destination");
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

    public class JumpState : SimpleState
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

        public override bool OnFrameImpl()
        {
            if (warp_state != null)
            {
                warp_state.OnFrame();
                if (warp_state.IsDone)
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
                SetDone("Success");
                return false;
            }

            entities = g.eve.GetEntities("ID", entity_id.ToString());
            if (entities.Count == 0)
            {
                SetDone("stargate not found");
                return false;
            }

            if (entities.Count > 1)
            {
                SetDone("stargate id ambiguous");
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

    public class ApproachState : SimpleState
    {
        bool started = false;
        int entity_id = -1;
        bool use_bookmark = false;
        string bm_label;

        public ApproachState(int entity_id)
        {
            this.entity_id = entity_id;
        }

        public ApproachState(BookMark bm)
        {
            use_bookmark = true;
            bm_label = bm.Label;
        }

        public override bool OnFrameImpl()
        {
            if (!started)
            {
                if (use_bookmark)
                {
                    BookMark bm = g.eve.Bookmark(bm_label);
                    if (bm == null || !bm.IsValid)
                    {
                        SetDone("Bookmark not found");
                        return false;
                    }

                    // TODO: FIXME
                    SetDone("We don't know how to approach a bookmark!");
                    return false;
                }
                else
                {
                    List<Entity> entities = g.eve.GetEntities("ID", entity_id.ToString());
                    if (entities.Count == 0)
                    {
                        SetDone("entity not found");
                        return false;
                    }

                    if (entities.Count > 1)
                    {
                        SetDone("entity ambiguous");
                        return false;
                    }

                    Entity entity = entities[0];

                    entity.Approach();
                }
                started = true;
                return true;
            }
            else
            {
                // we did enter warp - if we drop out of warp, then we're done
                if (g.me.ToEntity.Mode != 3)
                {
                    SetDone("Success");
                    return false;
                }
                return true;
            }
        }
    }

    public class WarpState : SimpleState
    {
        int entity_id = -1;
        bool started = false;
        bool warp_start_detected = false;
        bool use_bookmark = false;
        string bm_label;

        // state started from a command from the user
        public WarpState(string command)
        {
            // atm we only support "warp <entityID>"
            try
            {
                entity_id = Int32.Parse(command.Substring(5));
            }
            catch
            {
            }
        }

        public WarpState(int entity_id)
        {
            this.entity_id = entity_id;
        }

        public WarpState(BookMark bookmark)
        {
            use_bookmark = true;
            bm_label = bookmark.Label;
        }

        public override string ToString()
        {
            if (use_bookmark)
                return "WarpState to bookmark " + bm_label;
            return "WarpState to entity id " + entity_id.ToString();
        }

        public override bool OnFrameImpl()
        {
            if (!started)
            {
                // check if we're already in warp
                if (g.me.ToEntity.Mode == 3)
                {
                    SetDone("already in warp");
                    return false;
                }

                if (use_bookmark)
                {
                    BookMark bm = g.eve.Bookmark(bm_label);
                    if (bm == null || !bm.IsValid)
                    {
                        SetDone("Bookmark not found");
                        return false;
                    }

                    double distance = Util.Distance(bm.X, bm.Y, bm.Z, g.me.ToEntity.X, g.me.ToEntity.Y, g.me.ToEntity.Z);

                    if (distance < 150000.0)
                    {
                        SetDone("entity too close");
                        return false;
                    }

                    bm.WarpTo();
                }
                else
                {
                    List<Entity> entities = g.eve.GetEntities("ID", entity_id.ToString());
                    if (entities.Count == 0)
                    {
                        SetDone("entity not found");
                        return false;
                    }

                    if (entities.Count > 1)
                    {
                        SetDone("entity ambiguous");
                        return false;
                    }

                    Entity entity = entities[0];

                    if (entity.Distance < 150000.0)
                    {
                        SetDone("entity too close");
                        return false;
                    }

                    entity.WarpTo();
                }
                started = true;
                return true;
            }
            else if (!warp_start_detected)
            {
                // check if we've entered warp
                if (g.me.ToEntity.Mode == 3)
                {
                    warp_start_detected = true;
                }

                // TODO: have some way to bail if we don't start warp in enough time
                return true;
            }
            else
            {
                // we did enter warp - if we drop out of warp, then we're done
                if (g.me.ToEntity.Mode != 3)
                {
                    SetDone("Success");
                    return false;
                }
                return true;
            }
        }
    }
}
