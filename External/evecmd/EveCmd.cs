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
using System.Threading;

namespace evecmd
{
    class EveCmd
    {
        private static object lock_ = new object();
        private static List<string> command_queue_ = new List<string>();
        List<State> states = new List<State>();

        static void Main(string[] args)
        {
            new EveCmd().Run();
        }

        public void Initialize()
        {
            //if (g.eve == null)
            //{
                g.isxeve = new ISXEVE();
                g.eve = new EVE.ISXEVE.EVE();
                g.me = new Me();
                
            //}


        }

        public void Run()
        {
            // set up the handler for events coming back from InnerSpace
            LavishScript.Events.AttachEventTarget(LavishScript.Events.RegisterEvent("OnFrame"), OnFrame);
            LavishScript.Commands.AddCommand("evecmd", Update);

            lock (lock_) {
                Monitor.Wait(lock_);
            }
        }

        public int Update(string[] args)
        {
            var list = args.ToList();
            list.RemoveAt(0);

            var command = string.Join(" ", list.ToArray());

            lock (lock_) {
                command_queue_.Add(command);
            }

            return 0;
        }

        DateTime dont_run_until;
        void OnFrame(object sender, LSEventArgs e)
        {
            if (dont_run_until > DateTime.Now)
                return;

            dont_run_until = DateTime.Now + new TimeSpan(5000000);

            using (new FrameLock(true))
            {
                Initialize();

                List<string> queue = null;
                lock (lock_)
                {
                    if (command_queue_.Count > 0)
                    {
                        queue = new List<string>(command_queue_);
                        command_queue_.Clear();
                    }
                }

                if (queue != null && !g.isxeve.IsReady)
                {
                    g.Print("ISXEVE isn't ready!");
                    return;
                }

                // first process any commands from the user
                if (queue != null)
                    foreach (string command in queue)
                        RunCommand(command);

                // now go through the states in the state queue until one
                // claims to have handled  the frame
                int i;
                for (i = 0; i < states.Count; i++)
                {
                    State state = states[i];
                    if (state.OnFrame())
                        break;
                }

                if (i == states.Count)
                    i--;

                // remove any states that finished
                for (; i >= 0; i--)
                {
                    State state = states[i];
                    if (state.IsDone)
                        states.RemoveAt(i);
                }
            }
        }

        void RunCommand(string command)
        {
            if (command == "clear")
                states.Clear();
            else if (command == "exit") {
                InnerSpace.Echo("Exiting...");
                // set up the handler for events coming back from InnerSpace
                LavishScript.Events.DetachEventTarget("OnFrame", OnFrame);
                LavishScript.Commands.RemoveCommand("evecmd");

                lock (lock_) {
                    Monitor.Pulse(lock_);
                }
            }
            else if (command == "update")
                LavishScript.ExecuteCommand("execute evecmd_update woot");
            else if (command == "undock") {
                State state = new UndockState();
                TryToEnterState(state);
            }
            else if (command == "gates") {
                List<Entity> entities = g.eve.QueryEntities("GroupID = 10");
                g.Print("Found {0} Stargates:", entities.Count);
                int i = 0;
                foreach (Entity entity in entities) {
                    g.Print("#{0}: [{2}] {1}", i, entity.Name, entity.ID);
                    i++;
                }
            }
            else if (command == "stations") {
                List<Entity> entities = g.eve.QueryEntities("GroupID = 15");
                g.Print("Found {0} Stations:", entities.Count);
                int i = 0;
                foreach (Entity entity in entities) {
                    g.Print("#{0}: [{2}] {1}", i, entity.Name, entity.ID);
                    i++;
                }
            }
            else if (command == "missions") {
                List<AgentMission> missions = g.eve.GetAgentMissions();
                if (missions != null && missions.Count != 0) {
                    g.Print("Found {0} Missions:", missions.Count);
                    int i = 0;
                    foreach (AgentMission mission in missions) {
                        g.Print("#{0}: {1}", i, mission.Name);
                        g.Print("    AgentID={0}", mission.AgentID);
                        g.Print("    Expires={0}", mission.Expires);
                        g.Print("    State={0}", mission.State);
                        g.Print("    Type={0}", mission.Type);
                        mission.GetDetails(); //opens details window
                        List<BookMark> bookmarks = mission.GetBookmarks();
                        int j = 0;
                        g.Print("    {0} Bookmarks:", bookmarks.Count);
                        foreach (BookMark bookmark in bookmarks) {
                            g.Print("    Bookmark #{0}: [{2}] {1}", j, bookmark.Label, bookmark.ID);
                            g.Print("        Type: [{0}] {1}", bookmark.TypeID, bookmark.TypeID);
                            g.Print("        LocationType: {0}", bookmark.LocationType);
                            g.Print("        SolarSystemID: {0}", bookmark.SolarSystemID);
                            j++;
                        }
                        i++;
                    }
                }
                else if (missions == null) {
                    g.Print("Getting missions failed");
                }
                else {
                    g.Print("No missions found");
                }
            }
            else if (command.StartsWith("printwindow ")) {
                string window_name = command.Substring(12);
                EVEWindow window = EVEWindow.GetWindowByName(window_name);
                if (window == null || !window.IsValid)
                    window = EVEWindow.GetWindowByCaption(window_name);

                if (window != null && window.IsValid) {
                    g.Print(window.Caption);
                    g.Print(window.HTML);

                    try // to parse some basics
                    {
                        MissionPage page = new MissionPage(window.HTML);
                        g.Print("Title: {0}", page.Title);
                        g.Print("CargoID: {0}", page.CargoID);
                        g.Print("Volume: {0}", page.CargoVolume);
                    }
                    catch { }
                }
                else
                    g.Print("window \"{0}\" not found", window_name);
            }
            else if (command == "printitems") {
                // print the items in station
                if (!g.me.InStation)
                    g.Print("Not in station...");
                else {
                    List<Item> items = g.me.GetHangarItems();
                    if (items == null) {
                        g.Print("Failed to GetHangerItems");
                    }
                    else {
                        int i = 0;
                        g.Print("Found {0} Items:", items.Count);
                        foreach (Item item in items) {
                            g.Print("#{0}: [{2}] {1} x{3}", i, item.Name, item.ID, item.Quantity);
                            g.Print("    Description={0}", item.Description);
                            g.Print("    Type=[{0}] {1}", item.TypeID, item.Type);
                            g.Print("    Category=[{0}] {1}", item.CategoryID, item.Category);
                            g.Print("    BasePrice={0}", item.BasePrice);
                            g.Print("    UsedCargoCapacity={0}", item.UsedCargoCapacity);
                            i++;
                        }
                    }
                }
            }
            else if (command.StartsWith("printagent ")) {
                int id = Int32.Parse(command.Substring(11));
                Agent agent = new Agent("ByID", id);
                if (agent != null && agent.IsValid) {
                    g.Print("Name: {0}", agent.Name);
                    g.Print("Station: [{0}] {1}", agent.StationID, agent.Station);
                    g.Print("Division: [{0}] {1}", agent.DivisionID, agent.Division);
                    g.Print("StandingTo: {0}", agent.StandingTo);
                    g.Print("SolarSystemID: {0}", agent.Solarsystem.ID);
                    List<DialogString> responses = agent.GetDialogResponses();
                    int i = 0;
                    g.Print("{0} Dialog Responses:", responses.Count);
                    foreach (DialogString response in responses) {
                        g.Print("    Response #{0}: {1}", i, response.Text);
                        i++;
                    }
                }
                else {
                    g.Print("Agent not found");
                }
            }
            else if (command == "printcargo") {
                List<Item> items = g.me.Ship.GetCargo();

                g.Print("Found {0} Items:", items.Count);
                int i = 0;
                foreach (Item item in items) {
                    g.Print("#{0} {1}", i, item.Name);
                    g.Print("    Category: [{0}] {1} ({2})", item.CategoryID, item.Category, item.CategoryType.ToString());
                    g.Print("    Description: {0}", item.Description);
                    g.Print("    Group: [{0}] {1}", item.GroupID, item.Group);
                    i++;
                }
            }
            else if (command == "printroids") {
                List<Entity> roids = g.eve.QueryEntities("CategoryID = 25");
                g.Print("Found {0} Asteroids:", roids.Count);
                int i = 0;
                foreach (Entity roid in roids) {
                    if (i >= 10)
                        break;
                    g.Print("#{0} {1}", i, roid.Name);
                    g.Print("    Distance: {0}", roid.Distance);
                    g.Print("    Type: [{0}] {1}", roid.TypeID, roid.Type);
                    g.Print("    Category: [{0}] {1} ({2})", roid.CategoryID, roid.Category, roid.CategoryType);
                    g.Print("    Location: {0},{1},{2}", roid.X, roid.Y, roid.Z);
                    g.Print("    IsActiveTarget: {0} IsLockedTarget: {1}", roid.IsActiveTarget ? "Yes" : "No", roid.IsLockedTarget ? "Yes" : "No");
                    i++;
                }

            }
            else if (command.StartsWith("warp ")) {
                State state = new WarpState(command);
                TryToEnterState(state);
            }
            else if (command.Split(' ')[0] == "dock") {
                State state = new DockState(command);
                TryToEnterState(state);
            }
            else if (command.Split(' ')[0] == "goto") {
                State state = new GotoState(command);
                TryToEnterState(state);
            }
            else if (command.Split(' ')[0] == "domission") {
                State state = new MissionState(command);
                TryToEnterState(state);
            }
            else if (command.Split(' ')[0] == "dodropoff") {
                State state = new DoDropoffState(command);
                TryToEnterState(state);
            }
            else if (command.Split(' ')[0] == "mineloop") {
                State state = new MineLoopState(command);
                TryToEnterState(state);
            }
            else if (command == "unloadore") {
                State state = new UnloadOreState();
                TryToEnterState(state);
            }
            else if (command.StartsWith("travel ")) {
                State state = new TravelToStationState(command);
                TryToEnterState(state);
            }
            else if (command == "runlasers") {
                TryToEnterState(new RunMiningLasersState());
            }
        }

        public void TryToEnterState(State state)
        {
            state.OnFrame();
            if (!state.IsDone)
            {
                states.Insert(0, state);
            }
            else
            {
                g.Print("Failed to enter state: {0} ({1})", state, state.Result);
            }
        }
    }
}
