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
    // NOTE: we might need some substate here to make sure cargo is accessable
    public class UnloadOreState : State
    {
        bool waiting = false;
        DateTime wait_start;

        public override bool OnFrame()
        {
            if (base.OnFrame())
                return true;

            if (!g.me.InStation)
            {
                Result = "Can't unload in space!";
                done = true;
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
                Result = "Success";
                done = true;
                return false;
            }
        }
    }
}