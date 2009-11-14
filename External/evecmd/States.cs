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
    abstract public class State
    {
        // true means the frame has been 'handled', and we 
        // shouldn't continue down the state list.
        public abstract bool OnFrame();

        protected bool done = false;
        // call this after OnFrame - if its true, abandon the state
        public virtual bool IsDone()
        {
            return done;
        }

        // describes what happened so you can show it
        // TODO: maybe change this to some result enum or something
        public string Result { get; protected set; }
    }

    // will dock at and optionally warp to a station in the current system
    public class DockState : State
    {
        bool started = false;
        int entity_id = -1;
        WarpState warp = null;

        public DockState(string command)
        {
            // atm we only support "dock <entityID>"
            try
            {
                entity_id = Int32.Parse(command.Substring(5));
            }
            catch
            {
            }
        }

        public DockState(int entity_id)
        {
            this.entity_id = entity_id;
        }

        public override string ToString()
        {
            return "DockState to entity id " + entity_id.ToString();
        }

        public override bool OnFrame()
        {
            if (warp != null)
            {
                warp.OnFrame();
                if (warp.IsDone())
                    warp = null;
            }
            else if (!started)
            {
                // check if we're already in warp
                if (g.me.ToEntity.Mode == 3)
                {
                    done = true;
                    Result = "can't dock in warp";
                    return false;
                }

                List<Entity> entities = g.eve.GetEntities("ID", entity_id.ToString());
                if (entities.Count == 0)
                {
                    done = true;
                    Result = "entity not found";
                    return false;
                }

                if (entities.Count > 1)
                {
                    done = true;
                    Result = "entity ambiguous";
                    return false;
                }

                Entity entity = entities[0];

                if (entity.Distance > 150000.0)
                {
                    warp = new WarpState(entity_id);
                    warp.OnFrame();
                    if (warp.IsDone())
                    {
                        done = true;
                        Result = warp.Result;
                    }
                }
                else
                {
                    entity.Dock();
                    started = true;
                }
                return true;
            }
            else if (g.me.InStation && g.me.StationID > 0)
            {
                Result = "Success";
                done = true;
                return false;
            }
         
            return true;
        }
    }

    public class UndockState : State
    {
        bool started = false;
        // TODO: remove this excpetion crap if and when it stops happening
        bool exception_seen = false;

        public override string ToString()
        {
            return "UndockState";
        }

        public override bool OnFrame()
        {
            bool in_space = false;
            bool in_station = false;
            int station_id = g.me.StationID;
            bool exception = false;
            try
            {
                in_space = g.me.InSpace;
                in_station = g.me.InStation;
                //station_id = g.me.StationID;
            }
            catch
            {
                if (!exception_seen)
                {
                    g.Print("NOTE: Me.InSpace and Me.InStation still throwing exceptions while undocking");
                    exception_seen = true;
                }
                exception = true;
            }

            if (!exception && !started)
            {
                if (!in_station)
                {
                    done = true;
                    Result = "not docked";
                    return false;
                }

                g.eve.Execute(ExecuteCommand.CmdExitStation);
                started = true;
                return true;
            }
            else if (!exception && in_space && !in_station && station_id <= 0)
            {
                Result = "Success";
                done = true;
                return false;
            }
         
            // keep waiting
            return true;
        }
    }

    public class WarpState : State
    {
        int entity_id = -1;
        bool started = false;
        bool warp_start_detected = false;

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

        public override string ToString()
        {
            return "WarpState to entity id " + entity_id.ToString();
        }

        public override bool OnFrame()
        {
            if (!started)
            {
                // check if we're already in warp
                if (g.me.ToEntity.Mode == 3)
                {
                    done = true;
                    Result = "already in warp";
                    return false;
                }

                List<Entity> entities = g.eve.GetEntities("ID", entity_id.ToString());
                if (entities.Count == 0)
                {
                    done = true;
                    Result = "entity not found";
                    return false;
                }

                if (entities.Count > 1)
                {
                    done = true;
                    Result = "entity ambiguous";
                    return false;
                }

                Entity entity = entities[0];

                if (entity.Distance < 150000.0)
                {
                    Result = "entity too close";
                    done = true;
                    return false;
                }

                entity.WarpTo();
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
                    Result = "Success";
                    done = true;
                    return false;
                }
                return true;
            }
        }
    }
}