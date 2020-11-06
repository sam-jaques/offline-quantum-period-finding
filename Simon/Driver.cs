

namespace Quantum.ModularAddition
{
    using System.Collections.Generic;
 
    using Microsoft.Quantum.Simulation.Core;
    using Microsoft.Quantum.Simulation.Simulators;
    using Microsoft.Quantum.Arithmetic;
    using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;
    using Xunit.Abstractions;
    using System.Diagnostics;
    using System.Threading;
    using System;

    using Microsoft.Quantum.Core;   

    using CommaSeparated;

    using Microsoft.Quantum.Crypto;
    using Microsoft.Quantum.Characterization;
    using Microsoft.Quantum.Simulation.Simulators.Exceptions;
    using Microsoft.Quantum.Intrinsic;
    using Newtonsoft.Json.Serialization;
    using Microsoft.Quantum.Crypto.Basics;  
    using Microsoft.Quantum.Crypto.Tests;

    using Microsoft.Quantum.Canon;

    using Quantum.Matrix;
    using SimonResourceWrappers;
    using Quantum.Prince;
    using Quantum.Keccak;
    using Quantum.Elephant;
    using Quantum.Chaskey;


    class Driver
    {
        public delegate System.Threading.Tasks.Task<Microsoft.Quantum.Simulation.Core.QVoid>  RunQop(QCTraceSimulator sim, long n, bool isControlled);
        public delegate System.Threading.Tasks.Task<Microsoft.Quantum.Simulation.Core.QVoid>  RunTwoArgQop(QCTraceSimulator sim, long n, long m, bool isControlled);
 

        static void Main(string[] args)
        {
            // Debugging
            // Remove before release
           //   var qsim = new ToffoliSimulator();
           //  // RankTest.Run(qsim).Wait();
           //   // KeccakTest.Run(qsim).Wait();
           //   // ChaskeyTest.Run(qsim).Wait();
           // //  TestElephant.Run(qsim, 200).Wait();
           //     KeccakTest.Run(qsim).Wait();
           //   return;

            string subFolder;
            if (DriverParameters.MinimizeDepthCostMetric)
            {

                subFolder = "LowDepth/";
            }
            else if (DriverParameters.MinimizeTCostMetric)
            {
                subFolder = "LowT/";
            }
            else
            {
                subFolder = "LowWidth/";
            }

            int[] bigTestSizes = { 4, 8, 16, 32, 64, 110, 128, 160, 192, 224, 256, 384, 512 };
            int[] smallSizes = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 };
            int[] ellipticCurveTestSizes = { 110, 160, 192, 224, 256, 384, 521 };
            int[] fixedEllipticCurveTestSizes = { 10, 30, 192, 224, 256, 384, 521 };

            // Matrix dimensions of the actual attack
            int[] realWidths =   {47, 48, 50, 51, 63, 68, 76};
            int[] a1 = {134};
            int[] a2 = {166};
            int[] a3 = {182};
            int[] a4 = {206};
            int[] a5 = {166, 182};
            int[][] realHeights = {a5, a1, a1, a1, a2, a3, a4};


            // construct list of random matrix dimensions
            List<int> exhaustiveMatrixWidths = new List<int>();
            List<int[]> exhaustiveMatrixHeights = new List<int[]>();
            System.Random rnd = new System.Random();
            for (int i = 14; i <= 64; i ++)
            {
                exhaustiveMatrixWidths.Add(i);
                List<int> matrixWidths = new List<int>();
                matrixWidths.Add(i - rnd.Next(0,20));
                for (int j =1; j <= 6; j++){
                    matrixWidths.Add(matrixWidths[j-1] + rnd.Next(0,8));
                }
                exhaustiveMatrixHeights.Add(matrixWidths.ToArray());
            }

            // Estimate costs for matrix rank calculation in random dimensions
            EstimateRankCosts(exhaustiveMatrixWidths.ToArray(), exhaustiveMatrixHeights.ToArray(), "RankCalculationEven/" + subFolder);
            // Costs for matrix rank calculation for attack-specific dimensions
            EstimateRankCosts(realWidths, realHeights,  "RankCalculation/" + subFolder);


            // Estimate costs for block ciphers optimized for Simon
            EstimateCipherCosts("CipherCosts/" + subFolder);
            // Costs for block ciphers for Simon, unoptimized
            EstimateFullCipherCosts("FullCipherCosts/" + subFolder);
            // Costs for block ciphers in a Grover search
            EstimateGroverCosts("GroverCosts/" + subFolder);


        }

        public static void EstimateCipherCosts(string directory)
        {
            // Writes global parameters (cost metric, testable gates) to terminal
            DriverParameters.Print();

            System.IO.Directory.CreateDirectory(directory);
            int[] chaskeyRounds = {8, 12};
            int[] elephantSizes = {160, 176, 200};
            int[] princeSizes = {64};
            int[][] elephantGuessSizes = {new int[]{47, 63}, new int[]{47, 68},  new int[]{69, 76}};
            int[][] princeGuessSizes = {new int[]{48, 50}};
            int[][] chaskeyGuessSizes = {new int[]{48, 50, 51}, new int[]{48, 50, 51}};
            // Warning, longer version!
            //int[][] elephantGuessSizes = {new int[]{47, 62, 63, 64}, new int[]{47, 67, 68, 69},  new int[]{69, 75, 76, 77}};
            //int[][] princeGuessSizes = {new int[]{47, 48, 49, 50, 51, 52}};
            //int[][] chaskeyGuessSizes = {new int[]{47,48, 49, 50, 51, 52}, new int[]{47, 48, 49, 50, 51, 52}};
            // Loops over controlled/not and whether it counts all gates
            bool allGates = false;
            bool isControlled = false;
            for (int j = 0; j < 2; j++)
            {
                // for (int i = 0; i < 2; i++)
                // {
                    var localControl = isControlled;
                    var localGates = allGates;
                    Thread chaskeyThread = new Thread(() => TwoArgResourceTest<ChaskeyAttackEstimate>(
                        ChaskeyAttackEstimate.Run,
                        chaskeyRounds,
                        chaskeyGuessSizes,
                        localControl,
                        directory + "Chaskey",
                        localGates));
                    chaskeyThread.Start();
                    Thread princeThread = new Thread(() => TwoArgResourceTest<PrinceAttackEstimate>(
                        PrinceAttackEstimate.Run,
                        princeSizes,
                        princeGuessSizes,
                        localControl,
                        directory + "Prince",
                        localGates));
                    princeThread.Start();
                    Thread elephantThread = new Thread(() => TwoArgResourceTest<ElephantAttackEstimate>(
                        ElephantAttackEstimate.Run,
                        elephantSizes,
                        elephantGuessSizes,
                        localControl,
                        directory + "Elephant",
                        localGates));
                    elephantThread.Start();
                //     isControlled = !isControlled;
                // }

                allGates = !allGates;
            }
        }

        public static void EstimateFullCipherCosts(string directory)
        {
            // Writes global parameters (cost metric, testable gates) to terminal
            DriverParameters.Print();

            System.IO.Directory.CreateDirectory(directory);
            int[] chaskeyRounds = {8, 12};
            int[] elephantSizes = {160, 176, 200};
            int[] princeSizes = {64};
            // Loops over controlled/not and whether it counts all gates
            bool allGates = false;
            bool isControlled = false;
            for (int j = 0; j < 2; j++)
            {
                // for (int i = 0; i < 2; i++)
                // {
                    var localControl = isControlled;
                    var localGates = allGates;
                    Thread chaskeyThread = new Thread(() => BasicResourceTest<FullChaskeyAttackEstimate>(
                        FullChaskeyAttackEstimate.Run,
                        chaskeyRounds,
                        localControl,
                        directory + "Chaskey",
                        localGates,
                        false));
                    chaskeyThread.Start();
                    Thread princeThread = new Thread(() => BasicResourceTest<FullPrinceAttackEstimate>(
                        FullPrinceAttackEstimate.Run,
                        princeSizes,
                        localControl,
                        directory + "Prince",
                        localGates,
                        false));
                    princeThread.Start();
                    Thread elephantThread = new Thread(() => BasicResourceTest<FullElephantAttackEstimate>(
                        FullElephantAttackEstimate.Run,
                        elephantSizes,
                        localControl,
                        directory + "Elephant",
                        localGates,
                        false));
                    elephantThread.Start();
                //     isControlled = !isControlled;
                // }

                allGates = !allGates;
            }
        }

        public static void EstimateGroverCosts(string directory)
        {
            // Writes global parameters (cost metric, testable gates) to terminal
            DriverParameters.Print();

            System.IO.Directory.CreateDirectory(directory);
            int[] chaskeyRounds = {8, 12};
            int[][] chaskeyQueries = {new int[]{1,2}, new int[]{1,2}};
            int[] elephantSizes = {160, 176, 200};
            int[][] elephantQueries = {new int[]{1}, new int[]{1}, new int[]{1}};
            int[] princeSizes = {64};
            int[][] princeQueries = {new int[]{1,2,3}};

            // Loops over controlled/not and whether it counts all gates
            bool allGates = false;
            bool isControlled = false;
            for (int j = 0; j < 2; j++)
            {
                // for (int i = 0; i < 2; i++)
                // {
                    var localControl = isControlled;
                    var localGates = allGates;
                    Thread chaskeyThread = new Thread(() => TwoArgResourceTest<ChaskeyGroverEstimate>(
                        ChaskeyGroverEstimate.Run,
                        chaskeyRounds,
                        chaskeyQueries,
                        localControl,
                        directory + "Chaskey",
                        localGates));
                    chaskeyThread.Start();
                    Thread princeThread = new Thread(() => TwoArgResourceTest<PrinceGroverEstimate>(
                        PrinceGroverEstimate.Run,
                        princeSizes,
                        princeQueries,
                        localControl,
                        directory + "Prince",
                        localGates));
                    princeThread.Start();
                    Thread elephantThread = new Thread(() => TwoArgResourceTest<ElephantGroverEstimate>(
                        ElephantGroverEstimate.Run,
                        elephantSizes,
                        elephantQueries,
                        localControl,
                        directory + "Elephant",
                        localGates));
                    elephantThread.Start();
                //     isControlled = !isControlled;
                // }

                allGates = !allGates;
            }
        }

        public static void EstimateRankCosts(int[] widths, int[][] heights, string directory)
        {
            // Writes global parameters (cost metric, testable gates) to terminal
            DriverParameters.Print();

            System.IO.Directory.CreateDirectory(directory);

            // Loops over controlled/not and whether it counts all gates
            bool allGates = false;
            bool isControlled = false;
            for (int j = 0; j < 2; j++)
            {
                // for (int i = 0; i < 2; i++) // no need to estimate when its controlled
                // {
                    var localControl = isControlled;
                    var localGates = allGates;
                    Thread rankThread = new Thread(() => TwoArgResourceTest<RankResourceEstimate>(
                        RankResourceEstimate.Run,
                        widths,
                        heights,
                        localControl,
                        directory + "Rank",
                        localGates));
                    rankThread.Start();
                //     isControlled = !isControlled;
                // }

                allGates = !allGates;
            }
        }

        /// # Summary
        /// Returns a trace simulator object that is configured
        /// to measure depth, width, and primitive operation count.
        /// If `full_depth` is true, then it counts every gate as depth 1;
        /// otherwise it only counts T gates
        private static QCTraceSimulator GetTraceSimulator(bool full_depth)
        {
            var config = new QCTraceSimulatorConfiguration();
            config.UseDepthCounter = true;
            config.UseWidthCounter = true;
            config.UsePrimitiveOperationsCounter = true;
            if (DriverParameters.MinimizeDepthCostMetric)
            {

                config.OptimizeDepth = true;
            }
            else if (DriverParameters.MinimizeTCostMetric)
            {   
                // This is the more sensible choice until
                // the depth optimization problem is fixed
                config.OptimizeDepth = false;
            }
            else
            {
                config.OptimizeDepth = false;
            }
            if (full_depth)
            {
                config.TraceGateTimes[PrimitiveOperationsGroups.CNOT] = 1;
                config.TraceGateTimes[PrimitiveOperationsGroups.Measure] = 1; // count all one and 2 qubit measurements as depth 1
                config.TraceGateTimes[PrimitiveOperationsGroups.QubitClifford] = 1; // qubit Clifford depth 1
            }

            return new QCTraceSimulator(config);
        }





        /// # Summary
        /// Runs a specified quantum operation with different parameters `ns`,
        /// saving the resource estimates as a csv file to a specified location.
        ///
        /// # Inputs
        /// ## runner
        /// The quantum operation being tested (must also match the type `Qop`).
        /// This operation must take a boolean `isControlled` and an integer parameter
        /// ## ns
        /// An array of integer parameters. This method will run the quantum operation
        /// with each parameter
        /// ## isControlled
        /// A boolean argument to pass to the quantum operation. The intention is that
        /// it tells the operator whether to test a controlled or uncontrolled version.
        /// ## filename
        /// The filename, including directory, of where to save the results
        /// ## full_depth
        /// If true, counts all gates as depth 1; if false, only counts T-gates as depth 1,
        /// all others as depth 0
        private static void BasicResourceTest<TypeQop>(RunQop runner, int[] ns, bool isControlled, string filename, bool full_depth, bool isThreaded)
        {
            if (full_depth)
            {
                filename += "-all-gates";
            }

            if (isControlled)
            {
                filename += "-controlled";
            }

            filename += ".csv";
            string estimation = string.Empty;

            // Headers for the table
            if (!System.IO.File.Exists(filename))
            {
                estimation += DisplayCSV.GetHeader(full_depth) + ", size";
                System.IO.File.WriteAllText(filename, estimation);
            }

            // Run the test for every size
            ReaderWriterLock locker = new ReaderWriterLock();
            for (int i = 0; i < ns.Length; i++)
            {
                if (isThreaded)
                {
                    var thisThreadParameter = ns[i];
                    Thread oneParameterTest = new Thread(() => SingleResourceTest<TypeQop>(
                        runner, locker, thisThreadParameter, isControlled, filename, full_depth));
                    oneParameterTest.Start();
                }
                else
                {
                    // Single thread
                    SingleResourceTest<TypeQop>(runner, locker, ns[i], isControlled, filename, full_depth);
                }
            }
        }

        private static void SingleResourceTest<TypeQop>(RunQop runner, ReaderWriterLock locker, int n, bool isControlled, string filename, bool full_depth)
        {
            QCTraceSimulator estimator = GetTraceSimulator(full_depth); // construct simulator object

            // we must generate a new simulator in each round, to clear previous estimates
            var res = runner(estimator, n, isControlled).Result; // run test

            // Create string of a row of parameters
            string thisCircuitCosts = DisplayCSV.CSV(estimator.ToCSV(), typeof(TypeQop).FullName, false, string.Empty, false, string.Empty);

            // add the row to the string of the csv
            thisCircuitCosts += $"{n}";
            try
            {
                locker.AcquireWriterLock(int.MaxValue); // absurd timeout value
                System.IO.File.AppendAllText(filename, thisCircuitCosts);
            }
            finally
            {
                locker.ReleaseWriterLock();
            }
        }

        /// # Summary
        /// Runs a specified quantum operation with different parameters `ns`,
        /// saving the resource estimates as a csv file to a specified location.
        /// This also runs the operation with a second parameter, which varies
        /// between specified minimum and maximum values. It only runs over the
        /// second parameter until it minimizes depth and T count.
        /// The main purpose is to estimate optimal window sizes for windowed operations.
        ///
        /// # Inputs
        /// ## runner
        /// The quantum operation being tested (must also match the type `Qop`).
        /// This operation must take a boolean `isControlled` and an integer parameter
        /// ## ns
        /// An array of integer parameters. This method will run the quantum operation
        /// with each parameter
        /// ## isControlled
        /// A boolean argument to pass to the quantum operation. The intention is that
        /// it tells the operator whether to test a controlled or uncontrolled version.
        /// ## isAmortized
        /// Decides how to select the optimal second parameter. If it's amortized, it divides
        /// the resulting cost by the value of the second parameter. This is intended
        /// for windowed addition: as the window size increases, we need to do fewer additions.
        /// ## filename
        /// The filename, including directory, of where to save the results
        /// ## full_depth
        /// If true, counts all gates as depth 1; if false, only counts T-gates as depth 1,
        /// all others as depth 0
        /// ## minParameters
        /// The minimum value for the second parameter, corresponding to values in ns
        /// ## maxParameters
        /// The maximum value for the second parameter.
        private static void TwoArgResourceTest<TypeQop>(
            RunTwoArgQop runner,
            int[] ns,
            int[][] ms,
            bool isControlled,
            string filename,
            bool full_depth
        ) {
            if (full_depth)
            {
                filename += "-all-gates";
            }

            if (isControlled)
            {
                filename += "-controlled";
            }

            filename += ".csv";

            // Create table headers
            if (!System.IO.File.Exists(filename))
            {
                string estimation = DisplayCSV.GetHeader(full_depth) + ", first arg, second arg";
                System.IO.File.WriteAllText(filename, estimation);
            }

            ReaderWriterLock locker = new ReaderWriterLock();

            for (int i = 0; i < ns.Length; i++)
            {
                // Local variables to prevent threading issues
                var thisThreadProblemSize = ns[i];
                var thisTheadSecondParams = ms[i];

                // Starts a thread for each value in ns.
                // Each thread will independently search for an optimal size.
                Thread oneParameterTest = new Thread(() => SingleTwoArgResourceTest<TypeQop>(
                    runner,
                    locker,
                    thisThreadProblemSize,
                    thisTheadSecondParams,
                    isControlled,
                    filename,
                    full_depth));
                oneParameterTest.Start();
            }
        }

        private static void SingleTwoArgResourceTest<TypeQop>(
            RunTwoArgQop runner,
            ReaderWriterLock locker,
            int n,
            int[] ms,
            bool isControlled,
            string filename,
            bool full_depth)
        {

            // Iterate through values of the second parameter
            foreach (int m in ms)
            {
                QCTraceSimulator estimator = GetTraceSimulator(full_depth); // construct simulator object

                // we must generate a new simulator in each round, to clear previous estimates
                var res = runner(estimator, n, m, isControlled).Result; // run test

                // Get results
                var roundDepth = estimator.GetMetric<TypeQop>(MetricsNames.DepthCounter.Depth);
                var roundTGates = estimator.GetMetric<TypeQop>(PrimitiveOperationsGroupsNames.T);


                // Create string of a row of parameters
                string thisCircuitCosts = DisplayCSV.CSV(estimator.ToCSV(), typeof(TypeQop).FullName, false, string.Empty, false, string.Empty);

                // add the row to the string of the csv
                thisCircuitCosts += $"{n}, {m}";
                try
                {
                    locker.AcquireWriterLock(int.MaxValue); // absurd timeout value
                    System.IO.File.AppendAllText(filename, thisCircuitCosts);
                }
                finally
                {
                    locker.ReleaseWriterLock();
                }

            }
        }

    }

}
