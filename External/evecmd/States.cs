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
        private bool on_frame_run = false;
        public virtual bool OnFrame()
        {
            if (!on_frame_run && !done)
            {
                on_frame_run = true;
                g.Print("Entering State:{0}", this);
            }
            return false;
        }

        private bool done_ = false;
        protected bool done
        {
            get { return done_; }
            set
            {
                // if the constructor set done = true we don't want to 
                // spew
                if (value && !done_ && on_frame_run)
                    g.Print("Finished State:{0}:{1}", this, Result);
                done_ = value;
            }
        }
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
        bool waiting = false;
        DateTime wait_start;
        int entity_id = -1;
        WarpState warp = null;

        public DockState(string command)
        {
            List<string> args = new List<string>(command.Split(' '));
            // "dock bm <Bookmark name>"
            if (args.Count == 3 && args[1] == "bm")
            {
                BookMark bm = g.eve.Bookmark(args[2]);

                if (bm != null && bm.ToEntity != null && bm.ToEntity.ID > 0)
                    entity_id = bm.ToEntity.ID;
                else
                {
                    Result = "Bookmark not found";
                    done = true;
                }
            }
            else
            {
                // support for "dock <entityID>"
                try
                {
                    entity_id = Int32.Parse(command.Substring(5));
                }
                catch
                {
                    Result = "Failed to parse command";
                    done = true;
                }
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
            base.OnFrame();

            if (done)
                return false;

            if (warp != null)
            {
                warp.OnFrame();
                if (warp.IsDone())
                    warp = null;
                else
                    return true;
            }

            if (!started)
            {
                // check if we're already in warp
                if (g.me.ToEntity.Mode == 3)
                {
                    Result = "can't dock in warp";
                    done = true;
                    return false;
                }

                List<Entity> entities = g.eve.GetEntities("ID", entity_id.ToString());
                if (entities.Count == 0)
                {
                    Result = "entity not found";
                    done = true;
                    return false;
                }

                if (entities.Count > 1)
                {
                    Result = "entity ambiguous";
                    done = true;
                    return false;
                }

                Entity entity = entities[0];

                if (entity.Distance > 150000.0)
                {
                    warp = new WarpState(entity_id);
                    warp.OnFrame();
                    if (warp.IsDone())
                    {
                        Result = warp.Result;
                        done = true;
                    }
                }
                else
                {
                    entity.Dock();
                    started = true;
                }
                return true;
            }
            else if (waiting)
            {
                if (DateTime.Now - wait_start > TimeSpan.FromSeconds(5.0))
                {
                    Result = "Success";
                    done = true;
                    return false;
                }
            }
            else
            {

                if (!g.me.InSpace &&
                g.me.InStation &&
                g.me.StationID > 0 &&
                g.me.Ship.GetCargo() != null)
                {
                    waiting = true;
                    wait_start = DateTime.Now;
                    return true;
                }
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
            base.OnFrame();
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
                    Result = "not docked";
                    done = true;
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
}