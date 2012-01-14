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

namespace evecmd {
    abstract public class State {
        protected bool on_frame_run = false;

        // OnFrame
        // this of OnFrame like an event handler - if its handled the frame event, it returns true
        // returning false indicates that anyone else waiting to handle the frame should also be given a chance

        // states that want to introduce a state-level mechanism should override this (use SimpleState for normal states)
        public abstract bool OnFrame();

        // subcalsses that do something specific need to override this
        public abstract bool OnFrameImpl();

        bool done = false;

        public void SetDone(string result) {
            Result = result;
            done = true;
            if (on_frame_run)
                g.Print("Finished State:{0}:{1}", this, Result);
        }

        public bool IsDone {
            get {
                return done;
            }
        }

        // describes what happened so you can show it
        // TODO: maybe change this to some result enum or something
        public string Result { get; private set; }
    }

    abstract public class SimpleState : State {
        public override bool OnFrame() {
            // finished states can't run
            if (IsDone)
                return false;

            // if this is our first time, we're 'entering' the state
            if (!on_frame_run && !IsDone) {
                on_frame_run = true;
                g.Print("Entering State:{0}", this);
            }

            return OnFrameImpl();
        }
    }

    // will dock at and optionally warp to a station in the current system
    public class DockState : SimpleState {
        bool started = false;
        bool waiting = false;
        DateTime wait_start;
        long entity_id = -1;
        WarpState warp = null;

        public DockState(string command) {
            List<string> args = new List<string>(command.Split(' '));
            // "dock bm <Bookmark name>"
            if (args.Count == 3 && args[1] == "bm") {
                BookMark bm = g.eve.Bookmark(args[2]);

                if (bm != null && bm.ToEntity != null && bm.ToEntity.ID > 0)
                    entity_id = bm.ToEntity.ID;
                else
                    SetDone("Bookmark not found");
            }
            else if (args.Count == 2) {
                // support for "dock <entityID>"
                try {
                    entity_id = Int32.Parse(command.Substring(5));
                }
                catch {
                    SetDone("Failed to parse command");
                }
            }
            else {
                // try to dock at the closest station
                var stations = g.eve.QueryEntities("GroupID = 15");
                stations.Sort((a, b) => a.Distance.CompareTo(b.Distance));

                var closest = stations.FirstOrDefault();
                if (closest == null)
                    SetDone("No stations nearby");
                else
                    entity_id = closest.ID;
            }
        }

        public DockState(long entity_id) {
            this.entity_id = entity_id;
        }

        public override string ToString() {
            return "DockState to entity id " + entity_id.ToString();
        }

        public override bool OnFrameImpl() {
            if (IsDone)
                return false;

            if (warp != null) {
                warp.OnFrame();
                if (warp.IsDone)
                    warp = null;
                else
                    return true;
            }

            if (!started) {
                // check if we're already in warp
                if (g.me.ToEntity.Mode == 3) {
                    SetDone("can't dock in warp");
                    return false;
                }

                List<Entity> entities = g.eve.QueryEntities("ID = {0}".Format(entity_id));
                if (entities.Count == 0) {
                    SetDone("entity not found");
                    return false;
                }

                if (entities.Count > 1) {
                    SetDone("entity ambiguous");
                    return false;
                }

                Entity entity = entities[0];

                if (entity.Distance > 150000.0) {
                    warp = new WarpState(entity_id);
                    warp.OnFrame();
                    if (warp.IsDone)
                        SetDone(warp.Result);
                }
                else {
                    entity.Dock();
                    started = true;
                }
                return true;
            }
            else if (waiting) {
                if (DateTime.Now - wait_start > TimeSpan.FromSeconds(5.0)) {
                    SetDone("Success");
                    return false;
                }
            }
            else {

                if (!g.me.InSpace &&
                g.me.InStation &&
                g.me.StationID > 0 &&
                g.me.Ship.GetCargo() != null) {
                    waiting = true;
                    wait_start = DateTime.Now;
                    return true;
                }
            }

            return true;
        }
    }

    public class UndockState : SimpleState {
        bool started = false;
        // TODO: remove this excpetion crap if and when it stops happening
        bool exception_seen = false;

        DateTime doneSince = DateTime.Now;

        public override string ToString() {
            return "UndockState";
        }

        public override bool OnFrameImpl() {
            bool in_space = false;
            bool in_station = false;
            int station_id = g.me.StationID;
            bool exception = false;
            try {
                in_space = g.me.InSpace;
                in_station = g.me.InStation;
                //station_id = g.me.StationID;
            }
            catch {
                if (!exception_seen) {
                    g.Print("NOTE: Me.InSpace and Me.InStation still throwing exceptions while undocking");
                    exception_seen = true;
                }
                exception = true;
            }

            if (!exception && !started) {
                if (!in_station) {
                    SetDone("not docked");
                    return false;
                }

                g.eve.Execute(ExecuteCommand.CmdExitStation);
                started = true;
                return true;
            }
            else if (!exception && in_space && !in_station && station_id <= 0) {
                if (DateTime.Now.Subtract(doneSince) > TimeSpan.FromSeconds(1.0)) {
                    SetDone("Success");
                    return false;
                }
                return true;
            }

            doneSince = DateTime.Now;

            // keep waiting
            return true;
        }
    }
}