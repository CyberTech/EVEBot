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