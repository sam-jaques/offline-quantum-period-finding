# Estimation Code For Offline Simon's Algorithm

This code estimates the cost of running an offline Simon's attack against the block ciphers Chaskey, Prince, and Elephant. 

It consists of two main components
- Q# code to compute circuit costs for the ciphers themselves and linear algebra
- A Python script to assemble the results into the cost of the full attack

## Dependencies

-Dotnet core 3.1, available here: https://dotnet.microsoft.com/download
-Qsharp sdk 0.13.20102604 (later versions will need changes to the C# code portions). Installation instructions here: https://docs.microsoft.com/en-us/quantum/quickstarts/ Can be run with
   `dotnet new -i Microsoft.Quantum.ProjectTemplates`
-Python 3 
-SageMath 8.1

## How to Build

`cd /path/to/MicrosoftQuantumCrypto`
`dotnet build -c MinimizeT`

This builds the MicrosoftQuantumCrypto library.

`cd /path/to//Simon`
`dotnet build`

This builds the Q# estimation circuits.

## How to run

`cd /path/to//Simon`
`dotnet run`

This runs the Q# estimation circuits for:
- The Simon function for the three block ciphers, with no optimizations (saved to /FullCipherCosts/)
- The same block ciphers, with optimizations for different guess sizes (saved to /CipherCosts/)
- Grover iterations for key search (saved to /GroverCosts/)
- Computing the rank of a matrix for a range of dimensions from 4 to 64 with approximately even width (saved to /RankCalculationEven/)
- Computing the rank of the matrices needed for the offline Simon attack (saved to /RankCalculation/)

If estimations already exist, this will append the new data to the existing estimations.

To find the full costs for the offline Simon attack and the quantum exhaustive key search, run:

`cd /path/to/folder`
`python3 attack_cost.py`

This will print the results to the console. It starts with query-limited versions of the attacks, then tries a query-unlimited version.

# Customizations
Some of the main points you may want to customize:

## Optimization strategies
The MicrosoftQuantumCrypto library can be built with any of three different optimization strategies:
`dotnet build -c MinimizeT`
`dotnet build -c MinimizeDepth`
`dotnet build -c MinimizeWidth`
The Simon resource estimator references these directly, so to use a different option, you will need to modify ResourceEstimator.csproj. Specifically, lines including
`..\MicrosoftQuantumCrypto\bin\MinimizeT\netcoreapp3.1\MicrosoftQuantumCrypto.dll`
should have `MinimizeT` changed to one of the other options.

As well, `Driver.cs` makes a decision of which compiler strategy to use when allocating qubits: a depth-optimal or width-optimal. As of November 2020 there is a bug in the depth-optimal estimator (https://github.com/microsoft/qsharp-runtime/issues/419), so we opted to use a width-optimal strategy when optimizing for T count. This is is part of the `GetTraceSimulator` function.

The python script `attack_cost.py` will also need to have `Q_SHARP_SUBFOLDER` changed to "LowDepth" or "LowWidth".

## Keccak
Because Pi, Rho, and Theta use a PLU decomposition, this must be created for every block size used. We only generated code for a block size of 200 bits. To change this, modify the `matrixPLU.sage` file. It has a hard-coded `w` which represents the length of a state. Modify this (e.g., w=64 for 1600-bit blocks), and run `sage matrixPLU.sage` and it will save a new code to `PiRhoThetaRaw`. As needed, replace the code in `PiRhoTheta.qs`. 

## Cost metrics
The script `attack_cost.py` chooses an optimal number of queries based on the minimum gate cost. This can be easily changed; `COST_METRIC` can be changed to `ALL_GATES` or `T_GATES`; and `COST_MODEL` can be switched from `G_COST` to `DW_COST`

# Contributors

- Xavier Bonnetain
- Samuel Jaques

MicrosoftQuantumCrypto library, resource estimation, and PLU decompositions:

- Christain Paquin
- Michael Naehrig
- Fernando Virdia

# License

MIT License

Copyright 2020 Samuel Jaques, Xavier Bonnetain, Microsoft Corporation	

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

