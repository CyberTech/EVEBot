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
    public class MineLoopState : SimpleState
    {
        State substate = null;
        string base_label, mining_label;
        int max_count;
        int count = 0;
        bool started = false;
        bool mine_next = true;

        public MineLoopState(string command)
        {
            List<string> args = new List<string>(command.Split(' '));

            // "mineloop <Base bm> <Mining bm> <maxcount>"
            if (args.Count == 4)
            {
                BookMark base_bm = g.eve.Bookmark(args[1]);
                BookMark mining_bm = g.eve.Bookmark(args[2]);

                if (base_bm != null && base_bm.IsValid &&
                    mining_bm != null && mining_bm.IsValid)
                {
                    base_label = base_bm.Label;
                    mining_label = mining_bm.Label;

                    max_count = Int32.Parse(args[3]);
                }
                else
                    SetDone("Bookmark not found");
            }
            else
            {
                SetDone("Invalid arguments");
            }
        }

        public override bool OnFrameImpl()
        {
            // TODO: consider including this in the parent
            if (substate != null)
            {
                bool result = substate.OnFrame();

                if (substate.IsDone)
                {
                    if (substate is RunMiningLasersState &&
                        substate.Result != "Success")
                    {
                        SetDone(substate.Result);
                        return false;
                    }
                    substate = null;
                }

                if (result)
                    return true;
            }

            if (count >= max_count)
            {
                SetDone("Success");
                return false;
            }

            if (!started)
            {
                BookMark bm = g.eve.Bookmark(mining_label);
                if (!g.me.InStation &&
                    bm == null ||
                    !bm.IsValid)
                {
                    SetDone(string.Format("mining bookmark {0} not found", mining_label));
                    return false;
                }

                if (g.me.InStation ||
                    bm.SolarSystemID != g.me.SolarSystemID ||
                    Util.Distance(bm.X, bm.Y, bm.Z, g.me.ToEntity.X, g.me.ToEntity.Y, g.me.ToEntity.Z) > 10000.0)
                {
                    substate = new GotoState("goto bm " + mining_label);
                    substate.OnFrame();

                    if (substate.IsDone)
                    {
                        SetDone(substate.Result);
                        return false;
                    }

                    return true;
                }

                started = true;
            }

            if (mine_next)
            {
                mine_next = false;

                count += 1;
                substate = new RunMiningLasersState();
                substate.OnFrame();
                return true;
            }
            else
            {
                mine_next = true;

                substate = new DoDropoffState("dodropoff " + base_label + " " + mining_label);
                substate.OnFrame();
                return true;
            }
        }
    }

    public class RunMiningLasersState : SimpleState
    {
        int max_targets = -1;
        int laser_count = -1;
        double max_range = -1;
        DateTime do_nothing_until, dont_cycle_until;
        Dictionary<int, DateTime> start_times = new Dictionary<int, DateTime>();
        public override bool OnFrameImpl()
        {
            if (DateTime.Now < do_nothing_until)
                return true;

            if (max_targets == -1)
            {
                // TODO: check your skills, too - i think that can limit it
                max_targets = Convert.ToInt32(g.me.Ship.MaxLockedTargets);
            }

            if (max_range == -1)
            {
                max_range = Util.Ship.GetOptimalMiningRange();
                if (max_range == 0.0)
                {
                    SetDone("No mining lasers!");
                    return false;
                }
            }

            if (laser_count == -1)
            {
                laser_count = Util.Ship.GetMiningLaserCount();
            }

            // if out cargo is near full, shut off lasers and bail
            if (g.me.Ship.CargoCapacity - g.me.Ship.UsedCargoCapacity < 100.0)
            {
                for (int i = 0; i < 8; i++)
                {
                    Module laser = g.me.Ship.Module(SlotType.HiSlot, i);
                    if (laser != null &&
                        laser.IsValid &&
                        laser.MiningAmount > 0 &&
                        (laser.IsActive || laser.IsGoingOnline))
                        laser.Click();
                }

                SetDone("Success");
                return false;
            }

            List<Entity> roids = g.eve.GetEntities("CategoryID", "25", "Radius", max_range.ToString());
            List<Entity> locked = new List<Entity>();
            List<Entity> locking = new List<Entity>();
            List<Entity> not_locked = new List<Entity>();
            Entity active = null;

            if (roids == null || roids.Count == 0)
            {
                SetDone("No asteroids in range");
                return false;
            }

            foreach (Entity roid in roids)
            {
                if (roid.IsActiveTarget)
                    active = roid;
                if (roid.IsLockedTarget)
                    locked.Add(roid);
                else if (roid.BeingTargeted)
                    locking.Add(roid);
                else
                    not_locked.Add(roid);
            }

            // we're just gonna lock one per frame
            if (locked.Count + locking.Count < max_targets && not_locked.Count > 0)
            {
                not_locked[0].LockTarget();
                g.Print("Locking: [{0}] {1}", not_locked[0].ID, not_locked[0].Name);
                return true;
            }

            // available targets - we'll remove things when we find a laser using them
            List<Entity> available = new List<Entity>(locked);

            // lasers we've found that aren't being used
            List<Module> need_activating = new List<Module>();

            // now make sure each laser we have is firing
            for (int i = 0; i < 8; i++)
            {
                Module laser = g.me.Ship.Module(SlotType.HiSlot, i);
                if (laser == null || !laser.IsValid || !laser.MiningAmount.HasValue)
                    continue;

                if (laser.IsActive || laser.IsGoingOnline)
                {
                    // if its active, lets find its target
                    if (laser.LastTarget != null &&
                        laser.LastTarget.IsValid)
                        for (int j = 0; j < available.Count; j++)
                            if (available[j].ID == laser.LastTarget.ID)
                            {
                                available.RemoveAt(j);
                                break;
                            }
                }
                else if (!laser.IsDeactivating)
                    need_activating.Add(laser);
            }

            // if we fire something, then just wait until next frame
            if (available.Count > 0 && need_activating.Count > 0)
            {
                TryToActivateLaser(active, need_activating[0], available[0]);
                return true;
            }
            // if there are none available, but we still have lasers, feel free to double up
            else if (need_activating.Count > 0 && locked.Count > 0)
            {
                TryToActivateLaser(active, need_activating[0], locked[0]);
                return true;
            }

            // if our capacitor is at more than half, turn off the laser furthest along
            //Module furthest = null;
            if (g.me.Ship.CapacitorPct > 50.0 && DateTime.Now > dont_cycle_until)
            {
                Module furthest = null;

                for (int i = 0; i < 8; i++)
                {
                    Module laser = g.me.Ship.Module(SlotType.HiSlot, i);
                    if (laser != null &&
                        laser.IsValid &&
                        laser.MiningAmount > 0 &&
                        laser.IsActive)
                    {
                        if (!start_times.ContainsKey(laser.ToItem.ID))
                            start_times[laser.ToItem.ID] = DateTime.Now;

                        if (furthest == null ||
                            start_times[furthest.ToItem.ID] > start_times[laser.ToItem.ID])
                            furthest = laser;
                    }
                }

                if (furthest != null)
                {
                    furthest.Click();
                    dont_cycle_until = DateTime.Now + new TimeSpan(0, 0, 2);
                }
            }

            return true;
        }

        private void TryToActivateLaser(Entity active, Module laser, Entity roid)
        {
            if (active != null && active.IsValid &&
                active.ID == roid.ID)
            {
                laser.Click();
                start_times[laser.ToItem.ID] = DateTime.Now;
                g.Print("Mining: [{0}] {1}", roid.ID, roid.Name);
            }
            else
                roid.MakeActiveTarget();

            do_nothing_until = DateTime.Now + TimeSpan.FromSeconds(0.5);
        }
    }
    
    public class DoDropoffState : SimpleState
    {
        State substate = null;
        string base_label, mining_label;

        public DoDropoffState(string command)
        {
            List<string> args = new List<string>(command.Split(' '));

            // "dodropoff <Base bm> <Mining bm>"
            if (args.Count == 3)
            {
                BookMark base_bm = g.eve.Bookmark(args[1]);
                BookMark mining_bm = g.eve.Bookmark(args[2]);

                if (base_bm != null && base_bm.IsValid &&
                    mining_bm != null && mining_bm.IsValid)
                {
                    base_label = base_bm.Label;
                    mining_label = mining_bm.Label;
                }
                else
                    SetDone("Bookmark not found");
            }
            else
            {
                SetDone("Invalid arguments");
            }
        }

        public override bool OnFrameImpl()
        {
            // TODO: consider including this in the parent
            if (substate != null)
            {
                bool result = substate.OnFrame();

                if (substate.IsDone)
                    substate = null;

                if (result)
                    return true;
            }

            // collect information about our state
            bool have_ore = Util.DoWeHaveOre();
            bool at_home_station = AtHomeStation();

            // step 1 - go home
            if (have_ore && !at_home_station)
            {
                BookMark bm = g.eve.Bookmark(base_label);

                substate = new TravelToStationState(bm.ItemID, bm.SolarSystemID);
                
                substate.OnFrame();
                
                // if we're done with this state immediately, that's bad
                if (substate.IsDone)
                {
                    SetDone(substate.Result);
                    return false;
                }

                return true;
            }
            // step 2 - unload our cargo
            if (have_ore && at_home_station)
            {
                substate = new UnloadOreState();
                substate.OnFrame();

                // if we're done with this state immediately, that's bad
                if (substate.IsDone)
                {
                    SetDone(substate.Result);
                    return false;
                }

                return true;
            }
            // step 3 - travel back to the mining area
            if (!have_ore && at_home_station)
            {
                substate = new GotoState("goto bm " + mining_label);
                substate.OnFrame();

                // if we're done with this state immediately, that's bad
                if (substate.IsDone)
                {
                    SetDone(substate.Result);
                    return false;
                }

                return true;
            }

            // step 4 - if we got here, Success!
            SetDone("Success");
            return false;
        }

        private bool AtHomeStation()
        {
            BookMark bm = g.eve.Bookmark(base_label);

            if (g.me.InStation &&
                g.me.StationID == bm.ItemID)
                return true;
            return false;
        }
    }

    // NOTE: we might need some substate here to make sure cargo is accessable
    public class UnloadOreState : SimpleState
    {
        bool waiting = false;
        DateTime wait_start;

        public override bool OnFrameImpl()
        {
            if (!g.me.InStation)
            {
                SetDone("Can't unload in space!");
                return false;
            }

            if (waiting)
            {
                // give it 2 seconds
                if (DateTime.Now - wait_start > TimeSpan.FromSeconds(2.0))
                    waiting = false;
                else
                    return true;
            }

            bool found = false;

            // hopefully 'Asteroid' is just ore otherwise TODO :/
            List<Item> items = g.me.Ship.GetCargo();
            foreach (Item item in items)
                if (item.CategoryType == CategoryType.Asteroid)
                {
                    found = true;
                    item.MoveToHangar();
                }

            if (found)
            {
                waiting = true;
                wait_start = DateTime.Now;
                return true;
            }
            else
            {
                SetDone("Success");
                return false;
            }
        }
    }
}